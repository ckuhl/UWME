#lang racket/base

; word: definition of a word object

; TODO can I bind a contract to the struct at definition instead of at provision?
(provide (struct-out word)
         bytes->word ; convert a string of four bytes to a word
         word->bytes ; convert a word to a string of bytes
         integer->word ; convert an integer to a word
         word->integer ; convert a word to an integer
         format-word-binary ; format a word as a binary string
         format-word-hex ; format a word as a hex string

         ; debugging tools
         make-r-type-word)

(require racket/contract ; contracts
         racket/format ; format word as binary or hex
         "constants.rkt") ; magic numbers


(struct word (raw op rs rt rd shmt fn i addr)
  #:transparent)


(define/contract
  (bytes->word bstr)
  (bytes? . -> . word?)
  (define val (integer-bytes->integer bstr #f #t))
  (define signed-val (integer-bytes->integer bstr #t #t))
  (word
    (integer-bytes->integer bstr #f #t) ; raw
    (arithmetic-shift (bitwise-and opcode-mask    val) opcode-offset)    ; opcode
    (arithmetic-shift (bitwise-and rs-mask        val) rs-offset)        ; rs
    (arithmetic-shift (bitwise-and rt-mask        val) rt-offset)        ; rt
    (arithmetic-shift (bitwise-and rd-mask        val) rd-offset)        ; rd
    (arithmetic-shift (bitwise-and shamt-mask     val) shamt-offset)     ; shamt
    (arithmetic-shift (bitwise-and funct-mask     val) funct-offset)     ; funct
    (integer-bytes->integer (subbytes bstr 2 4) #t #t) ; immediate (signed)
    (arithmetic-shift (bitwise-and address-mask   val) address-offset))) ; addr

(define/contract
  (word->bytes w)
  (word? . -> . bytes?)
  (integer->integer-bytes (word-raw w) word-size #f #t))

(define/contract
  (integer->word n)
  (integer? . -> . word?)
  (bytes->word (integer->integer-bytes n word-size #f #t)))

(define/contract
  (word->integer w)
  (word? . -> . integer?)
  (word-raw w))

;; TODO there's a way to put this inside of the struct using #:method
(define/contract
  (format-word-binary w)
  (word? . -> . string?)
  (format "~a"
          (~r (word-raw w)
              #:sign #f
              #:base 2
              #:min-width 32
              #:pad-string "0")))

;; TODO there's a way to put this inside of the struct using #:method
(define/contract
  (format-word-hex w)
  (word? . -> . string?)
  (format "~a"
          (~r (word-raw w)
              #:sign #f
              #:base 16
              #:min-width 8
              #:pad-string "0")))

(define/contract
  (make-r-type-word rs rt rd funct)
  (exact-nonnegative-integer? exact-nonnegative-integer? exact-nonnegative-integer? exact-nonnegative-integer? . -> . word?)
  (integer->word
    (+
      (arithmetic-shift rs 21)
      (arithmetic-shift rt 16)
      (arithmetic-shift rd 11)
      funct)))
