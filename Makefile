.DEFAULT_GOAL := help

BUILD_DIR=compiled
DIST_DIR=dist

MAIN=main
PROJECT=UWME
EXAMPLE_DIR=examples
DEMO=${EXAMPLE_DIR}/fibonacci.mips


build: ## Build a standalone program
	raco make ${MAIN}.rkt
	raco exe ${MAIN}.rkt
	raco distribute ${DIST_DIR} ${MAIN}
	mv ${DIST_DIR} ${MAIN}
	zip -r ${MAIN}.zip ${MAIN}

.PHONY: clean debug run demo help
clean: ## Remove temporary files
	rm -f ${MAIN}.zip

debug: ## Run a demonstration program with debugging enabled
	# 47 is the largest fibonacci number that fits in a 32 bit integer
	echo "0 47" | racket -l errortrace -u ${MAIN}.rkt --twoints ${DEMO}

demo: ## Run a series of demonstration programs
	echo "0 47" | racket main.rkt --twoints --more-info examples/fibonacci.mips
	# 77031 has the longest number of iterations of any number under 100K
	echo "0 77031" | racket main.rkt --twoints --more-info examples/collatz.mips
	# 47 is the largest fibonacci number that fits in a 32 bit integer
	echo "0 47" | racket -l errortrace -u main.rkt --twoints --more-info examples/fibonacci.mips
	# 77031 has the longest number of iterations of any number under 100K
	echo "0 77031" | racket -l errortrace -u main.rkt --twoints --more-info examples/collatz.mips

run: ## Run a demonstration program
	echo "0 47" | racket main.rkt --twoints ${DEMO}

help: ## Print this help message
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| sort \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

