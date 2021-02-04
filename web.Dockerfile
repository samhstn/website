FROM amazonlinux:latest

WORKDIR /home/ec2-user

# === AUTOMATICALLY INSTALLED FROM CLOUDFORMATION TEMPLATE METADATA ===
RUN yum update -y
RUN yum install -y ruby jq aws-cli openssl
# === AUTOMATICALLY INSTALLED FROM CLOUDFORMATION TEMPLATE METADATA ===

# === COPIED FROM EC2 LAUNCH TEMPLATE ===
# send script output to /tmp so we can debug boot failures
RUN exec > /tmp/userdata.log 2>&1

RUN ln -s /usr/lib64/libtinfo.so.{6,5}

RUN mkdir -p /home/ec2-user/app/keys
WORKDIR /home/ec2-user/app/keys
RUN openssl req -new -newkey rsa:4096 -days 365 -nodes -x509 \
                -subj "/C=/ST=/L=/O=/CN=localhost" -keyout key.pem -out cert.pem
# ENV SECRET_KEY_BASE=`aws secretsmanager get-secret-value \
#                       --secret-id '/SecretKeyBase' \
#                       --query SecretString --output text`
# ENV SAMHSTN_ASSETS_BUCKET=samhstn-assets-${AWS_ACCOUNT_ID}
# === COPIED FROM EC2 LAUNCH TEMPLATE ===

# === SIMULATING S3 BEHAVIOR ===
RUN yum update -y
RUN yum install -y unzip

RUN mkdir -p /home/ec2-user/app/release
WORKDIR /home/ec2-user/app/release
COPY --from=samhstn_build:latest /opt/app/samhstn.zip .
RUN unzip -q samhstn.zip
# === SIMULATING S3 BEHAVIOR ===

# === COPIED FROM START-SERVICE SCRIPT ===
WORKDIR /home/ec2-user/app/release
RUN cp -r ../keys priv/
ENV SAMHSTN_PORT=8443
ENV SAMHSTN_HOST=localhost

# RUN _build/prod/rel/samhstn/bin/samhstn daemon
# === COPIED FROM START-SERVICE SCRIPT ===
