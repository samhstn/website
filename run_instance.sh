#!/bin/bash

cat <<EOF > codebuild.Dockerfile
FROM samhstn_base:latest
WORKDIR /opt/app
COPY mix.exs mix.lock ./
COPY config config
COPY lib lib
COPY test test
COPY infra infra
COPY priv priv
RUN mix deps.get
RUN mix test
WORKDIR /opt/app
RUN mix phx.digest
ENV MIX_ENV=prod
RUN mix release
RUN zip -r issue_num.zip priv
RUN zip -qr issue_num.zip _build/prod/rel/samhstn
RUN zip -j issue_num.zip infra/samhstn/appspec.yml \
           infra/samhstn/start-service.sh \
           infra/samhstn/stop-service.sh
EOF

cat <<EOF > instance.Dockerfile
FROM amazonlinux:latest
WORKDIR /opt/app
RUN yum -y update 
RUN yum install -y unzip openssl11
ENV LANG="en_US.UTF-8"
ENV LC_ALL="en_US.UTF-8"
RUN ln -s /usr/lib64/libtinfo.so.{6,5}
COPY issue_num.zip issue_num.zip
RUN unzip -q issue_num.zip
WORKDIR /opt/app/priv/keys
RUN openssl11 req -new -newkey rsa:4096 -days 365 -nodes -x509 \
                  -subj "/C=/ST=/L=/O=/CN=localhost" -keyout key.pem -out cert.pem
WORKDIR /opt/app
ENV SAMHSTN_PORT=4000
ENV SAMHSTN_HOST=$(hostname)
ENV SECRET_KEY_BASE='secretExampleQrzdplBPdbHHhr2bpELjiGVGVqmjvFl2JEXdkyla8l6+b2CCcvs'
CMD ["_build/prod/rel/samhstn/bin/samhstn", "start"]
EOF

docker build -f infra/Dockerfile -t samhstn_base .

docker build -f codebuild.Dockerfile -t samhstn_codebuild .

docker create samhstn_codebuild:latest

docker cp $(docker container ls -a | grep samhstn_codebuild:latest | head -1 | sed 's/ .*//'):/opt/app/issue_num.zip .

docker build -f instance.Dockerfile -t samhstn_instance .

rm codebuild.Dockerfile instance.Dockerfile issue_num.zip

docker run -p 4000:4000 -i samhstn_instance:latest
