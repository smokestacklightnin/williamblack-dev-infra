export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    if (url.hostname.startsWith("www.")) {
      const apex = url.hostname.slice(4);
      return Response.redirect(
        `https://${apex}${url.pathname}${url.search}`,
        301,
      );
    }

    let path = url.pathname;
    if (path.endsWith("/")) {
      path += "index.html";
    }

    const origin = `https://storage.googleapis.com/${env.BUCKET}${path}`;
    const response = await fetch(origin, {
      cf: { cacheEverything: true, cacheTtl: 3600 },
    });

    return new Response(response.body, {
      status: response.status,
      headers: response.headers,
    });
  },
};
