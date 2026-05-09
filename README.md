# samhstn.com

[samhstn.com](http://samhstn.com)
(Not hosted yet)

### Requirements

###### fly.io (TODO)

```bash
$ fly --version
fly version 0.4.45
```

###### Docker (TODO)

```bash
$ docker --version
Docker version 29.4.1, build 055a478
```

###### AWS (TODO)

```bash
$ aws --version
aws-cli/2.34.41 Python/3.14.4 Darwin/24.6.0 source/arm64
```

###### BigQuery (TODO)

```bash
$ bq --version
```

###### Deno (TODO)

```bash
$ deno --version
deno 2.7.14 (stable, release, aarch64-apple-darwin)
v8 14.7.173.20-rusty
typescript 5.9.2
```

###### Elixir + Phoenix (TODO)

```bash
$ elixir --version
Erlang/OTP 28 [erts-16.4] [source] [64-bit] [smp:8:8] [ds:8:8:10] [async-threads:1] [jit] [dtrace]

Elixir 1.19.5 (compiled with Erlang/OTP 28)

$ mix phx.new --version
Phoenix installer v1.8.5
```

###### React + Elm (TODO)

### Local Setup

```bash
# clone repository
git clone git@github.com:samhstn/website.git && cd website

npx http-server
```

### Run the dockerfile

```bash
docker build -t samhstn-website .
docker run -p 8080:8080 samhstn-website
```
