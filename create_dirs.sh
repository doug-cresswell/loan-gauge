#!/bin/bash

# Define project directory
PROJECT_DIR="loan-gauge"

# Create project directory structure
mkdir -p "${PROJECT_DIR}/app" "${PROJECT_DIR}/tests"

# Create Python files
touch "${PROJECT_DIR}/app/__init__.py"
touch "${PROJECT_DIR}/app/main.py"
touch "${PROJECT_DIR}/app/dashboard.py"
touch "${PROJECT_DIR}/tests/__init__.py"
touch "${PROJECT_DIR}/tests/test_dashboard.py"

# Create Dockerfile, Makefile, pyproject.toml, .pre-commit-config.yaml, and README.md
touch "${PROJECT_DIR}/Dockerfile"
touch "${PROJECT_DIR}/Makefile"
touch "${PROJECT_DIR}/pyproject.toml"
echo "repos:
-   repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.0.1  # Use the latest revision
    hooks:
    -   id: trailing-whitespace
    -   id: end-of-file-fixer
    -   id: check-yaml
    -   id: check-added-large-files" > "${PROJECT_DIR}/.pre-commit-config.yaml"
touch "${PROJECT_DIR}/README.md"

echo "Project directory and initial files created."
