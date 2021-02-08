FROM samhstn_base:latest

COPY infra infra
COPY config config
COPY test test
COPY lib lib
COPY priv/static/favicon.svg priv/static/favicon.svg
COPY priv/static/script.js priv/static/script.js
COPY priv/static/style.css priv/static/style.css
COPY mix.exs mix.lock .formatter.exs ./

RUN mix deps.get

RUN MIX_ENV=test mix compile --force
# This command is very slow, we can ignore for now
# RUN MIX_ENV=test mix dialyzer
RUN MIX_ENV=test mix format --check-formatted
RUN MIX_ENV=test mix sobelow --router lib/samhstn_web/router.ex --exit --skip
RUN mix test

RUN MIX_ENV=prod mix phx.digest
RUN MIX_ENV=prod mix release
RUN zip -r samhstn.zip priv/static
RUN zip -qr samhstn.zip _build/prod/rel/samhstn
RUN zip -j samhstn.zip \
      infra/samhstn/appspec.yml \
      infra/samhstn/start-service.sh \
      infra/samhstn/stop-service.sh
