# samhstn.com

[samhstn.com](http://samhstn.com)

### Requirements

```bash
$ docker --version
Docker version 19.03.12

$ python3 --version
Python 3.8.5

$ aws --version
aws-cli/2.0.40 Python/3.8.5

$ node --version
v14.8.0

$ elixir --version
Erlang/OTP 23 [erts-11.0.3] [source] [64-bit] [smp:12:12] [ds:12:12:10] [async-threads:1] [hipe] [dtrace]

Elixir 1.10.4 (compiled with Erlang/OTP 23)

$ mix --version
Mix 1.10.4

$ mix phx.new --version
Phoenix v1.5.4
```

### Local Setup

```bash
# clone repository
git clone git@github.com:samhstn/samhstn.git && cd samhstn

# install dependencies and run our tests and checks
MIX_ENV=test mix compile --force
MIX_ENV=test mix dialyzer
MIX_ENV=test mix sobelow --router lib/samhstn_web/router.ex --exit --skip
MIX_ENV=test mix format --check-formatted
mix test

# start the dev server
mix do compile, phx.server
```

### AWS Setup

Checkout the [infra](./infra/README.md) documentation for guidance.

### Pre-commit hook

To configure the pre-commit hook to run on every commit, run:

```bash
./pre-commit-hook
```

### Docker

Our app runs in two stages:
+ Building our mix release.
+ Running the binary files from our mix release.

This can be achieved by setting up a `.env` file with the following contents:

```
export AWS_ACCESS_KEY_ID=
export AWS_SECRET_ACCESS_KEY=
export SECRET_KEY_BASE=g+Li...Fi+trohKSao4VOv5BWkEXAMPLE
export SAMHSTN_ASSETS_BUCKET=
```

We can generate these access keys for our `docker` IAM user in:

`IAM Console > Security Credentials > Create access key`.

We can now replicate our application running in production with:

```bash
docker-compose up --build
```

Note: These IAM user credentials should be deleted after running Docker locally.
