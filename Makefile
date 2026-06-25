.DEFAULT_GOAL := help
.PHONY: setup up down shell test help lint lint-test analyse quality

SAIL := ./vendor/bin/sail

help: ## Show this help message and available targets
	@printf "\033[33mUsage:\033[0m\n  make \033[32m<target>\033[0m\n\n\033[33mTargets:\033[0m\n"
	@awk 'BEGIN {FS = ":.*##"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[32m%-15s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

setup: ## Initialize the project (env, deps, containers, keys, and migrations)
	cp -n .env.example .env || true
	docker run --rm \
		-u "$$(id -u):$$(id -g)" \
		-v "$$(pwd):/var/www/html" \
		-w /var/www/html \
		laravelsail/php83-composer:latest \
		composer install --ignore-platform-reqs
	$(SAIL) up -d
	$(SAIL) artisan key:generate
	$(SAIL) artisan migrate

up: ## Start all Docker containers in detached mode
	$(SAIL) up -d

down: ## Stop and remove all Docker containers
	$(SAIL) down

shell: ## Open an interactive bash shell inside the application container
	$(SAIL) shell

test: ## Execute the automated test suite
	$(SAIL) artisan test

lint: ## Fix code style issues automatically using Laravel Pint
	$(SAIL) composer lint

lint-test: ## Check code style violations without applying fixes (dry-run)
	$(SAIL) composer lint:test

analyse: ## Perform static code analysis using PHPStan
	$(SAIL) composer analyse

quality: lint-test analyse test ## Run the full Quality Assurance suite (lint, analyse, test)