#!/usr/bin/env bash

mkdir -p ./temp/svgs
cp -a ./svgs/. ./temp/svgs/
wget -P ./temp https://github.com/flother/spreet/releases/download/v0.11.0/spreet-x86_64-unknown-linux-musl.tar.gz
tar -xzvf ./temp/spreet-x86_64-unknown-linux-musl.tar.gz -C ./temp
./temp/spreet --unique --minify-index-file --recursive ./temp/svgs/ ./sprites/nautical
./temp/spreet --unique --minify-index-file --recursive --retina ./temp/svgs/ ./sprites/nautical@2x
rm -r temp
