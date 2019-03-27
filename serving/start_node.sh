#!/bin/bash

set -ex

if [ ! -e stonesouper ]; then
  git clone https://github.com/paulfitz/stonesouper
fi

cd stonesouper
git pull

docker exec -it stonesoup script/node

