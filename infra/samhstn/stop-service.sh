#!/bin/bash -xe
source /home/ec2-user/.bash_profile
[ -d "/home/ec2-user/release" ] && \
cd /home/ec2-user/release && \

_build/prod/rel/samhstn/bin/samhstn stop
