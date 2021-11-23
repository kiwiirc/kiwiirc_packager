#!/bin/bash

set -e

version_tag=$1
source_version=`date +%y.%m.%d`.1
package_iteration=1
main_email="darren@kiwiirc.com"
main_desc="Kiwi IRC server."
main_url="https://www.kiwiirc.com"
main_category="irc"
vendor_name="Kiwi IRC"
license_short="Licensed under the Apache License, Version 2.0"

source_comments="Source build versions: "

if [[ $version_tag == v* ]]; then
	source_version="$version_tag"
fi

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
mkdir -p $GOPATH
git clone --depth=1 https://github.com/kiwiirc/webircgateway.git
cd webircgateway
source_comments="$source_comments server=`go run main.go --version`"

status Building...
mkdir builds/
GOOS=darwin GOARCH=amd64 go build -o dist/webircgateway.darwin_amd64 main.go
GOOS=darwin GOARCH=arm64 go build -o dist/webircgateway.darwin_arm64 main.go
GOOS=linux GOARCH=386 GO386=sse2 go build -o dist/webircgateway.linux_386 main.go
GOOS=linux GOARCH=amd64 go build -o dist/webircgateway.linux_amd64 main.go
GOOS=linux GOARCH=arm GOARM=5 go build -o dist/webircgateway.linux_armel main.go
GOOS=linux GOARCH=arm GOARM=6 go build -o dist/webircgateway.linux_armhf main.go
GOOS=linux GOARCH=arm64 go build -o dist/webircgateway.linux_arm64 main.go
GOOS=windows GOARCH=386 GO386=sse2 go build -o dist/webircgateway.windows_386 main.go
GOOS=windows GOARCH=amd64 go build -o dist/webircgateway.windows_amd64 main.go
cd ..

packageDist () {
	date=`date +%Y%m%d`
	folder=kiwiirc_$date_$1
	mkdir $folder

	if [[ $1 == windows* ]]; then
		cp webircgateway/dist/webircgateway.$1 $folder/kiwiirc.exe
	else
		cp webircgateway/dist/webircgateway.$1 $folder/kiwiirc
		chmod +x $folder/kiwiirc
	fi

	mkdir $folder/www
	cp -r kiwiirc/dist/* $folder/www/
	cp -r tomerge/* $folder

	zip -r "packaged/kiwiirc_"$source_version"-"$package_iteration"_"$1".zip" $folder
	rm -rf $folder
}


status Preparing zip packages...
mkdir -p packaged
packageDist darwin_amd64
packageDist darwin_arm64
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


status Build client zip
mkdir -p to-zip/kiwiirc
cp -r kiwiirc/dist/* to-zip/kiwiirc
zip -r "packaged/kiwiirc-client_"$source_version"-"$package_iteration"_any.zip" to-zip/


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
cp webircgateway/dist/webircgateway.linux_386 build-dir/usr/bin/kiwiirc
chmod 755 build-dir/usr/bin/kiwiirc

make_deb "i386"
make_rpm "i386"


status Building amd64...
rm -f build-dir/usr/bin/kiwiirc
cp webircgateway/dist/webircgateway.linux_amd64 build-dir/usr/bin/kiwiirc
chmod 755 build-dir/usr/bin/kiwiirc

make_deb "amd64"
make_rpm "amd64"

status Building armel...
rm -f build-dir/usr/bin/kiwiirc
cp webircgateway/dist/webircgateway.linux_armel build-dir/usr/bin/kiwiirc
chmod 755 build-dir/usr/bin/kiwiirc

make_deb "armel"
make_rpm "armel"

status Building armhf...
rm -f build-dir/usr/bin/kiwiirc
cp webircgateway/dist/webircgateway.linux_armhf build-dir/usr/bin/kiwiirc
chmod 755 build-dir/usr/bin/kiwiirc

make_deb "armhf"
make_rpm "armhf"

status Building arm64...
rm -f build-dir/usr/bin/kiwiirc
cp webircgateway/dist/webircgateway.linux_arm64 build-dir/usr/bin/kiwiirc
chmod 755 build-dir/usr/bin/kiwiirc

make_deb "arm64"
make_rpm "arm64"

mv *.deb *.rpm packaged/

status Cleaning up...
rm -rf kiwiirc webircgateway build-dir to-zip
# don't fail if gopath cannot be removed
rm -rf gopath || true

status Building packages complete!
ls -lh packaged
