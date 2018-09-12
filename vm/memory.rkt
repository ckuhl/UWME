#lang racket

(require "constants.rkt") ; TODO eventually remove this in favour of command line options?

(provide make-memory
	 memory-ref
	 memory-set
	 memory?
	 initialize-memory)

;; internal sparse list representation
;; Num Num Hash -> memory
(struct memory (k default _hash)
  #:transparent
  #:guard (lambda (k v i name)
	    (cond
	      [(not (exact-nonnegative-integer? k))
	       (raise-user-error 'memory "list must have a positive length")]
	      [(not (any/c v))
	       (raise-user-error 'memory "Problem with keyvalue")]
	      [else (values k v i)])))

;; Create a new sparse list
(define/contract
  (make-memory k v)
  (exact-nonnegative-integer? any/c . -> . memory?)
  (memory k v (make-immutable-hash)))

;; Get element at index
(define/contract
  (memory-ref lst pos)
  (memory? exact-nonnegative-integer? . -> . any/c)
  (if (or
	(> pos (memory-k lst))
	(< pos 0))
    (raise-user-error 'memory "index ~a is outside of the bounds of the array" pos)
    #t)
  (if (not (zero? (remainder pos 4))) (raise-user-error 'memory "unaligned byte access at ~a" pos)#t)

  (hash-ref (memory-_hash lst)
	    pos
	    (lambda () (memory-default lst))))

;; Set element at index
(define/contract
  (memory-set lst pos v)
  (memory? exact-nonnegative-integer? any/c . -> . memory?)
  (memory (memory-k lst)
	       (memory-default lst)
	       (hash-set (memory-_hash lst) pos v)))


;; Initialize memory
(define/contract
  (initialize-memory payload
		     [memory (make-memory MEMORY-SIZE MEMORY-LOAD-OFFSET)]
		     [offset 0])
  ((bytes?) (memory? exact-nonnegative-integer?) . ->* . memory?)
  (cond
    [(zero? (bytes-length payload)) memory]
    [else (initialize-memory (subbytes payload 4)
			     (memory-set memory offset (subbytes payload 0 4))
			     (+ 4 offset))]))

