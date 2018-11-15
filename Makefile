.DEFAULT_GOAL := help

MAIN=initialize
EXAMPLE_DIR=examples
COLLATZ=${EXAMPLE_DIR}/collatz.mips
FIBB=${EXAMPLE_DIR}/fibonacci.mips


.PHONY: clean debug run help
clean: ## Remove temporary files
	rm -rf compiled/

debug: ## Run a demonstration program with debugging enabled
	# 47 is the largest fibonacci number that fits in a 32 bit integer
	echo "0 47" | racket -l errortrace -u ${MAIN}.rkt \
		--twoints \
		--more-info \
		--verbose \
		--show-binary \
		${COLLATZ}

demo: ## Run a series of demonstration programs
	# 77031 has the longest number of iterations of any number under 100K
	echo "0 77031" | racket ${MAIN}.rkt --twoints --more-info ${COLLATZ}
	echo "0 47" | racket ${MAIN}.rkt --twoints --more-info ${FIBB}

help: ## Print this help message
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| sort \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

