MAIN=mips-vm.rkt
make:
	raco make ${MAIN}
	raco exe ${MAIN}

.PHONY: clean

clean:
	rm -rf mips-vm
	rm -rf compiled/

