.DEFAULT_GOAL := help
.PHONY: setup up down shell test help lint analyse quality

SAIL := ./vendor/bin/sail

help: ## Show this help message
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n\nTargets:\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

setup: ## Copy .env, install dependencies via Docker, generate key and migrate
	cp .env.example .env
	docker run --rm \
		-u "$$(id -u):$$(id -g)" \
		-v "$$(pwd):/var/www/html" \
		-w /var/www/html \
		laravelsail/php83-composer:latest \
		composer install --ignore-platform-reqs
	$(SAIL) up -d
	$(SAIL) artisan key:generate
	$(SAIL) artisan migrate

up: ## Start Sail containers in background
	$(SAIL) up -d

down: ## Stop Sail containers
	$(SAIL) down

shell: ## Access Sail shell
	$(SAIL) shell

test: ## Run tests via Artisan
	$(SAIL) artisan test

lint: ## Run Laravel Pint to check code style
	$(SAIL) bin pint --test

analyse: ## Run PHPStan for static analysis
	$(SAIL) bin phpstan analyse

quality: lint analyse test ## Run lint, static analysis, and tests