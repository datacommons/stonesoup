#!/bin/bash

set -ex

docker build -t stonesoup_cc .

if [ ! -e config/database.yml ]; then
  (
  cat <<EOF
development:
  adapter: sqlite3
  database: stonesoup.sqlite3
production:
  adapter: sqlite3
  database: stonesoup.sqlite3
geocode_cache_db:
  adapter: sqlite3
  database: stonesoup.sqlite3
EOF
  ) > config/database.yml
fi

if [ ! -e stonesoup.sqlite3 ]; then
  echo "Need a database."
  exit 1
fi

docker stop stonesoup || echo ok
docker kill stonesoup || echo ok
docker rm stonesoup || echo ok

# this will work only if you don't have spaces or other odd characters in your path
docker run --rm --name stonesoup -p 4040:4040 -v $PWD:$PWD -w $PWD -dit stonesoup_cc nginx -g 'daemon off;'

docker ps
