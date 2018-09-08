#lang racket
(provide (contract-out [make-sparse-list make-sparse-list-contract]
		       [sparse-list-ref sparse-list-ref-contract]
		       [sparse-list-set sparse-list-set-contract]))

;; internal sparse list representation
;; Num Num Hash -> sparse-list

(struct sparse-list (k default _hash)
  #:transparent
  #:guard (lambda (k v i name)
	    (cond
	      [(not (exact-nonnegative-integer? k))
	       (raise-user-error 'sparse-list "list must have a positive length")]
	      [(not (any/c v))
	       (raise-user-error 'sparse-list "Problem with keyvalue")]
	      [else (values k v i)])))

;; Create a new sparse list
(define make-sparse-list-contract (exact-nonnegative-integer? any/c . -> . sparse-list?))
(define (make-sparse-list k v)
  (sparse-list k v (make-immutable-hash)))

;; Get element at index
(define sparse-list-ref-contract (sparse-list? exact-nonnegative-integer? . -> . any/c))
(define (sparse-list-ref lst pos)
  (if (or
	(> pos (sparse-list-k lst))
	(< pos 0))
    (raise-user-error 'sparse-list "index ~a is outside of the bounds of the array" pos)
    #t)
  (hash-ref (sparse-list-_hash lst)
	    pos
	    (lambda () (sparse-list-default lst))))

;; Set element at index
;; sparse-list Num (any?) -> sparse-list
(define sparse-list-set-contract (sparse-list? exact-nonnegative-integer? any/c . -> . sparse-list?))
(define (sparse-list-set lst pos v)
  (sparse-list (sparse-list-k lst)
	       (sparse-list-default lst)
	       (hash-set (sparse-list-_hash lst) pos v)))

