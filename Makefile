.DEFAULT_GOAL := help

BUILD_DIR=compiled
DIST_DIR=dist

MAIN=main
PROJECT=UWME
EXAMPLE_DIR=example
DEMO=${EXAMPLE_DIR}/fibonacci.mips


build: ## Build a standalone program
	raco make ${MAIN}.rkt
	raco exe ${MAIN}.rkt
	raco distribute ${DIST_DIR} ${MAIN}
	mv ${DIST_DIR} ${MAIN}
	zip -r ${MAIN}.zip ${MAIN}

.PHONY: clean debug run help
clean: ## Remove temporary files
	rm -f ${MAIN}.zip

debug: ## Run a demonstration program with debugging enabled
	echo "0 47" | racket -l errortrace -u ${MAIN}.rkt --twoints ${DEMO}

run: ## Run a demonstration program
	echo "0 47" | racket main.rkt --twoints ${DEMO}

help: ## Print this help message
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| sort \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

