FROM debian:stretch

# Install essential build packages
RUN apt-get update && apt-get install -y wget git locales curl

# Set locale
RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    dpkg-reconfigure --frontend=noninteractive locales && \
    update-locale LANG=en_US.UTF-8
ENV LANG en_US.UTF-8

# Install nodejs v8
RUN curl -sL https://deb.nodesource.com/setup_8.x | bash - && \
    apt-get install -y nodejs

# Install python3
RUN apt-get -y install python3 python3-pip && \
    pip3 install -vU setuptools

# Install python packages
RUN pip3 install cfn-lint

# Install node packages
