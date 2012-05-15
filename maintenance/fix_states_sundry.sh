#!/bin/bash

# some manual tweaking

cat<<EOF
create temporary table us_states (name char(255), code char(255));
load data local infile 'us_states.csv' into table us_states fields terminated by ',' enclosed by '"' lines terminated by '\n' (name, code);

create temporary table ca_states (name char(255), code char(255));
load data local infile 'ca_states.csv' into table ca_states fields terminated by ',' enclosed by '"' lines terminated by '\n' (name, code);
EOF

for col in physical mailing; do
    echo "UPDATE locations set ${col}_state = TRIM(${col}_state);"
    echo "CREATE TEMPORARY TABLE dodgy_${col}_states SELECT DISTINCT ${col}_state ${col}_country FROM locations WHERE ${col}_state <> \"\" AND ${col}_country IS NULL;"
    echo "SELECT * FROM dodgy_${col}_states;"

    # United States
    echo "UPDATE locations, us_states SET locations.${col}_country = 'United States' WHERE us_states.code = locations.${col}_state AND locations.${col}_country IS NULL;"
    echo "UPDATE locations, us_states SET locations.${col}_state = us_states.name WHERE us_states.code = locations.${col}_state AND locations.${col}_country = 'United States';"
    echo "UPDATE locations, us_states SET locations.${col}_country = 'United States' WHERE us_states.name = locations.${col}_state AND locations.${col}_country IS NULL;"

    # Canada
    echo "UPDATE locations set ${col}_state = 'NB' where ${col}_state IN ('N-B','N.B.') AND ${col}_country IS NULL;"
    echo "UPDATE locations set ${col}_state = 'BC' where ${col}_state IN ('B-C','B.C.') AND ${col}_country IS NULL;"
    echo "UPDATE locations, ca_states SET locations.${col}_country = 'Canada' WHERE ca_states.code = locations.${col}_state AND locations.${col}_country IS NULL;"
    echo "UPDATE locations, ca_states SET locations.${col}_state = ca_states.name WHERE ca_states.code = locations.${col}_state AND locations.${col}_country = 'Canada';"
    echo "UPDATE locations, ca_states SET locations.${col}_country = 'Canada' WHERE ca_states.name = locations.${col}_state AND locations.${col}_country IS NULL;"
done
