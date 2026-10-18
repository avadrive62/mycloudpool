# syntax=docker/dockerfile:1
FROM node:24-alpine@sha256:44fce696f38ba8c987c4db89954051000bbd05ffd8d8659ba15ed4a8602e937f AS web
WORKDIR /build
ADD https://codeload.github.com/rclone/rclone-web/zip/refs/tags/1.1.11 /tmp/web.zip
RUN apk add --no-cache unzip \
    && echo "9f503645b719598b7aef891ba6f1b32ed7c912378a79c0db07f02e0646a36dca  /tmp/web.zip" | sha256sum -c - \
    && unzip -q /tmp/web.zip -d /build
WORKDIR /build/rclone-web-1.1.11
COPY patch-gui.mjs /tmp/patch-gui.mjs
RUN node /tmp/patch-gui.mjs && npm ci && npm run build

FROM caddy:2.11.7-alpine@sha256:d8542f48d34a9cf4e4c11a478865229840e87e4c96ea3f439101f31a5d35f75f AS proxy
FROM rclone/rclone:1.75.2@sha256:2687085f718d3c628f7fdfb77c52a1d344332aed543110bb88088f2c70d43eb5
COPY --from=proxy /usr/bin/caddy /usr/bin/caddy
COPY --from=web /build/rclone-web-1.1.11/dist /app/gui
COPY --from=web /build/rclone-web-1.1.11/LICENSE /app/licenses/rclone-web-LICENSE
COPY start.sh Caddyfile waiting.Caddyfile /app/
WORKDIR /app
ENV PORT=8080 CLOUDPOOL_DATA_DIR=/data CLOUDPOOL_SCHEME=https CLOUDPOOL_RC_PORT=5533
VOLUME ["/data"]
EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=5s --start-period=30s \
    CMD wget -q -O /dev/null "http://127.0.0.1:${PORT}/healthz" || exit 1
ENTRYPOINT ["/bin/sh", "/app/start.sh"]
