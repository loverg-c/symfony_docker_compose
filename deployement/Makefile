COMPOSE_FILE_PATH := -f docker-compose-prod.yml
DOCKER_EXEC_CMD=$(DOCKER_COMPOSE) exec
.DEFAULT_GOAL := help
SQL_MIGRATION_PATH := $(shell grep ^SQL_MIGRATION_PATH= ./.env | cut -d '=' -f 2-)
ARGUMENT=$(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS)) #split argument from make
EVAL := $(eval $(ARGUMENT):;@:) #split argument from make
DOCKER_COMPOSE=@docker-compose $(COMPOSE_FILE_PATH)
DB_NAME=$(shell grep ^DB_NAME= ./.env | cut -d '=' -f 2-)
SF_LOCAL_FILE=$(BACKSRC)/.env.local
## —— ComposedCommand 🚀 ———————————————————————————————————————————————————————————————

checkConfigFile: ## Check your config file
ifeq (,$(wildcard ./.env)) #if no .env
		@cp .env.dist .env
		@echo 'We have just generate a .env file for you'
		@echo 'Please configure this new .env'
		@exit 1;
endif
		@mkdir -p $(SQL_MIGRATION_PATH);

replaceDBName:
		@grep -q '^DB_NAME=' $(SF_LOCAL_FILE) && \
		sed -i 's/^DB_NAME.*/DB_NAME=$(DB_NAME)/' $(SF_LOCAL_FILE) || \
		sed -i '1 i\DB_NAME=$(DB_NAME)' $(SF_LOCAL_FILE)

install: checkConfigFile replaceDBName destroy buildImage start ## Check config files, destroy, rebuild, start containers, and do afterbuild

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

## —— Database 🏢 ———————————————————————————————————————————————————————————————

showDBVersion: replaceDBName ## Show last db version for migration
		$(DOCKER_EXEC_CMD) php ./bashrun.sh dbVersion

generateSqlMigration: replaceDBName ## Generate migration file in sql
		$(DOCKER_EXEC_CMD) php ./bashrun.sh generateSQLMigration up
		@echo "Le fichier \033[32mup.sql\033[0m a été généré dans le dossier: \033[32m$(SQL_MIGRATION_PATH)/\c"
		$(DOCKER_EXEC_CMD) php ./bashrun.sh dbVersion
		@echo "\033[0m"

generateSqlRevert: replaceDBName ## Generate revert migration file in sql to version in argument
ifeq  ($(strip $(ARGUMENT)),)
		$(error "Veuillez entrer une version cible")
else
		$(DOCKER_EXEC_CMD) php ./bashrun.sh generateSQLMigration down $(ARGUMENT)
		@echo "Le fichier \033[32mdown.sql\033[0m a été généré dans le dossier: \033[32m$(SQL_MIGRATION_PATH)/$(ARGUMENT)\033[0m"
endif

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
