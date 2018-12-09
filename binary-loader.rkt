#lang racket/base

;; Load words from a file

(provide file->hash)

(require racket/file ; file->bytes
         racket/list) ; empty


;; Convert a string of bytes into a list of 4-byte bytestrings
(define (chunk-bytes bstr)
  (cond
    [(zero? (bytes-length bstr)) empty]
    [else (cons (subbytes bstr 0 4)
                (chunk-bytes (subbytes bstr 4)))]))

;; Given a list of words, create a list of memory-index: word pairs
(define (words->index/word-pairs wl [offset 0])
  (cond
    [(empty? wl) empty]
    [else (cons (cons offset (first wl))
                (words->index/word-pairs (rest wl) (+ 4 offset)))]))

;; Given a file, load it into a hash of memory addresses and bstrs
(define (file->hash filename)
  (make-immutable-hash
    (words->index/word-pairs
      (chunk-bytes
        (file->bytes filename)))))
