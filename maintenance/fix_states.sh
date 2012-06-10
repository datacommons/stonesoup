#!/bin/bash

# figure out the country associate with states, by looking at existing
# complete entries.

for col in physical mailing; do
    echo "CREATE TEMPORARY TABLE dodgy_${col}_states SELECT DISTINCT ${col}_state ${col}_country FROM locations WHERE ${col}_state <> \"\" AND ${col}_country IS NULL;"
    echo "CREATE TEMPORARY TABLE fixer_${col}_states SELECT DISTINCT ${col}_state, ${col}_country FROM locations WHERE ${col}_country IS NOT NULL AND EXISTS (SELECT ${col}_state FROM dodgy_${col}_states WHERE ${col}_state = locations.${col}_state);"
    echo "UPDATE locations, fixer_${col}_states SET locations.${col}_country = fixer_${col}_states.${col}_country WHERE fixer_${col}_states.${col}_state = locations.${col}_state AND locations.${col}_country IS NULL;"
done

