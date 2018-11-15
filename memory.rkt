#lang racket/base

(require "constants.rkt")

(provide make-memory ; create empty memory object
         memory-ref ; get the value of an index of memory
         memory-set ; set the value of an index of memory
         memory? ; predicate
         initialize-memory ; initialize memory with a binary payload
         memory-end-of-program ; get the ending point of the binary payload
         memory-set-pairs) ; set a series of memory address as a list of key-value pairs

(require racket/contract
         "word.rkt")


;; Constants
(define MEMORY-SIZE #x01000000)
(define MEMORY-LOAD-OFFSET #x00000000)


;; internal sparse list representation
;; Num Num Hash -> memory
(struct memory (k default _program-end _hash)
  #:transparent
  #:guard (lambda (k v p i name)
            (cond
              [(not (exact-nonnegative-integer? k))
               (raise-user-error 'memory "list must have a positive length")]
              [(not (exact-nonnegative-integer? k))
               (raise-user-error 'memory "key must be an exact nonnegative integer")]
              [(not (bytes? v))
               (raise-user-error 'memory "value must of type bytes")]
              [else (values k v p i)])))

;; Create a memory object
; k: size
; v: default value
(define/contract
  (make-memory k v)
  (exact-nonnegative-integer? bytes? . -> . memory?)
  (memory k v 0 (make-immutable-hash)))

;; Get element at index
(define/contract
  (memory-ref mem key)
  (memory? exact-nonnegative-integer? . -> . bytes?)
  ;; additional constraints
  ;; TODO can these be moved into the contract?
  (when (> key (memory-k mem))
    (raise-user-error 'memory "index ~a is outside the bounds of memory" key))
  (unless (zero? (remainder key 4)) (raise-user-error 'memory "unaligned byte access at ~a" key))

  (hash-ref (memory-_hash mem)
            key
            (lambda () (memory-default mem))))

;; Set element at index
(define/contract
  (memory-set mem key v)
  (memory? exact-nonnegative-integer? bytes? . -> . memory?)
  (memory (memory-k mem)
          (memory-default mem)
          (memory-_program-end mem)
          (hash-set (memory-_hash mem) key v)))

; set a series of memory indices at once
(define/contract
  (memory-set-pairs mem kvps)
  (memory? (listof (cons/c exact-nonnegative-integer? bytes?)) . -> . memory?)
  (for/fold ([m mem])
    ([p kvps])
    (memory-set m (car p) (cdr p))))


;; Initialize memory
; load four byte chunks (i.e. words) into each point
(define/contract
  (initialize-memory payload
                     [mem (make-memory MEMORY-SIZE (bytes 0 0 0 0))]
                     [offset MEMORY-LOAD-OFFSET])
  ((bytes?) (memory? exact-nonnegative-integer?) . ->* . memory?)
  (cond
    [(zero? (bytes-length payload)) mem]
    [else (initialize-memory
            (subbytes payload word-size)
            ; custom-set memory to increment the program ending point
            (memory (memory-k mem)
                    (memory-default mem)
                    (+ (memory-_program-end mem) word-size)
                    (hash-set (memory-_hash mem)
                              offset
                              (subbytes payload 0 word-size)))
            (+ word-size offset))]))

; provide the index of the last instruction of the program
(define/contract
  (memory-end-of-program mem)
  (memory? . -> . exact-nonnegative-integer?)
  (memory-_program-end mem))

