#!/usr/bin/env bash

set -eux

chmod 600 .deploy_key
bundle exec rake deploy --trace
