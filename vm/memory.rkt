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

;; Create a memory object
; k: size
; v: default value
(define/contract
  (make-memory k v)
  (exact-nonnegative-integer? bytes? . -> . memory?)
  (memory k v (make-immutable-hash)))

;; Get element at index
(define/contract
  (memory-ref mem key)
  (memory? exact-nonnegative-integer? . -> . bytes?)
  ;; additional constraints
  ;; TODO can these be moved into the contract?
  (when (> key (memory-k mem))
    (raise-user-error 'memory "index ~a is outside of the bounds of the array" key))
  (unless (zero? (remainder key 4))) (raise-user-error 'memory "unaligned byte access at ~a" key)

  (hash-ref (memory-_hash mem)
	    key
	    (lambda () (memory-default mem))))

;; Utility function to get and convert in one step
(define/contract
  (memory-integer-ref mem key signed)
  (memory? exact-nonnegative-integer? boolean? . -> . exact-integer?)
  (integer-bytes->integer (memory-ref mem key) word-size signed))

;; Set element at index
(define/contract
  (memory-set mem key v)
  (memory? exact-nonnegative-integer? bytes? . -> . memory?)
  (memory (memory-k mem)
	  (memory-default mem)
	  (hash-set (memory-_hash mem) key v)))

(define/contract
(memory-integer-set mem key v)
(memory? exact-nonnegative-integer? integer? . -> . memory?)
(memory-set mem key (integer->integer-bytes v word-size #f)))

;; Initialize memory
(define/contract
  (initialize-memory payload
		     [memory (make-memory MEMORY-SIZE MEMORY-LOAD-OFFSET)]
		     [offset 0])
  ((bytes?) (memory? exact-nonnegative-integer?) . ->* . memory?)
  (cond
    [(zero? (bytes-length payload)) memory]
    [else (initialize-memory
	    (subbytes payload word-size)
	    (memory-set memory offset (subbytes payload 0 word-size))
	    (+ word-size offset))]))

