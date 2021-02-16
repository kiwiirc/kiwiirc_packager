# kiwiirc_packager
Builds Kiwi IRC packages for distribution.

Complete Packages: https://kiwiirc.com/downloads/index.html

What it does:

1. Clones and builds `https://github.com/kiwiirc/kiwiirc.git`
2. Clones and compiles `https://github.com/kiwiirc/webircgateway.git` for multiple OSs
3. Merges the two projects together and adds default configuration files to get it running as easy as possible
4. Zips each package up into the packaged/ folder
5. Builds deb and rpm files for i386 and amd64
6. Builds dep/rpm/dmg/exe/zip packages for kiwiirc desktop (os dependant)

<br />

# MacOS Notes <span style="font-size:0.5em;">(can build all kiwiirc desktop packages)</span>

Install Xcode from the app store and the following packages.

### Homebrew see https://brew.sh/

``` bash
$ brew install golang nodejs yarn rpm gnu-tar
```

### Ruby's fpm

``` bash
$ gem install --no-document fpm -v 1.11.0
```
*note: fpm version 1.12.0 has errors building rpm packages*

*note: If having issues installing fpm try an older xcode command line tools*
* Download Command Line Tools 11.5 from [Apple Developer Downloads](https://developer.apple.com/download/more/?=xcode)
* `sudo rm -rf /Library/Developer/CommandLineTools`
* Install Command Line Tools from .dmg/.pkg
* `sudo xcode-select --switch /Library/Developer/CommandLineTools`
* after gem install switch back to xcode with: `sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer`
