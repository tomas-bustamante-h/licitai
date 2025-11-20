#################################################################################
# GLOBALS                                                                       #
#################################################################################

PROJECT_NAME = licitai
PYTHON_VERSION = 3.11
PYTHON_INTERPRETER = python

#################################################################################
# COMMANDS                                                                      #
#################################################################################


## Install Python dependencies
.PHONY: requirements
requirements:
	poetry install
	



## Delete all compiled Python files
.PHONY: clean
clean:
	find . -type f -name "*.py[co]" -delete
	find . -type d -name "__pycache__" -delete


## Lint using ruff (use `make format` to do formatting)
.PHONY: lint
lint:
	poetry run ruff format --check
	poetry run ruff check

## Format source code with ruff
.PHONY: format
format:
	poetry run ruff check --fix
	poetry run ruff format



## Run tests
.PHONY: test
test:
	poetry run pytest tests
## Download Data from storage system
.PHONY: sync_data_down
sync_data_down:
	gsutil -m rsync -r gs://licitai-data-dev/data/ data/
	

## Upload Data to storage system
.PHONY: sync_data_up
sync_data_up:
	gsutil -m rsync -r data/ gs://licitai-data-dev/data/
	



## Set up Python interpreter environment
.PHONY: create_environment
create_environment:
	poetry env use $(PYTHON_VERSION)
	@echo ">>> Poetry environment created. Activate with: "
	@echo '$$(poetry env activate)'
	@echo ">>> Or run commands with:\npoetry run <command>"




#################################################################################
# PROJECT RULES                                                                 #
#################################################################################

## Ejecutar ingesta completa (full) usando Hydra
.PHONY: ingest
ingest:
	poetry run python licitai/etl/ingest.py etl.mode=full

## Entrenar baseline BM25 y loggear en MLflow
.PHONY: train-bm25
train-bm25:
	poetry run python licitai/models/train_bm25.py model=bm25

## Entrenar baseline MF (ALS / implicit)
.PHONY: train-mf
train-mf:
	poetry run python licitai/models/train_mf.py model=mf

## Entrenar ensemble BM25 + MF
.PHONY: train-ensemble
train-ensemble:
	poetry run python licitai/models/train_ensemble.py model=ensemble

## Ejecutar todos los hooks de pre-commit en todos los archivos
.PHONY: pre-commit
pre-commit:
	poetry run pre-commit run --all-files

## Renderizar la tesis en Quarto
.PHONY: tesis
tesis:
	poetry run quarto render docs/tesis.qmd

#################################################################################
# Self Documenting Commands                                                     #
#################################################################################

.DEFAULT_GOAL := help

define PRINT_HELP_PYSCRIPT
import re, sys; \
lines = '\n'.join([line for line in sys.stdin]); \
matches = re.findall(r'\n## (.*)\n[\s\S]+?\n([a-zA-Z_-]+):', lines); \
print('Available rules:\n'); \
print('\n'.join(['{:25}{}'.format(*reversed(match)) for match in matches]))
endef
export PRINT_HELP_PYSCRIPT

help:
	@$(PYTHON_INTERPRETER) -c "${PRINT_HELP_PYSCRIPT}" < $(MAKEFILE_LIST)
