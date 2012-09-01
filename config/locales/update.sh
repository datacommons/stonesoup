#!/bin/sh

# Assume we edit:
#   default.yml
#   *.po
# All other .yml files are auto-generated.
# The *.pot file is auto-generated.

if [ ! -e config/locales/default.yml ]; then
    echo "Call from project root, please"
    exit 1
fi

tmp="tmp_translate"

base="$PWD"
rm -rf $tmp

mkdir -p $tmp || exit 1
cd $tmp || exit 1
cp -R ../config/locales locale || exit 1

# from https://github.com/pejuko/i18n-translators-tools
i18n-translate merge || exit 1

# i18n-translate convert -f po -t rb || exit 1
# itranslate convert -f po -t yml || exit 1

cp locale/en.po locale/findcoop.pot || exit 1

# cd $base || exit 1
# rm -rf $tmp

cp -v locale/findcoop.pot ../config/locales
