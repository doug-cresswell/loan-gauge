# Shell configuration
SHELL := bash
.SHELLFLAGS := -eu -o pipefail -c
MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules

# Override PWD so that it's always based on the location of the file
PWD := $(realpath $(dir $(abspath $(firstword $(MAKEFILE_LIST)))))

# Directories
WORKTREE_ROOT := $(shell git rev-parse --show-toplevel 2> /dev/null)
SRC_DIR := app
TEST_DIR := tests
BUILD_DIR := build
DOCS_DIR := docs
DIST_DIR := dist
COVERAGE_REPORT := htmlcov

# Variables
PROJECT_NAME := app
# Python virtual environment
VENV := .venv
VENV_ACTIVATE := $(VENV)/bin/activate
PYTHON = $$(if [ -d ${PWD}/'.venv' ]; then echo ${PWD}/".venv/bin/python3"; else echo "python3"; fi)

# Coverage settings
COVERAGE := coverage



# ========================
# HELP
# ========================
.DEFAULT_GOAL := help
.PHONY: help
help: ## Display this help screen
	@grep -E '^[a-z.A-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'



# ========================
# Project Install
# ========================
.PHONY: install

install: ## Create venv and install project using `poetry install`
	@echo "Creating and activating the virtual environment..."
	$(PYTHON) -m venv $(VENV)
	@chmod -R +x .venv
	@echo "Activating the virtual environment..."
	@echo "Run 'deactivate' to exit the virtual environment."
	@echo "Setting up the virtual environment and installing dependencies"
	@poetry install
	@touch .venv # Ensure .venv modified date more recent than requirements to avoid accidental rebuilds.
	@echo "Installing pre-commit"
	@poetry run pre-commit install && poetry run pre-commit autoupdate
	@echo "Running pre-commit for the first time"
	@poetry run pre-commit run --all-files
	@echo '#!/bin/bash' > .git/hooks/pre-push
	@echo 'poetry run pre-commit run --all-files' >> .git/hooks/pre-push




# ========================
# Clean
# ========================
.PHONY: clean clean-docker clean-pybuild clean-test clean-venv uninstall

clean: clean-pybuild clean-test  ## Clean:  Everything EXCEPT docker images and venv
	@echo "All temporary files cleaned"


clean-docker:
	@echo "Removing all Docker containers for $(PROJECT_NAME)..."
	docker rm -f $$(docker ps -a -q --filter "label=project=$(PROJECT_NAME)") || true
	@echo "Removing all Docker images for $(PROJECT_NAME)..."
	docker rmi -f $$(docker images -a -q --filter "label=project=$(PROJECT_NAME)") || true
	@echo "Remove all dangling images"
	docker image prune -f


clean-pybuild:  ## Clean:  Python temp files
	@echo "Removing Python build artifacts"
	rm -rf $(BUILD_DIR) $(DIST_DIR)
	find "${PWD}" -type d -name "__pycache__" -exec rm -rf {} \; 2>/dev/null || true
	find "${PWD}" -type d -name "*.egg-info" -exec rm -rf {} \; 2>/dev/null || true
	find "${PWD}" -type f -name "*.pyc" -exec rm -f {} \; 2>/dev/null || true


clean-test:  ## Clean:  Test artefacts
	@echo "Removing test artefacts"
	rm -rf .pytest_cache $(COVERAGE_REPORT) .coverage .mypy_cache
	poetry run coverage erase
	poetry run ruff clean


clean-venv:  ## Clean:  Virtual environment
	@echo "Deleting virtual environment"
	rm -rf $(VENV)


uninstall:  ## Uninstall:  Clean everything INCLUDING docker images and venv
	@echo " Running uninstall - this will reset everything to pre-installation state"
	@echo "WARNING: `poetry.lock`, virtual environment (venv) & docker images will be DELETED"
	@sleep 3
	@make clean
	@make clean-docker
	@make clean-venv



# ========================
# Linting and Formatting
# ========================
.PHONY: lint format check-lint check-type check-code check-pre-commit
check-code: format check-lint check-type  ## CI: Run all code checks (check-lint, format & check-pre-commit)

lint:  ## CI:  Lint code
	@echo "Linting the code using ruff"
	poetry run ruff $(SRC_DIR) $(TEST_DIR)
	@echo "Completed linting"


format:  ## CI:  Format code
	@echo "Formatting the code using ruff and isort"
	poetry run ruff format $(SRC_DIR) $(TEST_DIR) scripts
	poetry run isort $(SRC_DIR) $(TEST_DIR) scripts
	@echo "Completed formatting"


check-lint:  ## CI: Check code static type checker
	@echo "Checking code linting"
	poetry run ruff check $(SRC_DIR) $(TEST_DIR)
	@echo "Completed lint checks"


check-type:  ## CI: Check code linting
	@echo "Checking types"
	poetry run mypy $(SRC_DIR) $(TEST_DIR)
	@echo "Completed type checks"


check-pre-commit:  ## CI: Run pre-commit checks on all files
	@echo "Running pre-commit"
	poetry run pre-commit run --all-files



# ========================
# Unit Tests and Coverage
# ========================
.PHONY: unit-test coverage-html

unit-test: 	 ## Test:  local unit tests
	@echo "Running tests using pytest and coverage"
	poetry run coverage run -m pytest $(TEST_DIR)


coverage-html:  ## Test:  Generate html coverage report
	@echo "Generating HTML coverage report"
	poetry run coverage html -d $(COVERAGE_REPORT)



# ========================
# Documentation Build
# ========================
# .PHONY: docs
# docs:  ## Build documentation with sphinx (to be deprecated in favour of mkdocs)
# 	@echo "Building documentation"
# cd $(DOCS_DIR) && make html



# ========================
# Docker commands
# ========================
.PHONY: docker-build docker-unit-test docker-check-code docker-run

# Docker arguments
DOCKER_IMAGE := $(PROJECT_NAME)
DOCKER_TAG_DEV := development
DOCKER_TAG_PROD := production
TARGET ?= $(DOCKER_TAG_DEV) ## Default to dev image build target
PROJECT_LABEL := project=$(PROJECT_NAME)

docker-all: docker-unit-test docker-check-code

docker-build:  ## Docker: Build image (set target like `make docker-build TARGET=development`)
	@echo "Building Docker image for $(TARGET)..."
	docker build --target $(TARGET) --label $(PROJECT_LABEL) -t $(DOCKER_IMAGE):$(TARGET) -f Dockerfile .


# Note: Avoid overwriting the container's .venv by mounting entire working directory
# Add more volumes as you need, e.g. docs for doctest / mkdocs
docker-unit-test: docker-build  ## Docker: Unit tests in docker development image
	@echo "Running unit tests in docker container..."
	docker run --rm \
	-v $(PWD)/$(PROJECT_NAME):/app/$(PROJECT_NAME) \
	-v $(PWD)/tests:/app/tests \
	-v $(PWD)/docs:/app/docs \
	--label $(PROJECT_LABEL) \
	$(DOCKER_IMAGE):$(DOCKER_TAG_DEV) make unit-test


docker-check-code: docker-build  ## Docker: Code checks in docker development image
	@echo "Checking code in docker container..."
	docker run --rm \
	-v $(PWD)/$(PROJECT_NAME):/app/$(PROJECT_NAME) \
	-v $(PWD)/tests:/app/tests \
	-v $(PWD)/docs:/app/docs \
	--label $(PROJECT_LABEL) \
	$(DOCKER_IMAGE):$(DOCKER_TAG_DEV) make check-code


docker-pre-commit-run:
	@echo "Setting docker-build TARGET to 'pre-commit'"
	export TARGET=pre-commit; \
	$(MAKE) docker-build
	# TODO: Add docker run to run pre-commit


docker-run: docker-build  ## Docker: Interactive terminal in docker development image
	@echo "Running interactive docker container..."
	@docker run --rm -it \
	-v $(PWD)/$(PROJECT_NAME):/app/$(PROJECT_NAME) \
	-v $(PWD)/tests:/app/tests \
	-v $(PWD)/docs:/app/docs \
	--label $(PROJECT_LABEL) \
	$(DOCKER_IMAGE):$(TARGET) /bin/bash
