Symfony-Docker-Compose
=============

0. [Git Flow](#0-git-flow)
1. [Prerequisites](#1-prerequisites)
2. [Installation](#2-installation)
3. [Running the server](#3-running-the-server)
4. [Running Tests](#4-runing-Tests)
5. [Access the Database](#5-access-the-database)
6. [Others features from makefile executable](#6-others-features-from-makefile)
7. [Env variables](#7-env-variables)

## 0. Git Flow

| Branch | Role |
| ------------- | ------------- |
| master | Is the production releases branch |
| dev | Is the development branch |
| The pattern : 'feature/' (followed by the feature's name) | Is used to create features and then deploy them by merging on dev |
| The pattern : 'hotfix/' (followed by the hotfix name) | Is used to fix (one or more) bug(s) and then deploy it by merging on dev/master |
| The pattern : 'release/' (followed by the release's name) | Is used to release and test a version and then deploy it by merging on master |

## 1. Prerequisites

- [Open SSL](https://www.openssl.org/source/)
- [Docker CE](https://docs.docker.com/install/)
- [Docker Compose](https://docs.docker.com/compose/install/) >=1.24

## 2. Installation

###2.a Installing docker

Please install docker, then:

```bash
sudo usermod -a -G docker $USER
sudo chown $USER:$USER ~/.docker/config.json
```

and verify that you can do a `docker ps`

###2.b Cloning the repository

```bash
git clone --recurse-submodules https://github.com/loverg-c/symfony_docker_compose
```

_IF AND ONLY IF ou didnt cloned with `--recurse-submodules` option, you have to do those following command:

```bash
git submodule init
git submodule update
```

###2.c Installation and .env files

Run:
```bash
make install
```
It will generate you a `.env` file, YOU SHOULD verify it
You can see possible variable and explanation on [7. env variable section](#7-env-variables)

Then again:
```bash
make install
```
It will generate you a `src_backend/.env.local` file, YOU SHOULD verify it

Then again:
```bash
make install
```
It will generate you a `src_backend/config/jwt/` folder, now go to next step


###2.d Generate key for jwt

Run: 
```bash
openssl genrsa -out src_backend/config/jwt/private.pem -aes256 4096
```
_It will ask you a password, please keep it and write it in your `.env` file at **JWT_KEY=**_

Then run:
```bash
openssl rsa -pubout -in src_backend/config/jwt/private.pem -out src_backend/config/jwt/public.pem
```

###2.e Finally

Then finally run :
```bash
sudo chown $USER:docker -R ./
sudo chmod -R g+swr ./
make install
```
If you want a pgadmin server: please add this variable in .env before install
```bash
PG_ADMIN=1 
```

## 3. Running the server

When the project is already installed (after a reboot for example), to start it just do a :
```bash
make start
```

Then go to [http://localhost:8083](http://localhost:8083) to see the server homepage

_NB: 8083 is the **APACHE_PORT_OUTSIDE_DOCKER** variable in your `.env`_

## 4. Running Tests

You can run this :

```bash
make testAll
```

## 5. Access the Database with a PGAdmin

If you add pgadmin you can see your database on [http://localhost:8803](http://localhost:8803)

_NB: 8803 is the **DB_ADMIN_PORT** variable in your `.env`_

- Then
>
> Username : `default@email.com`
>
> Password : **DB_PASSWORD** in **.env** (default `SomePasswordTooChange`)
>

- Create a database server connection on PGAdmin.

On **General** tab :

>
> name: `pgdb`
>

On **Connection** tab :

>
> host: `postgis`
>
> port: 5432
>
> Maintenance database: `postgres`
>
> username: **DB_USERNAME** in **.env** (default `postgres`)
>
> password: **DB_PASSWORD** in **.env** (default `postgres`)
>


## 6. Others features from makefile

Those following line are just a non-exhaustive list of which env variable you can set, available on .env.dist

| Command name | Argument | Detail |
| ------------ | -------- | ------ |
buildProject            | None |                                    Alias for install + testAll
afterBuild              | None |                                    Remove and reinstall the vendors, destroy and recreate database, rebuild assets
update                  | None |                                    Update vendor, database, and rebuild assets
checkConfigFile         | None |                                    Check your config file
install                 | None |                                    Check config files, destroy, rebuild, start containers, and do afterbuild
start                   | None or container_name |                  Start the containers (only work when installed)
restart                 | None or container_name |                  Restart the containers (only work when started)
stop                    | None or container_name |                  Stop the containers (only work when started)
destroy                 | None or container_name |                  Destroy the containers
buildImage              | None or container_name |                  Build the containers
vendorInstall           | None |                                    Remove and reinstall the vendors
vendorUpdate            | None |                                    Remove and update the vendors
testAll                 | None |                                    Run tests suites
routesJSGenerate        | None |                                    Regenerate routes file for ajax call
reloadAssets            | None |                                    Rebuild assets
watchAssets             | None |                                    Watch assets
yarnAdd                 | package_name |                            Add a package (node_modules) to assets
reloadFixtures          | None |                                    Empty and reload fixtures
updateDB                | None |                                    Update the database
migrateDB               | None or migration_version |               Execute a migration to a specified version or the latest available version.
executeDB               | migration_version and migration_mode  |   Execute a single migration version up or down manually.
generateMigrationFile   | None  |                                   Generate a migration by comparing your current database to your mapping information.
resetDB                 | None |                                    Destroy, recreate and refilled the database
resetAdmin              | None |                                    Reset backoffice admin user
bash                    | None or container_name |                  Open a bash inside a container
help                    | None |                                    Outputs this help screen

## 7. Env Variables

Those following line are just a non-exhaustive list of which command you can do (displayed with `make`
, for more information please refer to the `Makefile`

| Variable Name| type | Detail |
| ------------ | -------- | ------ |
WITH_APACHE                 | 0 OR 1 |                  Install with apache container
WITH_DB                     | 0 OR 1 |                  Install with postgres container 
WITH_PGADMIN                | 0 OR 1 |                  Install with pgadmin container 
WITH_MERCURE                | 0 OR 1 |                  Install with mercure container 
WITH_RESET_DB               | 0 OR 1 |                  IF 1: on install will reset database, else will just execute update db
WITH_UPDATE_DB              | 0 OR 1 |                  IF 1: on install (and with RESET_DB=0) it will update db, else will do nothing
DOCKER_SUBNET               | IP/mask |                 Your docker sub network on your host
COMPOSE_PROJECT_NAME        | string |                  Your project name (for container name and apache)
COMPOSER_CACHE_PATH         | path |                    Your composer dir path, useful to not download vendor and use cache if enable
YARN_CACHE_PATH             | path |                    Your yarn cache path, useful to not download vendor and use cache if enable
PROJECT_PATH_OUTSIDE_DOCKER | path |                    Your src_backend path, default src_backend (useful for ntfs or for working with different path)
APP_ENV                     | dev OR prod OR qa |       Symfony env
JWT_PASSPHRASE              | string |                  Passphrase for your PROJECT_PATH_OUTSIDE_DOCKER/config/jwt/ private key
TOKEN_TIMEOUT               | int |                     JWT token timeout for client reconnection
DB_HOST                     | container_name OR URL |   Your database host url or your database container alias (if php is on same sub-network and linked to it)
DB_PORT                     | int |                     Your database port (if DB_HOST is a container alias, port INSIDE the container)
DB_VERSION                  | version |                 Your database version
DB_USERNAME                 | string |                  Your database username
DB_PASSWORD                 | string |                  Your database password
DB_NAME                     | string |                  Your database name
DB_PROTOCOLE                | string |                  Your database protocol
MERCURE_PUBLISH_HOST        | container_name OR URL |   Your mercure host url or your database container alias (if php is on same subnetwork and linked to it)
MERCURE_PUBLISH_PORT        | int |                     Your mercure port (if MERCURE_PUBLISH_HOST is a container alias, port INSIDE the container)
MERCURE_JWT_PASSPHRASE      | string |                  Your mercure password for creating token and allow access to topic
DB_PORT_OUTSIDE_DOCKER      | int |                     If you choose WITH_DB=1 => will expose your database container port to this value
APACHE_PORT_OUTSIDE_DOCKER  | int |                     If you choose WITH_APACHE=1 => will expose your apache container port to this value
PHP_PORT_OUTSIDE_DOCKER     | int |                     It will expose your php container port to this value
DB_ADMIN_PORT               | int |                     If you choose WITH_PGADMIN=1 => will expose your pgadmin container port to this value
MERCURE_PORT                | int |                     If you choose WITH_MERCURE=1 => will expose your mercure container port to this value
DOCKER_IP                   | ip |                      Ip to expose docker php port
