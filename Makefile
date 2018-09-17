.DEFAULT_GOAL := help

BUILD=compiled
DIST=dist

MAIN=main
PROJECT=UWME
DEMO=example/variety.mips


build: ## Build a standalone program
	raco make ${MAIN}.rkt
	raco exe ${MAIN}.rkt
	raco distribute ${DIST} ${MAIN}
	mv ${DIST} ${MAIN}
	zip -r ${MAIN}.zip ${MAIN}

.PHONY: clean debug run help
clean: ## Remove temporary files
	rm -f ${MAIN}.zip

debug: ## Run a demonstration program with debugging enabled
	racket -l errortrace -u ${MAIN}.rkt --twoints ${DEMO}

run: ## Run a demonstration program
	racket ${MAIN}.rkt --twoints ${DEMO}

help: ## Print this help message
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| sort \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

