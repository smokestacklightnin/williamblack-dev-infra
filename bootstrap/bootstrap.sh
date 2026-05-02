#!/usr/bin/env bash
set -euo pipefail

# === Configuration (sourced from .envrc) ===
: "${PROJECT_ID:?must be set in .envrc}"
: "${REGION:?must be set in .envrc}"
: "${BOOTSTRAP_SA_NAME:?must be set in .envrc}"
: "${APP_INFRA_SA_NAME:?must be set in .envrc}"

# === Derived ===
BOOTSTRAP_SA="${BOOTSTRAP_SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"
APP_INFRA_SA="${APP_INFRA_SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"
BOOTSTRAP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# === Preflight ===
for tool in gcloud tofu; do
  command -v "$tool" >/dev/null || { echo "ERROR: $tool not found in PATH" >&2; exit 1; }
done

USER_EMAIL="$(gcloud config get-value account 2>/dev/null || true)"
[ -n "$USER_EMAIL" ] || { echo "ERROR: not authenticated. Run 'gcloud auth login'." >&2; exit 1; }

gcloud auth application-default print-access-token >/dev/null 2>&1 \
  || { echo "ERROR: no application-default credentials. Run 'gcloud auth application-default login'." >&2; exit 1; }

echo "==> Project: $PROJECT_ID"
echo "==> Region:  $REGION"
echo "==> User:    $USER_EMAIL"

gcloud config set project "$PROJECT_ID" >/dev/null

# === Enable APIs ===
echo "==> Enabling APIs..."
gcloud services enable \
  storage.googleapis.com \
  cloudkms.googleapis.com \
  cloudresourcemanager.googleapis.com \
  iam.googleapis.com \
  iamcredentials.googleapis.com \
  --project="$PROJECT_ID"

# === Service accounts (idempotent) ===
create_sa() {
  local name="$1" display="$2"
  local email="${name}@${PROJECT_ID}.iam.gserviceaccount.com"
  if gcloud iam service-accounts describe "$email" --project="$PROJECT_ID" >/dev/null 2>&1; then
    echo "==> SA exists: $email"
  else
    echo "==> Creating SA: $email"
    gcloud iam service-accounts create "$name" \
      --project="$PROJECT_ID" \
      --display-name="$display" >/dev/null
  fi
}

create_sa "$BOOTSTRAP_SA_NAME" "Tofu bootstrap (state bucket + KMS)"
create_sa "$APP_INFRA_SA_NAME" "Tofu app-infra (website, Cloudflare, WIF)"

# === Grant project roles ===
grant_role() {
  local sa="$1" role="$2"
  gcloud projects add-iam-policy-binding "$PROJECT_ID" \
    --member="serviceAccount:${sa}" \
    --role="$role" \
    --condition=None \
    --quiet >/dev/null
}

echo "==> Granting roles to $BOOTSTRAP_SA..."
grant_role "$BOOTSTRAP_SA" "roles/storage.admin"
grant_role "$BOOTSTRAP_SA" "roles/cloudkms.admin"

echo "==> Granting roles to $APP_INFRA_SA..."
grant_role "$APP_INFRA_SA" "roles/storage.admin"
grant_role "$APP_INFRA_SA" "roles/iam.serviceAccountAdmin"
grant_role "$APP_INFRA_SA" "roles/iam.workloadIdentityPoolAdmin"

# === Allow you to impersonate both SAs ===
echo "==> Granting $USER_EMAIL impersonation on both SAs..."
for sa in "$BOOTSTRAP_SA" "$APP_INFRA_SA"; do
  gcloud iam service-accounts add-iam-policy-binding "$sa" \
    --member="user:${USER_EMAIL}" \
    --role="roles/iam.serviceAccountTokenCreator" \
    --project="$PROJECT_ID" \
    --quiet >/dev/null
done

# === Apply bootstrap tofu, impersonating tofu-bootstrap ===
export GOOGLE_IMPERSONATE_SERVICE_ACCOUNT="$BOOTSTRAP_SA"

echo "==> Waiting for impersonation grant to propagate..."
for i in {1..12}; do
  if gcloud auth print-access-token \
       --impersonate-service-account="$BOOTSTRAP_SA" >/dev/null 2>&1; then
    echo "    ready after ${i} attempt(s)"
    break
  fi
  [ "$i" -eq 12 ] && { echo "ERROR: impersonation never became ready" >&2; exit 1; }
  sleep 5
done

echo "==> tofu init"
tofu -chdir="$BOOTSTRAP_DIR" init -input=false

echo "==> tofu apply"
tofu -chdir="$BOOTSTRAP_DIR" apply \
  -auto-approve \
  -input=false \
  -var "project_id=$PROJECT_ID" \
  -var "region=$REGION"

echo "==> Migrating state to GCS backend"
tofu -chdir="$BOOTSTRAP_DIR" init -input=false -migrate-state -force-copy

echo
echo "==> Bootstrap complete."
echo "    State bucket and KMS key created; state migrated to GCS."
echo "    App-infra SA provisioned and impersonable by $USER_EMAIL."
