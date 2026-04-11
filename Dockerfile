ARG NODE_VERSION=22.9.0
FROM node:${NODE_VERSION}-slim as base

LABEL fly_launch_runtime="Node.js"

WORKDIR /app

RUN npm install -g yarn --force

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    build-essential \
    node-gyp \
    pkg-config \
    python-is-python3 \
    ca-certificates && \
    rm -rf /var/lib/apt/lists/*

COPY --link .yarnrc.yml package.json yarn.lock server.js rsi.js elm.json entrypoint.sh ./
COPY --link .yarn .yarn
COPY --link public public
COPY --link src src
COPY --link server server
COPY --link css css
COPY --link views views
RUN chmod +x /app/entrypoint.sh

RUN yarn install --immutable

ENV PORT=3000
ENV NODE_ENV=production

EXPOSE 3000

CMD ["/app/entrypoint.sh"]
