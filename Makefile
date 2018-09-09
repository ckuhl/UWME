.DEFAULT_GOAL := help

MAIN=mips-vm.rkt


build: ## Build a standalone executable
	raco make ${MAIN}
	raco exe ${MAIN}

.PHONY: clean run help
clean: ## Remove temporary files
	rm -rf mips-vm
	rm -rf compiled/

run: ## Run program with stdin (while developing, is useful)
	racket -l errortrace -t ${MAIN} < test-files/a1p4.mips

help: ## Print this message
		@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

