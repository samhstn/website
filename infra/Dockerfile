FROM centos:7

RUN yum update -y
RUN yum clean -y all

RUN echo 'LC_ALL="en_US.UTF-8"' >> /etc/locale.conf
ENV LC_ALL="en_US.UTF-8"

RUN yum install -y epel-release
RUN yum install -y gcc gcc-c++ glibc-devel make ncurses-devel openssl-devel \
                   autoconf java-1.8.0-openjdk-devel git wget wxBase.x86_64 \
                   zip openssl11 python3

RUN curl -sL https://rpm.nodesource.com/setup_10.x | bash -
RUN yum install -y nodejs

RUN pip3 install awscli
ENV PATH="$HOME/.local/bin:${PATH}"

RUN wget https://github.com/jmespath/jp/releases/download/0.1.3/jp-linux-amd64 -O /usr/local/bin/jp
RUN chmod +x /usr/local/bin/jp

WORKDIR /opt

RUN wget http://packages.erlang-solutions.com/erlang-solutions-1.0-1.noarch.rpm
RUN rpm -Uvh erlang-solutions-1.0-1.noarch.rpm
RUN yum update -y
RUN yum install -y erlang

WORKDIR /opt/elixir

RUN git clone https://github.com/elixir-lang/elixir.git /opt/elixir

RUN make clean test

ENV PATH=/opt/elixir/bin:${PATH}

RUN mix do local.hex --force, local.rebar --force
RUN mix archive.install hex phx_new 1.5.4 --force

WORKDIR /opt/app
