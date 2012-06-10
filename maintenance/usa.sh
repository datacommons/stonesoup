#!/bin/bash

# standardize the spelling of the US, erm I mean, the United States.

function replace_country {
    col="$1"
    from="$2"
    to="$3"
    echo -n "UPDATE locations SET ${col}_country = \"$to\" WHERE ${col}_country = \"$from\""
    if [ "k$from" = "k" ]; then
	echo -n " AND (${col}_address1 <> \"\" OR ${col}_city <> \"\" OR ${col}_state <> \"\")"
    fi
    echo ";"
}

target="United States"
for col in physical mailing; do
    replace_country $col "United States of America" "$target"
    replace_country $col "USA" "$target"
    replace_country $col "US" "$target"
    replace_country $col "U.S." "$target"
    replace_country $col "" "$target"
done
