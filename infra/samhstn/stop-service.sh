#!/bin/bash -xe
source /home/ec2-user/.bash_profile
[ -d "/home/ec2-user/app/release" ] && \
cd /home/ec2-user/app/release && \
_build/prod/rel/samhstn/bin/samhstn stop || true
