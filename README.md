# Moodle application with behat and phpunit.
![logo](https://moodle.org/theme/image.php/moodleorgcleaned_moodleorg/theme_moodleorgcleaned/1447866970/moodle-logo)

## Initial setup
Initial setup needed on host machine.

### Step 1: Install [docker]
* [Install docker binary]

### Step 2: Docker image
* **Build your own image**
```sh
git clone https://rajeshtaneja.github.com/docker.git
cd docker
docker build -t {username}/moodle:master \
    --build-arg GITREPOSITORY=git://git.moodle.org/integration.git \
    --build-arg GITREMOTE=integration \
    --build-arg GITBRANCH=master \
    .
```
> use --build-arg IGNORECLONE=1, if you don't want to have a local copy of moodle in docker image and map it while running.

* **Download [official] image**
```sh
    docker pull moodlehq/moodle:master
```

## Run application

### 1. Moodle web application
Run Moodle [official] application 
* **Interactive**
```sh
docker run --name moodle -ti moodlehq/moodle:master /scripts/init.php --keepalive

or with your own copy of moodle

docker run --name moodle -v {PATH_TO_MOODLE_DIR_ON_HOST}/moodle:/var/www/html/moodle -ti moodlehq/moodle:master /scripts/init.php --keepalive
```
* **Demonised**
```shfiles/scripts/lib.sh
docker run --name moodle -d moodlehq/moodle:master /scripts/init.php
or
./start-docker.sh --name='moodle' --moodlepath='/var/www/html/moodle'
```

> **Get ip for moodle instance via**
```
docker exec -ti moodle bash
or
docker logs moodle
or
docker logs -f moodle
```

> username/password is admin/moodle
> Access moodle instance with http://{docker container ip}/moodle

### 2. Run behat using docker image
```sh
docker run -t --rm -v /host/shared:/shared moodlehq/moodle:master /scripts/behat.sh
```
> /host/shared folder is on host machine which will contain behat output and faildump.

#### 2.a. Run specific run (2) run out of some (5) parallel runs.
```sh
docker run -t --rm -v /host/shared:/shared moodlehq/moodle:master /scripts/behat.sh -r2 -j5
```

#### 2.b. Run specific run (2) run out of some (5) parallel runs with chrome profile
```sh
docker run -t --rm -v /host/shared:/shared moodlehq/moodle:master /scripts/behat.sh -r2 -j5 --profile='firefox'
```

> for chrome profile, you should run docker with --privileged flag. 

**Following profiles are supported**
  * firefox / default
  * chrome
  * phantomjs
  * phantomjs-selenium

#### 2.c. Run specific run (2) run out of some (5) parallel runs with specif tags
```sh
docker run -t --rm -v /host/shared:/shared moodlehq/moodle:master /scripts/behat.sh -r2 -j5 --tags='@javascript'
```

#### 2.d. Run behat with specific feature name
```sh
docker run -t --rm -v /host/shared:/shared moodlehq/moodle:master /scripts/behat.sh -r2 -j5 --name="This is test"
```

### 3. Run php unit test
```sh
docker run -t --rm -v /host/shared:/shared moodlehq/moodle:master /scripts/phpunit.sh"
```

### Specify database and git branch with following options.
* --git=git://git.moodle.org/moodle.git
* --branch=MOODLE_30_STABLE
* --remote=stable
* --bdhost=mssql99.test
* --dbtype=mssql
* --dbuser=moodle
* --dppass=moodle

### You can use external selenium instances (To make them work have a copy of moodle at root level on host machine)
* --seleniumurl=test.local:4444
* --phantomjsurl=test.local:4443

## NOTE: Script options use getopt style.
**Option string for short options with arguments:**
* With required arguments like -a bahman or -Hreports
* With optional arguments like -abahman. Note that there can't be any spaces between the option (-a) and the argument (bahman).

**Option string for long options with arguments:**
* With required arguments like --file-to-process reports or --package-name-prefix='com.bahmanm'
* With optional arguments like --package-name-prefix='com.bahmanm'. Note that the argument can be passed only using =.

[official]: <https://hub.docker.com/u/moodlehq/>
[docker]: <https://www.docker.com/>
[Install docker binary]: <http://docs.docker.com/engine/installation/>
[Install docker Machine]: <http://docs.docker.com/machine/install-machine/>
[Install docker compose]: <http://docs.docker.com/compose/install/>