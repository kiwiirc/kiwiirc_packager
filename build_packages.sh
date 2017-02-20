#!/bin/bash

source_version=1.0
package_iteration=1
main_email="darren@kiwiirc.com"
main_desc="Kiwi IRC webircgateway installer"
main_url="https://www.kiwiirc.com"
main_category="irc"
vendor_name="Kiwi IRC"
license_short="Licensed under the Apache License, Version 2.0"


rm -rf kiwiirc webircgateway build-dir

echo Downloading and building the client...
git clone --depth=1 https://github.com/kiwiirc/kiwiirc.git
cd kiwiirc
yarn install
npm run build
cp LICENSE dist/
cd ..

echo Downloading and building the server...
git clone --depth=1 https://github.com/kiwiirc/webircgateway.git
cd webircgateway
./webircgateway.sh prepare

echo Building...
GOOS=darwin GOARCH=amd64 ./webircgateway.sh build webircgateway.darwin
GOOS=linux GOARCH=386 ./webircgateway.sh build webircgateway.linux_386
GOOS=linux GOARCH=amd64 ./webircgateway.sh build webircgateway.linux_amd64
cd ..


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


echo Preparing zip packages...
mkdir -p packaged
packageDist darwin
packageDist linux_386
packageDist linux_amd64


echo Preparing distro packages...
mkdir -p build-dir/etc/kiwiirc
mkdir -p build-dir/usr/bin
mkdir -p build-dir/usr/share/kiwiirc

cp -r kiwiirc/dist/* build-dir/usr/share/kiwiirc
rm build-dir/usr/share/kiwiirc/static/config.json
ln -s /etc/kiwiirc/client.json build-dir/usr/share/kiwiirc/static/config.json

cat tomerge/config.conf | sed "s/^webroot.*$/webroot\ \=\ \/usr\/share\/kiwiirc\//" > build-dir/etc/kiwiirc/config.conf
cp tomerge/www/static/config.json build-dir/etc/kiwiirc/client.json


# call with make_deb "arch"
make_deb() {
	# add -e to edit before making package
	fpm -s dir -C ./build-dir \
	-a "$1" \
	-m "$main_email" \
	--description "$main_desc" \
	-v $source_version \
	--iteration $package_iteration \
	-t deb \
	-n "webircgateway" \
	--url "$main_url" \
	--category "$main_category" \
	--vendor "$vendor_name" \
	--license "$license_short" \
	--deb-init scripts/init/webircgateway \
	--after-install scripts/deb/after-install \
	--before-remove scripts/deb/before-remove \
	--after-upgrade scripts/deb/after-upgrade \
	--deb-no-default-config-files
}

# call with make_rpm "arch"
make_rpm() {
	# add -e to edit before making package
	fpm -s dir -C ./build-dir \
	-a "$1" \
	-m "$main_email" \
	--description "$main_desc" \
	-v $source_version \
	--iteration $package_iteration \
	-t rpm \
	-n "webircgateway" \
	--url "$main_url" \
	--category "$main_category" \
	--vendor "$vendor_name" \
	--license "$license_short" \
	--rpm-init scripts/init/webircgateway \
	--after-install scripts/rpm/after-install \
	--before-remove scripts/rpm/before-remove \
	--after-upgrade scripts/rpm/after-upgrade
}

echo Building i386...
rm -f build-dir/usr/bin/webircgateway
cp webircgateway/webircgateway.linux_386 build-dir/usr/bin/webircgateway
chmod 755 build-dir/usr/bin/webircgateway

make_deb "i386"
make_rpm "i386"


echo Building amd64...
rm -f build-dir/usr/bin/webircgateway
cp webircgateway/webircgateway.linux_amd64 build-dir/usr/bin/webircgateway
chmod 755 build-dir/usr/bin/webircgateway

make_deb "amd64"
make_rpm "amd64"

mv *.deb *.rpm packaged/

echo Cleaning up...
rm -rf kiwiirc webircgateway build-dir

echo Done
ls packaged
