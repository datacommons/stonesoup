Stone Soup, the Data Commons Directory
======================================

There are somewhat out of date instructions at http://cultivate.coop/wiki/Data_Commons_Directory

This is a Ruby on Rails project. We're using ruby-1.8.7.
Make sure to connect a database:
```
$ cp config/database.yml.dist config/database.yml
```
(this file will need editing).  

Create an empty database:
```
$ rake db:create
$ rake db:reset
$ rake db:migrate
```

You can then run the development server as:
```
$ ./script/server
```

To enable search indexing, do:
```
$ ruby ./script/ferret_server -e development -R `pwd` start
```
