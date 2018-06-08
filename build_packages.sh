#!/bin/bash

set -e

source_version=`date +%y.%m.%d`.1
package_iteration=1
main_email="darren@kiwiirc.com"
main_desc="Kiwi IRC server."
main_url="https://www.kiwiirc.com"
main_category="irc"
vendor_name="Kiwi IRC"
license_short="Licensed under the Apache License, Version 2.0"

source_comments="Source build versions: "

rm -rf kiwiirc webircgateway build-dir gopath

function status () {
	echo ""
	echo "###"
	echo "### $@"
	echo "###"
}

status Downloading and building the client...

git clone --depth=1 https://github.com/kiwiirc/kiwiirc.git
cd kiwiirc
yarn install
npm run build
cp LICENSE dist/
source_comments="$source_comments kiwiirc=`node -e "console.log(require('./package.json').version);"` "
cd ..

status Downloading and building the server...
export GOPATH="`pwd`/gopath"
mkdir -p $GOPATH/bin/
go get github.com/kiwiirc/webircgateway
main_go="$GOPATH/src/github.com/kiwiirc/webircgateway/main.go"
source_comments="$source_comments server=`go run $main_go --version`"

# install and run dep ensure
build_dir="`pwd`"
curl https://raw.githubusercontent.com/golang/dep/master/install.sh | sh
cd $GOPATH/src/github.com/kiwiirc/webircgateway/
$GOPATH/bin/dep ensure
cd $build_dir

status Building...
mkdir webircgateway/
GOOS=darwin GOARCH=amd64 go build -o webircgateway/webircgateway.darwin $main_go
GOOS=linux GOARCH=386 go build -o webircgateway/webircgateway.linux_386 $main_go
GOOS=linux GOARCH=amd64 go build -o webircgateway/webircgateway.linux_amd64 $main_go
GOOS=linux GOARCH=arm GOARM=5 go build -o webircgateway/webircgateway.linux_armel $main_go
GOOS=linux GOARCH=arm GOARM=6 go build -o webircgateway/webircgateway.linux_armhf $main_go
GOOS=linux GOARCH=arm64 go build -o webircgateway/webircgateway.linux_arm64 $main_go
GOOS=windows GOARCH=386 go build -o webircgateway/webircgateway.windows_386 $main_go
GOOS=windows GOARCH=amd64 go build -o webircgateway/webircgateway.windows_amd64 $main_go


packageDist () {
	date=`date +%Y%m%d`
	folder=kiwiirc_$date_$1
	mkdir $folder

    if [[ $1 == windows* ]]; then
        cp webircgateway/webircgateway.$1 $folder/kiwiirc.exe
    else
        cp webircgateway/webircgateway.$1 $folder/kiwiirc
        chmod +x $folder/kiwiirc
    fi

	mkdir $folder/www
	cp -r kiwiirc/dist/* $folder/www/
	cp -r tomerge/* $folder

	zip -r "packaged/kiwiirc_"$source_version"_"$1".zip" $folder
	rm -rf $folder
}


status Preparing zip packages...
mkdir -p packaged
packageDist darwin
packageDist linux_386
packageDist linux_amd64
packageDist linux_armel
packageDist linux_armhf
packageDist linux_arm64
packageDist windows_386
packageDist windows_amd64


status Preparing distro packages...
mkdir -p build-dir/etc/kiwiirc
mkdir -p build-dir/usr/bin
mkdir -p build-dir/usr/share/kiwiirc

cp -r kiwiirc/dist/* build-dir/usr/share/kiwiirc
rm build-dir/usr/share/kiwiirc/static/config.json
ln -s /etc/kiwiirc/client.json build-dir/usr/share/kiwiirc/static/config.json

cat tomerge/config.conf.example | sed "s/^webroot.*$/webroot\ \=\ \/usr\/share\/kiwiirc\//" > build-dir/etc/kiwiirc/config.conf.example
cp tomerge/www/static/config.json build-dir/etc/kiwiirc/client.json


# call with make_deb "arch"
make_deb() {
	# add -e to edit before making package
	fpm -s dir -C ./build-dir \
	-a "$1" \
	-m "$main_email" \
	--description "$main_desc $source_comments" \
	-v $source_version \
	--iteration $package_iteration \
	-t deb \
	-n "kiwiirc" \
	--url "$main_url" \
	--category "$main_category" \
	--vendor "$vendor_name" \
	--license "$license_short" \
	--deb-init scripts/init/kiwiirc \
	--after-install scripts/deb/after-install \
	--before-remove scripts/deb/before-remove \
	--after-upgrade scripts/deb/after-upgrade
}

# call with make_rpm "arch"
make_rpm() {
	# add -e to edit before making package
	fpm -s dir -C ./build-dir \
	-a "$1" \
	-m "$main_email" \
	--description "$main_desc $source_comments" \
	-v $source_version \
	--iteration $package_iteration \
	-t rpm \
	-n "kiwiirc" \
	--url "$main_url" \
	--category "$main_category" \
	--vendor "$vendor_name" \
	--license "$license_short" \
	--rpm-init scripts/init/kiwiirc \
	--after-install scripts/rpm/after-install \
	--before-remove scripts/rpm/before-remove \
	--after-upgrade scripts/rpm/after-upgrade \
	--rpm-os linux
}

status Building i386...
rm -f build-dir/usr/bin/kiwiirc
cp webircgateway/webircgateway.linux_386 build-dir/usr/bin/kiwiirc
chmod 755 build-dir/usr/bin/kiwiirc

make_deb "i386"
make_rpm "i386"


status Building amd64...
rm -f build-dir/usr/bin/kiwiirc
cp webircgateway/webircgateway.linux_amd64 build-dir/usr/bin/kiwiirc
chmod 755 build-dir/usr/bin/kiwiirc

make_deb "amd64"
make_rpm "amd64"

status Building armel...
rm -f build-dir/usr/bin/kiwiirc
cp webircgateway/webircgateway.linux_armel build-dir/usr/bin/kiwiirc
chmod 755 build-dir/usr/bin/kiwiirc

make_deb "armel"
make_rpm "armel"

status Building armhf...
rm -f build-dir/usr/bin/kiwiirc
cp webircgateway/webircgateway.linux_armhf build-dir/usr/bin/kiwiirc
chmod 755 build-dir/usr/bin/kiwiirc

make_deb "armhf"
make_rpm "armhf"

status Building arm64...
rm -f build-dir/usr/bin/kiwiirc
cp webircgateway/webircgateway.linux_arm64 build-dir/usr/bin/kiwiirc
chmod 755 build-dir/usr/bin/kiwiirc

make_deb "arm64"
make_rpm "arm64"

mv *.deb *.rpm packaged/

status Cleaning up...
rm -rf kiwiirc webircgateway build-dir gopath

status Building packages complete!
ls -lh packaged
