#!/bin/bash

if [ ! -e config/locales/default.yml ]; then
    echo "Call from project root, please"
    exit 1
fi


cd ./config/locales || exit 1
i18n-translate convert -f po -t yml --locale_dir=. || exit 1
cp -v default.yml en.yml || exit 1
sed -i "s/default:/en:/" en.yml || exit 1
for lang in es fr; do
    ./patch.pl < $lang.yml > $lang.yml.translate || exit 1
    cp -v $lang.yml.translate $lang.yml || exit 1
    rm -f $lang.yml.translate || exit 1
done

