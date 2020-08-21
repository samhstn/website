#!/bin/bash

mix do deps.get, compile

mix test

SECRET_KEY_BASE=$(mix phx.gen.secret) mix phx.server
