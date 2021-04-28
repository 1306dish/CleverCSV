# Makefile for easier installation and cleanup.
#
# Uses self-documenting macros from here:
# http://marmelab.com/blog/2016/02/29/auto-documented-makefile.html

SHELL := bash
.SHELLFLAGS := -eu -o pipefail -c
MAKEFLAGS += --no-builtin-rules

PACKAGE=clevercsv
DOC_DIR=./docs/
VENV_DIR=/tmp/clevercsv_venv/

.PHONY: help

.DEFAULT_GOAL := help

help:
	@grep -E '^[0-9a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) |\
		 awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m\
		 %s\n", $$1, $$2}'

################
# Installation #
################

.PHONY: inplace install

inplace:
	python setup.py build_ext -i

install: ## Install for the current user using the default python command
	python setup.py build_ext --inplace && \
		python setup.py install --user

################
# Distribution #
################

.PHONY: release dist

release: ## Make a release
	python make_release.py

dist: ## Make Python source distribution
	python setup.py sdist

###########
# Testing #
###########

.PHONY: test integration integration_partial

test: venv ## Run unit tests
	source $(VENV_DIR)/bin/activate && green -a -vv ./tests/test_unit

integration: venv ## Run integration tests
	source $(VENV_DIR)/bin/activate && python ./tests/test_integration/test_dialect_detection.py -v

integration_partial: venv ## Run partial integration tests
	source $(VENV_DIR)/bin/activate && python ./tests/test_integration/test_dialect_detection.py -v --partial


#################
# Documentation #
#################

.PHONY: docs doc

docs: doc
doc: venv ## Build documentation with Sphinx
	source $(VENV_DIR)/bin/activate && m2r README.md && mv README.rst $(DOC_DIR)
	source $(VENV_DIR)/bin/activate && m2r CHANGELOG.md && mv CHANGELOG.rst $(DOC_DIR)
	cd $(DOC_DIR) && \
		rm source/* && \
		source $(VENV_DIR)/bin/activate && \
		sphinx-apidoc -H 'CleverCSV API Documentation' -o source ../$(PACKAGE) && \
		touch source/AUTOGENERATED
	source $(VENV_DIR)/bin/activate && $(MAKE) -C $(DOC_DIR) html


#######################
# Virtual environment #
#######################

.PHONY: venv

venv: $(VENV_DIR)/bin/activate

$(VENV_DIR)/bin/activate:
	test -d $(VENV_DIR) || python -m venv $(VENV_DIR)
	source $(VENV_DIR)/bin/activate && pip install -e .[dev]
	touch $(VENV_DIR)/bin/activate

############
# Clean up #
############

.PHONY: clean

clean: ## Clean build dist and egg directories left after install
	rm -rf ./dist
	rm -rf ./build
	rm -rf ./$(PACKAGE).egg-info
	rm -rf ./cover
	rm -rf $(VENV_DIR)
	rm -f MANIFEST
	rm -f ./$(PACKAGE)/*.so
	rm -f ./*_valgrind.log*
	find . -type f -iname '*.pyc' -delete
	find . -type d -name '__pycache__' -empty -delete
