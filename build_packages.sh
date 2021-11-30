#!/bin/bash

set -e

version_iteration=1
version_number=`date +%Y.%m.%d`
main_email="darren@kiwiirc.com"
main_desc="Kiwi IRC server."
main_url="https://www.kiwiirc.com"
main_category="irc"
vendor_name="Kiwi IRC"
license_short="Licensed under the Apache License, Version 2.0"
source_comments="Source versions:"
tag_build=false

while getopts 'i:t:' OPTION; do
    case "$OPTION" in
        i)
            if [[ $OPTARG =~ ^[0-9]+$ ]]; then
                version_iteration="$OPTARG"
            else
                echo "Invalid iteration value passed to -i param, expected: '-i 2'"
                exit 1;
            fi
        ;;
        t)
            if [[ $OPTARG =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
                version_number="${OPTARG:1}"
                tag_build=true
            else
                echo "Invalid version tag passed to -t param, expected: '-t v1.2.3'"
                exit 1;
            fi
        ;;
    esac
done
shift "$(($OPTIND -1))"


function status () {
    echo ""
    echo "###"
    echo "### $@"
    echo "###"
}


# prepare directories and directory variables
build_dir=`pwd`
repo_dir="$build_dir/repos"
dist_dir="$build_dir/dist"
temp_dir="$build_dir/temp"

rm -rf $repo_dir $dist_dir $temp_dir
mkdir -p $repo_dir $dist_dir $temp_dir

export GOPATH="$build_dir/gopath"
# don't fail if $GOPATH cannot be removed
rm -rf $GOPATH || true
mkdir -p $GOPATH


version_full=v$version_number-$version_iteration
status "Kiwi IRC Packager"
echo
echo "building version: $version_full"


status "Download and build kiwiirc client"
git clone --depth=1 https://github.com/kiwiirc/kiwiirc.git $repo_dir/kiwiirc
cd $repo_dir/kiwiirc

if [ "$tag_build" = true ]; then
    # fetch tags and checkout the correct branch
    git fetch origin 'refs/tags/*:refs/tags/*'
    git checkout -b v$version_number refs/tags/v$version_number
fi

# add version information
source_comments="$source_comments kiwiirc=`node -e "console.log(require('./package.json').version);"`[`git rev-parse --short HEAD`]"

# build kiwiirc
yarn install
yarn build
cp LICENSE dist/

# replace kiwiServer in config
sed -i -r 's|"kiwiServer":.+,|"kiwiServer": "/webirc/kiwiirc/",|' $repo_dir/kiwiirc/dist/static/config.json

status "Preparing client zip"
mkdir -p $temp_dir/kiwiirc_$version_full
cp -r $repo_dir/kiwiirc/dist/* $temp_dir/kiwiirc_$version_full
cd $temp_dir
zip -r "${dist_dir}/kiwiirc-client_${version_full}_any.zip" "kiwiirc_$version_full/"
rm -rf $temp_dir/kiwiirc_$version_full
cd $build_dir


status "Download and build kiwiirc-desktop"
git clone --depth=1 https://github.com/kiwiirc/kiwiirc-desktop.git $repo_dir/kiwiirc-desktop
cd $repo_dir/kiwiirc-desktop

# link kiwiirc-desktop to kiwiirc client cloned above
rm -rf kiwiirc
ln -s $repo_dir/kiwiirc kiwiirc

# build kiwiirc-desktop
yarn install
yarn version --no-git-tag-version --new-version $version_full
yarn build:dist --win --linux --publish never

# move the completed pacakges to dist dir
mv build/*.{deb,rpm,zip,exe} $dist_dir
cd $build_dir


status "Download and build webircgateway"
git clone --depth=1 https://github.com/kiwiirc/webircgateway.git $repo_dir/webircgateway
cd $repo_dir/webircgateway

# add version information
source_comments="$source_comments server=`go run main.go --version`[`git rev-parse --short HEAD`]"

# build webircgateway variants
mkdir -p dist/
GOOS=darwin GOARCH=amd64 go build -o dist/webircgateway.darwin_amd64 main.go
GOOS=darwin GOARCH=arm64 go build -o dist/webircgateway.darwin_arm64 main.go
GOOS=linux GOARCH=386 GO386=sse2 go build -o dist/webircgateway.linux_i386 main.go
GOOS=linux GOARCH=amd64 go build -o dist/webircgateway.linux_amd64 main.go
GOOS=linux GOARCH=arm GOARM=5 go build -o dist/webircgateway.linux_armel main.go
GOOS=linux GOARCH=arm GOARM=6 go build -o dist/webircgateway.linux_armhf main.go
GOOS=linux GOARCH=arm64 go build -o dist/webircgateway.linux_arm64 main.go
GOOS=windows GOARCH=386 GO386=sse2 go build -o dist/webircgateway.windows_i386 main.go
GOOS=windows GOARCH=amd64 go build -o dist/webircgateway.windows_amd64 main.go
cd $build_dir


status "Preparing zip packages..."
make_zip () {
    pack_dir="$temp_dir/kiwiirc_${version_full}_$1"
    mkdir -p $pack_dir

    if [[ $1 == windows* ]]; then
        cp $repo_dir/webircgateway/dist/webircgateway.$1 $pack_dir/kiwiirc.exe
    else
        cp $repo_dir/webircgateway/dist/webircgateway.$1 $pack_dir/kiwiirc
        chmod +x $pack_dir/kiwiirc
    fi

    # copy webircgateway config
    cp $repo_dir/webircgateway/config.conf.example $pack_dir/config.conf

    # enable fileserving in config
    sed -i -r -z 's|(\[fileserving\]\nenabled =) false|\1 true|' $pack_dir/config.conf

    # copy kiwiirc client files
    mkdir -p $pack_dir/www
    cp -r $repo_dir/kiwiirc/dist/* $pack_dir/www/

    # add infoContent to config
    sed -i -r -z 's|("startupOptions" : \{)|\1\n        "infoContent": "<h3>Welcome to your Kiwi IRC page!</h3>You may want to customise or remove this message so please<br />glance over the www/static/config.json file.",|' $pack_dir/www/static/config.json

    # create zip file
    cd $temp_dir
    zip -r "$dist_dir/kiwiirc-server_${version_full}_$1.zip" "kiwiirc_${version_full}_$1/"

    # cleanup
    rm -rf $pack_dir
    cd $build_dir
}

# build the zip variants
make_zip darwin_amd64
make_zip darwin_arm64
make_zip linux_i386
make_zip linux_amd64
make_zip linux_armel
make_zip linux_arm64
make_zip linux_armhf
make_zip windows_i386
make_zip windows_amd64


status "Preparing distro packages..."
pack_dir="$temp_dir/package"

# Make directories
mkdir -p $pack_dir/etc/kiwiirc
mkdir -p $pack_dir/usr/bin
mkdir -p $pack_dir/usr/share/kiwiirc

# Copy server config and make adjustments
cp $repo_dir/webircgateway/config.conf.example $pack_dir/etc/kiwiirc/config.example.conf
sed -i -r -z 's|(\[fileserving\]\nenabled =) false(\nwebroot =) www/|\1 true\2 /usr/share/kiwiirc/|' $pack_dir/etc/kiwiirc/config.example.conf

# Copy client and symlink config to /etc/kiwiirc/
cp -r $repo_dir/kiwiirc/dist/* $pack_dir/usr/share/kiwiirc
mv $pack_dir/usr/share/kiwiirc/static/config.json $pack_dir/etc/kiwiirc/client.example.json
ln -s /etc/kiwiirc/client.json $pack_dir/usr/share/kiwiirc/static/config.json

# add infoContent to config
sed -i -r -z 's|("startupOptions" : \{)|\1\n        "infoContent": "<h3>Welcome to your Kiwi IRC page!</h3>You may want to customise or remove this message so please<br />glance over the /etc/kiwiirc/client.json file.",|' $pack_dir/etc/kiwiirc/client.example.json
cd $temp_dir

make_deb() {
    # add -e to edit before making package
    fpm -s dir -C ./package \
    -a "$1" \
    -p "$dist_dir/kiwiirc-server_${version_full}_linux_$1.deb" \
    -m "$main_email" \
    --description "$main_desc $source_comments" \
    -v $version_number \
    --iteration $version_iteration \
    -t deb \
    -n "kiwiirc" \
    --url "$main_url" \
    --category "$main_category" \
    --vendor "$vendor_name" \
    --license "$license_short" \
    --deb-init $build_dir/scripts/init/kiwiirc \
    --after-install $build_dir/scripts/deb/after-install \
    --before-remove $build_dir/scripts/deb/before-remove \
    --after-upgrade $build_dir/scripts/deb/after-upgrade
}

# call with make_rpm "arch"
make_rpm() {
    # add -e to edit before making package
    fpm -s dir -C ./package \
    -a "$1" \
    -p "$dist_dir/kiwiirc-server_${version_full}_linux_$1.rpm" \
    -m "$main_email" \
    --description "$main_desc $source_comments" \
    -v $version_number \
    --iteration $version_iteration \
    -t rpm \
    -n "kiwiirc" \
    --url "$main_url" \
    --category "$main_category" \
    --vendor "$vendor_name" \
    --license "$license_short" \
    --rpm-init $build_dir/scripts/init/kiwiirc \
    --after-install $build_dir/scripts/rpm/after-install \
    --before-remove $build_dir/scripts/rpm/before-remove \
    --after-upgrade $build_dir/scripts/rpm/after-upgrade \
    --rpm-os linux
}


status "Building i386..."
rm -f $pack_dir/usr/bin/kiwiirc
cp $repo_dir/webircgateway/dist/webircgateway.linux_i386 $pack_dir/usr/bin/kiwiirc
chmod 755 $pack_dir/usr/bin/kiwiirc

make_deb "i386"
make_rpm "i386"


status "Building amd64..."
rm -f $pack_dir/usr/bin/kiwiirc
cp $repo_dir/webircgateway/dist/webircgateway.linux_amd64 $pack_dir/usr/bin/kiwiirc
chmod 755 $pack_dir/usr/bin/kiwiirc

make_deb "amd64"
make_rpm "amd64"


status "Building armel..."
rm -f $pack_dir/usr/bin/kiwiirc
cp $repo_dir/webircgateway/dist/webircgateway.linux_armel $pack_dir/usr/bin/kiwiirc
chmod 755 $pack_dir/usr/bin/kiwiirc

make_deb "armel"
make_rpm "armel"


status "Building armhf..."
rm -f $pack_dir/usr/bin/kiwiirc
cp $repo_dir/webircgateway/dist/webircgateway.linux_armhf $pack_dir/usr/bin/kiwiirc
chmod 755 $pack_dir/usr/bin/kiwiirc

make_deb "armhf"
make_rpm "armhf"


status "Building arm64..."
rm -f $pack_dir/usr/bin/kiwiirc
cp $repo_dir/webircgateway/dist/webircgateway.linux_arm64 $pack_dir/usr/bin/kiwiirc
chmod 755 $pack_dir/usr/bin/kiwiirc

make_deb "arm64"
make_rpm "arm64"

status "Cleaning up..."
rm -rf $repo_dir $temp_dir
# don't fail if $GOPATH cannot be removed
rm -rf $GOPATH || true

status "Package building complete!"
ls -lh $dist_dir
