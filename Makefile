PROJECT_PATH_OUTSIDE_DOCKER := $(shell grep ^PROJECT_PATH_OUTSIDE_DOCKER= ./.env | cut -d '=' -f 2-)
IS_ROOT    := $(if $(patsubst /%,,$(PROJECT_PATH_OUTSIDE_DOCKER)),,yes)
IS_HOME    := $(if $(patsubst ~%,,$(PROJECT_PATH_OUTSIDE_DOCKER)),,yes)
IS_NETWORK := $(if $(patsubst \\\\%,,$(PROJECT_PATH_OUTSIDE_DOCKER)),,yes)
IS_DRIVE   := $(foreach d,A B C D E...Z,$(if $(patsubst $(d):/%,,$(PROJECT_PATH_OUTSIDE_DOCKER)),,yes))

ifeq ($(strip $(IS_ROOT)$(IS_HOME)$(IS_NETWORK)$(IS_DRIVE)),yes)
BACKSRC := $(PROJECT_PATH_OUTSIDE_DOCKER)
else
BACKSRC := $(PWD)/$(PROJECT_PATH_OUTSIDE_DOCKER)
endif

WITH_PGADMIN=$(shell grep ^WITH_PGADMIN ./.env | cut -d '=' -f 2-)
WITH_APACHE=$(shell grep ^WITH_APACHE ./.env | cut -d '=' -f 2-)
WITH_DB=$(shell grep ^WITH_DB ./.env | cut -d '=' -f 2-)
WITH_MERCURE=$(shell grep ^WITH_MERCURE ./.env | cut -d '=' -f 2-)
WITH_RESET_DB=$(shell grep ^WITH_RESET_DB ./.env | cut -d '=' -f 2-)
WITH_UPDATE_DB=$(shell grep ^WITH_UPDATE_DB ./.env | cut -d '=' -f 2-)

COMPOSE_FILE_PATH := -f docker-compose.yml
ifeq ($(WITH_PGADMIN), 1)
COMPOSE_FILE_PATH := $(COMPOSE_FILE_PATH) -f docker-compose-pgadmin.yml
endif
ifeq ($(WITH_APACHE), 1)
COMPOSE_FILE_PATH := $(COMPOSE_FILE_PATH) -f docker-compose-apache.yml
endif
ifeq ($(WITH_DB), 1)
COMPOSE_FILE_PATH := $(COMPOSE_FILE_PATH) -f docker-compose-db.yml
endif
ifeq ($(WITH_MERCURE), 1)
COMPOSE_FILE_PATH := $(COMPOSE_FILE_PATH) -f docker-compose-mercure.yml
endif

PROJECT_NAME=$(shell grep ^COMPOSE_PROJECT_NAME ./.env | cut -d '=' -f 2-)
DB_NAME=$(shell grep ^DB_NAME= ./.env | cut -d '=' -f 2-)
DB_USER=$(shell grep ^DB_USERNAME= ./.env | cut -d '=' -f 2-)
APP_ENV=$(shell grep ^APP_ENV= ./.env | cut -d '=' -f 2-)
YARN_CONTAINER_NAME= $(PROJECT_NAME)_yarn
ENCORE_COMMAND="./node_modules/.bin/encore dev"
FRONT_MAIN_DIR=/usr/src/app
DOCKER_EXEC_CMD=$(DOCKER_COMPOSE) exec
.DEFAULT_GOAL := help
ARGUMENT=$(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS)) #split argument from make
EVAL := $(eval $(ARGUMENT):;@:) #split argument from make
CURRENT_UID=$(shell id -u):$(shell id -g)
export HOST_UID=$(shell id -u)
export HOST_USER=$(shell whoami)
export HOST_GROUP=$(shell getent group docker | cut -d: -f3)
DOCKER_COMPOSE=@docker-compose $(COMPOSE_FILE_PATH)
SF_LOCAL_FILE=$(BACKSRC)/.env.local

## —— ComposedCommand 🚀 ———————————————————————————————————————————————————————————————
buildProject: install test ## Alias for install + test

afterBuild: vendorInstall resetDB reloadAssets ## Remove and reinstall the vendors, destroy and recreate database, rebuild assets

update: vendorUpdate updateDB reloadAssets ## Update vendor, database, and rebuild assets


checkConfigFile: ## Check your config file
ifeq (,$(wildcard ./.env)) #if no .env
		@cp .env.dist .env
		@echo 'We have just generate a .env file for you'
		@echo 'Please configure this new .env'
		@exit 1;
else ifeq (,$(wildcard $(SF_LOCAL_FILE))) #if no $(BACKSRC)/.env.local
		@cp $(BACKSRC)/.env.local.dist $(SF_LOCAL_FILE)
		@echo 'We have just generate a $(SF_LOCAL_FILE) file for you'
		@echo 'Please configure this new $(SF_LOCAL_FILE)'
		@exit 1;
else ifeq (,$(wildcard $(BACKSRC)/config/jwt/public.pem)) #if no $(BACKSRC)/config/jwt/public.pem
	    @mkdir -p $(BACKSRC)/config/jwt
		@echo 'We have just generate a $(BACKSRC)/config/jwt folder for you\\n'
		@echo 'Please refer to the \"###2.d Generate key for jwt\" section in the README.md'
		@exit 1;
endif

install: checkConfigFile replaceDBName destroy buildImage start afterBuild ## Check config files, destroy, rebuild, start containers, and do afterbuild

replaceDBName:
		@grep -q '^DB_NAME=' $(SF_LOCAL_FILE) && \
		sed -i 's/^DB_NAME.*/DB_NAME=$(DB_NAME)/' $(SF_LOCAL_FILE) || \
		sed -i '1 i\DB_NAME=$(DB_NAME)' $(SF_LOCAL_FILE)

## —— Docker 🐳 ———————————————————————————————————————————————————————————————

start: replaceDBName ## Start the containers (only work when installed)
	   $(DOCKER_COMPOSE) up -d $(ARGUMENT)

restart: replaceDBName ## Restart the containers (only work when started)
		 $(DOCKER_COMPOSE) restart $(ARGUMENT)

stop: ## Stop the containers (only work when started)
		$(DOCKER_COMPOSE) stop $(ARGUMENT)

destroy: ## Destroy the containers
		$(DOCKER_COMPOSE) stop $(ARGUMENT)
		$(DOCKER_COMPOSE) rm -f $(ARGUMENT)

buildImage: ## Build the containers
		$(DOCKER_COMPOSE) build $(ARGUMENT)

## —— Vendors 🧙‍️ ———————————————————————————————————————————————————————————————

vendorInstall: ## Remove and reinstall the vendors
		$(DOCKER_EXEC_CMD) php ./bashrun.sh vendorInstall

vendorUpdate: ## Remove and update the vendors
		$(DOCKER_EXEC_CMD) php ./bashrun.sh vendorUpdate

## —— Tests ✅  ———————————————————————————————————————————————————————————————

testAll:
		$(DOCKER_EXEC_CMD) php ./bashrun.sh testAll

## —— Front 🎨 ———————————————————————————————————————————————————————————————

routesJSGenerate: ## Regenerate routes file for ajax call
		$(DOCKER_EXEC_CMD) php ./bashrun.sh routesJSGenerate

runYarnCommand:
		@docker-compose -f docker-compose-yarn.yml run --no-deps -u $(HOST_UID) --rm yarn /bin/bash -c $(YARN_CMD)

yarnInstall: ## Reinstall node_modules
		@docker-compose -f docker-compose-yarn.yml build
		@docker-compose -f docker-compose-yarn.yml run --no-deps -u $(HOST_UID) --rm yarn /bin/bash -c "yarn install --check-files"


reloadAssets:	YARN_CMD = $(ENCORE_COMMAND) ## Rebuild assets
watchAssets:	YARN_CMD = $(ENCORE_COMMAND) --watch ## Watch assets
yarnAdd:		YARN_CMD = yarn add $(ARGUMENT) ## Add a package (node_modules) to assets
yarnAdd reloadAssets watchAssets: yarnInstall routesJSGenerate runYarnCommand

## —— Database 🏢 ———————————————————————————————————————————————————————————————

reloadFixtures: replaceDBName ## Reload the fixtures
ifeq ($(APP_ENV), dev)## Empty and reload fixtures
		$(DOCKER_EXEC_CMD) php ./bashrun.sh reloadFixtures
endif

updateDB: replaceDBName ## Update the database
ifeq ($(WITH_UPDATE_DB), 1)
		$(DOCKER_EXEC_CMD) php ./bashrun.sh updateDB
endif

migrateDB: replaceDBName ## Execute a migration to a specified version or the latest available version.
ifeq ($(WITH_UPDATE_DB), 1)
		$(DOCKER_EXEC_CMD) php ./bashrun.sh migrateDB $(ARGUMENT)
endif

executeDB: replaceDBName ## Execute a single migration version up or down manually, Example make executeDB 20200406202523 down.
ifeq ($(WITH_UPDATE_DB), 1)
	$(DOCKER_EXEC_CMD) php ./bashrun.sh executeDB $(ARGUMENT)
endif

generateMigrationFile: replaceDBName ## Generate a migration by comparing your current database to your mapping information.
ifeq ($(APP_ENV), dev)
		$(DOCKER_EXEC_CMD) php ./bashrun.sh generateMigrationFile
endif

destroyDB: replaceDBName
	$(DOCKER_EXEC_CMD) php ./bashrun.sh destroyCreateDB

dbReset: replaceDBName
	$(DOCKER_EXEC_CMD) php ./bashrun.sh resetDB

ifeq ($(WITH_RESET_DB), 1)
resetDB: destroyDB dbReset reloadFixtures resetAdmin ## Reset everything in database
else
resetDB: updateDB
endif

resetAdmin: replaceDBName ## Reset backoffice admin user
		$(DOCKER_EXEC_CMD) php ./bashrun.sh resetAdmin

## —— Usefull 🧐 ———————————————————————————————————————————————————————————————

bash: ## Open a bash inside a container
ifneq ($(strip $(ARGUMENT)),)
		$(DOCKER_EXEC_CMD) $(ARGUMENT) /bin/bash
else
		@echo Usage: make bash {container}
		@exit 1
endif

help: ## Outputs this help screen
		@grep -E '(^[a-zA-Z0-9_-]+:.*?##.*$$)|(^##)' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}{printf "\033[32m%-30s\033[0m %s\n", $$1, $$2}' | sed -e 's/\[32m##/[33m/'
		@echo ""
		@echo "In case you want to build with pgadmin, just change \033[32mWITH_PGADMIN=1\033[0m in .env"
		@echo "Make sure you are in the docker groups, give the repo's right to this group (read and write)"
		@echo ""
