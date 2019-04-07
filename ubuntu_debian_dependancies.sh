#!/bin/bash
sudo apt-get update
sudo apt-get install -y build-essential curl git libffi-dev libfontconfig1 rpm ruby ruby-dev software-properties-common zip

# GoLang
sudo add-apt-repository -y ppa:longsleep/golang-backports

# Yarn
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list

# NodeJS
curl -sL https://deb.nodesource.com/setup_10.x | sudo bash -

# the nodejs script above also runs apt-get update
sudo apt-get install -y golang-go nodejs yarn

sudo gem install fpm
