#!/bin/sh
script/ferret_server start
script/server -p 8474
script/ferret_server stop
