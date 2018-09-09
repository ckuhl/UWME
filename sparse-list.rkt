#lang racket
(provide make-sparse-list
	 sparse-list-ref
	 sparse-list-set
	 sparse-list?)

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
(define/contract
  (make-sparse-list k v)
  (exact-nonnegative-integer? any/c . -> . sparse-list?)
  (sparse-list k v (make-immutable-hash)))

;; Get element at index
(define/contract
  (sparse-list-ref lst pos)
  (sparse-list? exact-nonnegative-integer? . -> . any/c)
  (if (or
	(> pos (sparse-list-k lst))
	(< pos 0))
    (raise-user-error 'sparse-list "index ~a is outside of the bounds of the array" pos)
    #t)
  (hash-ref (sparse-list-_hash lst)
	    pos
	    (lambda () (sparse-list-default lst))))

;; Set element at index
(define/contract
  (sparse-list-set lst pos v)
  (sparse-list? exact-nonnegative-integer? any/c . -> . sparse-list?)
  (sparse-list (sparse-list-k lst)
	       (sparse-list-default lst)
	       (hash-set (sparse-list-_hash lst) pos v)))

