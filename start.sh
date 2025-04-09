#!/bin/bash

APP_DIR="/Users/juliansmith/code/crickett-challenges/filekeep/sync-service-rack"
cd "$APP_DIR" || exit

export GEM_HOME="$HOME/.gem/ruby/3.0.0"
export PATH="$GEM_HOME/bin:$PATH"

BUNDLER_VERSION="2.4.22"

if ! gem list bundler -i -v "$BUNDLER_VERSION" > /dev/null; then
  echo "Installing Bundler $BUNDLER_VERSION locally..."
  gem install bundler -v "$BUNDLER_VERSION" --no-document --user-install
fi

if command -v bundle &> /dev/null; then
  echo "Installing gems from Gemfile..."
  bundle _${BUNDLER_VERSION}_ install

  echo "Starting Rack app using Bundler $BUNDLER_VERSION..."
  bundle _${BUNDLER_VERSION}_ exec rackup -p 9292
else
  echo "Could not find 'bundle'. Starting with plain Ruby (rackup might still fail)..."
  ruby config.ru -p 9292
fi
