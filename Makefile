# Shell configuration
SHELL := bash
.SHELLFLAGS := -eu -o pipefail -c
MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules

# Override PWD so that it's always based on the location of the file
PWD := $(realpath $(dir $(abspath $(firstword $(MAKEFILE_LIST)))))

# Directories
WORKTREE_ROOT := $(shell git rev-parse --show-toplevel 2> /dev/null)
SRC_DIR := loan_gauge
TEST_DIR := tests
BUILD_DIR := build
DOCS_DIR := docs
DIST_DIR := dist
SCRIPT_DIR := scripts
COVERAGE_REPORT := htmlcov

# Variables
PROJECT_NAME := loan_gauge
POETRY_CMD := poetry
PRE_COMMIT_CMD := $(POETRY_CMD) run pre-commit

# Colors
YELLOW := \033[33m
GREEN := \033[32m
NC := \033[0m # No Color

# ========================
# HELP
# ========================
.DEFAULT_GOAL := help
.PHONY: help
help: ## Display this help screen
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "$(YELLOW)%-30s$(NC) %s\n", $$1, $$2}'

# ========================
# Project Install
# ========================
.PHONY: install
install: ## Install project using `poetry install` and set up pre-commit hooks
	@printf "Ensuring expected directories exist...\n"
	@mkdir -p ${SRC_DIR} ${TEST_DIR} ${SCRIPT_DIR}
	@printf "$(GREEN)Setting up the project environment and installing dependencies...$(NC)\n"
	@$(POETRY_CMD) install
	@printf "Installing type stubs for mypy\n"
	@$(POETRY_CMD) run mypy --install-types --non-interactive
	@printf "$(GREEN)Installing pre-commit hooks...$(NC)\n"
	@$(PRE_COMMIT_CMD) install && $(PRE_COMMIT_CMD) install -t pre-push && $(PRE_COMMIT_CMD) autoupdate
	@printf "$(GREEN)Running pre-commit for the first time...$(NC)\n"
	@$(PRE_COMMIT_CMD) run --all-files

# ========================
# Clean
# ========================
.PHONY: clean clean-docker clean-pybuild clean-test clean-venv uninstall
clean: clean-pybuild clean-test  ## Clean: Everything EXCEPT docker images
	@printf "$(GREEN)All temporary files cleaned.$(NC)\n"

clean-docker:
	@printf "$(GREEN)Removing all Docker containers and images for $(PROJECT_NAME)...$(NC)\n"
	@docker rm -f $$(docker ps -a -q --filter "label=project=$(PROJECT_NAME)") || true
	@docker rmi -f $$(docker images -a -q --filter "label=project=$(PROJECT_NAME)") || true
	@printf "$(GREEN)Remove all dangling images...$(NC)\n"
	@docker image prune -f

clean-pybuild:  ## Clean: Python temp files
	@printf "$(GREEN)Removing Python build artifacts...$(NC)\n"
	@rm -rf $(BUILD_DIR) $(DIST_DIR)
	@find "${PWD}" -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	@find "${PWD}" -type d -name "*.egg-info" -exec rm -rf {} + 2>/dev/null || true
	@find "${PWD}" -type f -name "*.pyc" -exec rm -f {} + 2>/dev/null || true

clean-test:  ## Clean: Test artifacts
	@printf "$(GREEN)Removing test artifacts...$(NC)\n"
	@rm -rf .pytest_cache $(COVERAGE_REPORT) .coverage .mypy_cache
	@$(POETRY_CMD) run coverage erase
	@$(POETRY_CMD) run ruff clean

uninstall: clean clean-docker  ## Uninstall: Clean everything INCLUDING docker images
	@printf "$(YELLOW)WARNING: This will reset everything to pre-installation state.$(NC)\n"
	@sleep 3

# ========================
# Linting and Formatting
# ========================
.PHONY: lint format check-docstrings check-lint check-type check-code check-pre-commit
check-code: format check-lint check-type  ## CI: Run all code checks (format, lint, & type checks)

lint:  ## CI: Lint code
	@printf "$(GREEN)Linting the code...$(NC)\n"
	@$(POETRY_CMD) run ruff check $(SRC_DIR) $(TEST_DIR)
	@printf "$(GREEN)Completed linting.$(NC)\n"

format:  ## CI: Format code
	@printf "$(GREEN)Formatting the code...$(NC)\n"
	@$(POETRY_CMD) run ruff format $(SRC_DIR) $(TEST_DIR) scripts
	@$(POETRY_CMD) run isort $(SRC_DIR) $(TEST_DIR) scripts
	@printf "$(GREEN)Completed formatting.$(NC)\n"

check-docstrings:  ## CI:  Check the project's Python docstrings for compliance with PEP 257
	@printf "$(GREEN)Checking docstrings for compliance with PEP 257...$(NC)\n"
	@pydocstyle $(SRC_DIR) $(TEST_DIR)
	@printf "$(GREEN)Completed docstring checks.$(NC)\n"

check-lint:  ## CI: Check code linting
	@printf "$(GREEN)Checking code linting...$(NC)\n"
	@$(POETRY_CMD) run ruff check $(SRC_DIR) $(TEST_DIR)
	@printf "$(GREEN)Completed lint checks.$(NC)\n"

check-type:  ## CI: Check code static typing
	@printf "$(GREEN)Checking types...$(NC)\n"
	@$(POETRY_CMD) run mypy $(SRC_DIR) $(TEST_DIR)
	@printf "$(GREEN)Completed type checks.$(NC)\n"

check-pre-commit:  ## CI: Run pre-commit checks on all files
	@printf "$(GREEN)Running pre-commit...$(NC)\n"
	@$(PRE_COMMIT_CMD) run --all-files

# ========================
# Unit Tests and Coverage
# ========================
.PHONY: unit-test coverage-html
unit-test:  ## Test: local unit tests
	@printf "$(GREEN)Running tests using pytest and coverage...$(NC)\n"
	@$(POETRY_CMD) run coverage run -m pytest $(TEST_DIR)

coverage-html:  ## Test: Generate HTML coverage report
	@printf "$(GREEN)Generating HTML coverage report...$(NC)\n"
	@$(POETRY_CMD) run coverage html -d $(COVERAGE_REPORT)
