#!/usr/bin/env bash

set -eux

bundle install --path vendor/bundle
bundle exec rake load_all_mtgjson['_additional_data/mtgjson'] --trace
bundle exec rake convert_front_matter['_posts'] --trace
bundle exec jekyll build --trace
