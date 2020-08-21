FROM samhstn_base:latest

COPY mix.exs mix.lock config.exs ./
COPY lib lib
COPY assets assets

RUN mkdir -p "$HOME/certs"
RUN openssl req -new -newkey rsa:4096 -days 3650 -nodes -x509 \
                -subj "/C=/ST=/L=/O=/CN=localhost" -keyout $HOME/certs/key.pem -out $HOME/certs/cert.pem

ENV PORT=4001
ENV CERT_DIR="$HOME/certs"
EXPOSE 4001

RUN mix do deps.get, compile

CMD mix phx.server
