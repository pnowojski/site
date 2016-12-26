#!/usr/bin/env bash
set -e # halt script on error

mkdir -p logs

bundle exec jekyll serve --watch > logs/serve.out 2> logs/serve.err &

