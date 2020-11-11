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

# install dependencies, run tests and start the dev server
./bootstrap.sh
```

### AWS Setup

Checkout the [infra](./infra/README.md) documentation for guidance.

### Pre-commit hook

To configure the pre-commit hook to run on every commit, run:

```bash
./pre-commit-hook
```
