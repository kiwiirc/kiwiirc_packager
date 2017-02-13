#!/bin/bash

echo Downloading and building the client...
git clone --depth=1 https://github.com/kiwiirc/kiwiirc.git
cd kiwiirc
yarn install
npm run build

echo Downloading and building the server...
cd ..
git clone --depth=1 https://github.com/kiwiirc/webircgateway.git
cd webircgateway
./webircgateway.sh prepare

echo Building...
GOOS=darwin GOARCH=amd64 ./webircgateway.sh build webircgateway.darwin
GOOS=linux GOARCH=386 ./webircgateway.sh build webircgateway.linux_386
GOOS=linux GOARCH=amd64 ./webircgateway.sh build webircgateway.linux_amd64

packageDist () {
	date=`date +%Y%m%d`
	folder=kiwiirc_$date_$1
	mkdir $folder

	cp webircgateway/webircgateway.$1 $folder/webircgateway
	chmod +x $folder/webircgateway

	mkdir $folder/www
	cp -r kiwiirc/dist/* $folder/www/
	cp -r tomerge/* $folder

	zip -r packaged/kiwiirc_$1.zip $folder
	rm -rf $folder
}

echo Preparing packages...

cd ..
mkdir packaged
packageDist darwin
packageDist linux_386
packageDist linux_amd64

rm -rf kiwiirc
rm -rf webircgateway

ls -lh

echo Done!
