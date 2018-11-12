.DEFAULT_GOAL := help

BUILD_DIR=compiled
DIST_DIR=dist

MAIN=initialize
PROJECT=functional-vm
EXAMPLE_DIR=examples
DEMO=${EXAMPLE_DIR}/collatz.mips


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
	# 47 is the largest fibonacci number that fits in a 32 bit integer
	echo "0 47" | racket -l errortrace -u ${MAIN}.rkt \
		--twoints \
		--more-info \
		--verbose \
		--show-binary \
		${DEMO}

demo: ## Run a series of demonstration programs
	# 77031 has the longest number of iterations of any number under 100K
	echo "0 77031" | racket ${MAIN}.rkt --twoints --more-info ${DEMO}

help: ## Print this help message
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| sort \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

