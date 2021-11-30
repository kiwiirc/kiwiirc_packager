#!/bin/bash
sudo apt-get update
sudo apt-get install -y build-essential curl git libffi-dev libfontconfig1 rpm ruby ruby-dev software-properties-common zip

# GoLang
sudo add-apt-repository -y ppa:longsleep/golang-backports

# Yarn
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list

# NodeJS
curl -sL https://deb.nodesource.com/setup_14.x | sudo bash -

# the nodejs script above also runs apt-get update
sudo apt-get install -y golang-go nodejs yarn

sudo gem install fpm

# kiwiirc-desktop electron requirements
sudo dpkg --add-architecture i386
wget -qO- https://dl.winehq.org/wine-builds/winehq.key | sudo apt-key add -
sudo apt-get install software-properties-common
sudo apt-add-repository "deb http://dl.winehq.org/wine-builds/ubuntu/ $(lsb_release -cs) main"
sudo apt-get update -y
sudo apt-get install -y libopenjp2-tools libarchive-tools gcc-multilib g++-multilib winehq-stable
