# Moodle application with behat and phpunit.
![logo](https://moodle.org/theme/image.php/moodleorgcleaned_moodleorg/theme_moodleorgcleaned/1447866970/moodle-logo)

### Build docker image (If you don't use moodlehq/moodle application)
```sh
cd {PATH_TO_THIS_REPO}
docker build -t {username}/moodle:master \
    --build-arg GITREPOSITORY=git://git.moodle.org/integration.git \
    --build-arg GITREMOTE=integration \
    --build-arg GITBRANCH=master \
    .
```
> you can use --env-file=env.list rather then passing individual environment variable.

### Moodle web application
Run Moodle [official] application 
```sh
docker run -ti -v /host/shared:/shared moodlehq/moodle:master /scripts/init.php
```
> username/password is admin/moodle

Run your local moodle application.
```sh
docker run -ti -v /host/shared:/shared {username}/moodle:master /scripts/init.php
```
> Access moodle instance with http://{docker container ip}/moodle

### Run behat using docker image
```sh
docker run -t --rm -v /host/shared:/shared moodlehq/moodle:master /scripts/behat.sh
```
> /host/shared folder is on host machine which will contain behat output and faildump.

### Run specific run (2) run out of some (5) parallel runs.
```sh
docker run -t --rm -v /host/shared:/shared moodlehq/moodle:master /scripts/behat.sh -r2 -j5
```

### Run specific run (2) run out of some (5) parallel runs with chrome profile
```sh
docker run -t --rm -v /host/shared:/shared moodlehq/moodle:master /scripts/behat.sh -r2 -j5 --profie=chrome
```
**Following profiles are supported**
  * firefox / default
  * chrome
  * phantomjs
  * phantomjs-selenium

### Run specific run (2) run out of some (5) parallel runs with specif tags
```sh
docker run -t --rm -v /host/shared:/shared moodlehq/moodle:master /scripts/behat.sh -r2 -j5 --tags=@javascript
```

### Run behat with specific feature name
```sh
docker run -t --rm -v /host/shared:/shared moodlehq/moodle:master /scripts/behat.sh -r2 -j5 --name="This is test"
```

### Run php unit test
```sh
docker run -t --rm -v /host/shared:/shared moodlehq/moodle:master /scripts/phpunit.sh"
```

#### Specify database and git branch with following options.
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