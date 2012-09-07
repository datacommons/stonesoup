#!/bin/bash

if [ ! -e config/locales/default.yml ]; then
    echo "Call from project root, please"
    exit 1
fi

cd ./config/locales || exit 1

if [ ! "k$1" = "k" ]; then
    # have a download from launchpad
    fname="/tmp/findcoop_translation.tar.gz"
    rm -f $fname
    wget -O $fname $1 || exit 1
    base=$PWD
    cd /tmp
    rm -rf findcoop_translation
    mkdir findcoop_translation || exit 1
    cd findcoop_translation || exit 1
    tar xzvf $fname || exit 1
    org=$PWD
    cd $base || exit 1
    for lang in es fr; do
	cp $org/config/locales/findcoop-$lang.po $lang.po || exit 1
    done
fi

i18n-translate convert -f po -t yml --locale_dir=. || exit 1
cp -v default.yml en.yml || exit 1
sed -i "s/default:/en:/" en.yml || exit 1
for lang in es fr; do
    echo $lang "$lang.po -> $lang.yml"
    ./patch2.pl $lang < $lang.po > $lang.yml || exit 1
done

