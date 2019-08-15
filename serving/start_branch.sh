#!/bin/bash
set -ex

if [ "$1" = "" ]; then
    echo "Please supply tag (prod or staging)"
    exit 1
fi

tag="$1"
container="stonesoup_$tag"

port=""
if [ "$tag" = "prod" ]; then
    port="4040"
fi
if [ "$tag" = "staging" ]; then
    port="4041"
fi
if [ "$port" = "" ]; then
    echo "Don't know port to use for $tag"
    exit 1
fi

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

touch /tmp/restart_$tag.txt
which inotifywait || exit 1

set -o pipefail  # trace ERR through pipes
set -o nounset   # same as set -u : treat unset variables as an error
set -o errtrace  # same as set -E: inherit ERR trap in functions
set -o errexit   # same as set -e: exit on command failures
trap 'cleanup' EXIT
trap 'echo "Exiting on SIGINT"; exit 1' INT
trap 'echo "Exiting on SIGTERM"; exit 1' TERM

stop() {
    docker stop $container || echo ok
    docker kill $container || echo ok
    docker rm $container || echo ok
}

cleanup() {
    stop
}


if [ ! -e stonesouper ]; then
    git clone https://github.com/paulfitz/stonesouper
fi
cd stonesouper
git stash
git pull
cd ..

while true; do
    docker run --rm --name $container -p $port:4040 -v "$PWD:$PWD" -w "$PWD" -dit stonesoup_cc nginx -g 'daemon off;'
    sleep 2
    docker exec -dit $container script/server -e production
    docker exec -dit $container script/node
    echo "Waiting for /tmp/restart_$tag.txt"
    inotifywait /tmp/restart_$tag.txt
    stop
    if [ -e /tmp/stop_$tag.txt ]; then
	echo "stopping because /tmp/stop_$tag.txt"
	exit 1
    fi
done
