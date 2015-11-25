# Moodle application with behat and phpunit.
![logo](https://moodle.org/theme/image.php/moodleorgcleaned_moodleorg/theme_moodleorgcleaned/1447866970/moodle-logo)

## Initial setup
Initial setup needed on host machine.

### Step 1: Install [docker]
* [Install docker binary]

> Create a [docker group] to avoid using sudo while executing scripts.
> NOTE: You need to logout and login to  make group affective.

### Step 2: Docker image
* **Download [official] image**
```sh
    docker pull rajeshtaneja/php:5.4
    docker pull rajeshtaneja/php:5.5
    docker pull rajeshtaneja/php:5.6
    docker pull rajeshtaneja/php:7.0
    docker pull rajeshtaneja/selenium:2.53.0
```

> Above will be done via run.sh script automatically, depending on what options you pass.

### Step 3: Clone this project
* **Clone this project and execute following commands from within the cloned project.**

## Run application

### 1. Moodle web application
Run Moodle [official] application
* **Interactive**
### 1. Run behat using docker image
```sh
./run.sh --moodlepath=/var/www/html/m --execute=moodle --shareddir=/host/shared --user=moodle --phpversion=7.0
```
> /host/shared folder is on host machine which will contain behat faildump and moodledata.

#### 2.a. Run specific run (2) run out of some (4) parallel runs.
```sh
./run.sh --moodlepath=/var/www/html/m --execute=behat --shareddir=/host/shared --user=moodle --phpversion=7.0.4 --run=2 --totalruns=4
```

#### 2.b. Run specific run (2) run out of some (4) parallel runs with chrome profile
```sh
./run.sh --moodlepath=/var/www/html/m --execute=behat --shareddir=/host/shared --user=moodle --phpversion=7.0.4 --run=2 --totalruns=4 --profile=chrome
```

**Following profiles are supported**
  * firefox / default
  * chrome
  * phantomjs
  * phantomjs-selenium

#### 2.c. 4 parallel runs with specific tags
```sh
./run.sh --moodlepath=/var/www/html/m --execute=behat --shareddir=/host/shared --user=moodle --phpversion=7.0.4 --run=0 --totalruns=4 --tags='@javascript'
```

#### 2.d. Run behat with specific feature name
```sh
./run.sh --moodlepath=/var/www/html/m --execute=behat --shareddir=/host/shared --user=moodle --phpversion=7.0.4 --run=1 --totalruns=1 --name="This is test"
```

### 3. Run php unit test
```sh
./run.sh --moodlepath=/var/www/html/m --execute=phpunit --shareddir=/host/shared --user=moodle --phpversion=7.0.4
```

### You can use following database and git branch options:
* --git=git://git.moodle.org/moodle.git
* --branch=MOODLE_30_STABLE
* --remote=stable
* --dbhost=mssql.test.com
* --dbtype=mssql
* --dbuser=moodle
* --dppass=moodle

### You can use external selenium instances (To make them work have a copy of moodle at root level on host machine)
* --seleniumurl=test.local:4444
* --phantomjsurl=test.local:4443
* or use selenium docker image --selenium=selenium/standalone-chrome:2.53.0

## NOTE: Script options use getopt style.
**Option string for short options with arguments:**
* With required arguments like -a bahman or -Hreports
* With optional arguments like -abahman. Note that there can't be any spaces between the option (-a) and the argument (bahman).

**Option string for long options with arguments:**
* With required arguments like --file-to-process reports or --package-name-prefix='com.bahmanm'
* With optional arguments like --package-name-prefix='com.bahmanm'. Note that the argument can be passed only using =.

[official]: <https://hub.docker.com/u/moodlehq/>
[docker]: <https://www.docker.com/>
[docker group]: <https://docs.docker.com/v1.8/installation/ubuntulinux/#create-a-docker-group>
[Install docker binary]: <http://docs.docker.com/engine/installation/>
[Install docker Machine]: <http://docs.docker.com/machine/install-machine/>
[Install docker compose]: <http://docs.docker.com/compose/install/>