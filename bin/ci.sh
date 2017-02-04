#!/usr/bin/env bash
set -e # halt script on error

bundle exec jekyll build

LAST_POST=$(ls _posts/ -1 | sort | tail -n 1 | sed 's/[0-9]*-[0-9]*-[0-9]*-//g' | sed 's/.md$//g')
bundle exec htmlproofer --url-ignore "http://prestodb.rocks/${LAST_POST}/,#" ./_site
