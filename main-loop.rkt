#lang racket/base

(provide (rename-out [main-loop start]))

(require "boot-vm.rkt" ; for vm structure

		 "bytes.rkt"

         "stage/fetch.rkt"
         "stage/decode.rkt"
         "stage/execute.rkt")

(define (main-loop machine [count 0])
	
  (define fetched (fetch   machine))
  (define decoded (decode  fetched))
  (define updated (execute decoded))

  (define pc (hash-ref (vm-rf machine) 'PC))
  (define new-pc (unsigned->word (+ 4 (bytes->unsigned pc))))

  (define new-machine (struct-copy vm machine
  	[rf (hash-set (vm-rf machine) 'PC new-pc)]))

  (main-loop (updated new-machine) (add1 count)))
