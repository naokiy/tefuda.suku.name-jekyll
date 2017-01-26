#!/usr/bin/env bash

set -eux

bundle install --path vendor/bundle
bundle exec rake convert_front_matter['_posts']
bundle exec jekyll build --trace
