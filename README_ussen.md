
You'll need docker to run this, and a sqlite database.
Run this first from the root directory of the repository:

```
$ ./serving/start_parent.sh
```

It will take a long time the first time as it builds
a docker image (if you have any trouble, I can send
you a prebuilt image).

Once it is done, you should see a single docker
container running, called `solid`:

```
$ docker ps
CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS                    NAMES
9efc91ba120a        stonesoup_cc        "nginx -g 'daemon of…"   3 days ago          Up 3 days           0.0.0.0:4040->4040/tcp   stonesoup
```

You'll also need to edit `/etc/hosts and make sure that
dev.solidarityeconomy.us is set up to point to your machine
with a line like this:

```
$ sudo nano /etc/hosts
...
127.0.0.1    dev.solidarityeconomy.us
```

If that is done, and you visit http://dev.solidarityeconomy.us:4040/test,
you should see:

```
hello I am here
```

That's a good sign, it is nginx saying it is running.  But there's no
website yet.

Before the next step, you'll need a `stonesoup.sqlite3` file from
Paul.  Place it in the root directory of the repository.

```
$ ls *.sqlite3
stonesoup.sqlite3
```


Great, now you can start the rails server as follows:

```
$ ./serving/start_rails.sh
```

After some time, if you visit http://dev.solidarityeconomy.us:4040,
you will now see the solidarity economy site in all its glory,
minus the maps.

To get the maps, in a separate console in the same directory,
do:

```
$ ./serving/start_node.sh
```

This will take some time the first time it runs to install
and compile some stuff.  But then maps should load just fine.
