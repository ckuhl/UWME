#lang racket/base

; word: definition of a word object

; TODO can I bind a contract to the struct at definition instead of at provision?
(provide (struct-out word)
         bytes->word ; convert a string of four bytes to a word
         word->binary-string ; format a word as a binary string
         word->hex-string ; format a word as a hex string

         bytes->signed
         bytes->unsigned
         signed->bytes
         unsigned->bytes)

(require racket/contract ; contracts
         racket/format ; format word as binary or hex

         "constants.rkt")


; CONSTANTS ==================================================================
; Removed from constants.rkt because they're only used here

; Bit masks ==================================================================
;    bit 31                                 bit 0
;         |                                     |
;         v   6     5     5     5     5      6  v
;         +------+-----+-----+-----+-----+------+
; R-type  |opcode|  Rs |  Rt |  Rd |shamt| funct|
;         +------+-----+-----+-----+-----+------+
;
;             6     5     5           16
;         +------+-----+-----+------------------+
; I-type  |opcode|  Rs |  Rt |     immediate    |
;         +------+-----+-----+------------------+
;
;            6                 26
;         +------+------------------------------+
; J-type  |opcode|            address           |
;         +------+------------------------------+

;; R, J, and I-type fields
(define    opcode-mask #b11111100000000000000000000000000)

;; R and I-type fields
(define        rs-mask #b00000011111000000000000000000000)
(define        rt-mask #b00000000000111110000000000000000)

;; R-type fields
(define        rd-mask #b00000000000000001111100000000000)
(define     shamt-mask #b00000000000000000000011111000000)
(define     funct-mask #b00000000000000000000000000111111)

;; I-type fields
(define immediate-mask #b00000000000000001111111111111111)

;; J-type
(define   address-mask #b00000011111111111111111111111111)


; Offsets ====================================================================
; (from rightmost bit)
(define opcode-offset -26)
(define rs-offset -21)
(define rt-offset -16)
(define rd-offset -11)
(define shamt-offset -6)
(define funct-offset 0)
(define immediate-offset 0)
(define address-offset 0)


;; Byte conversion helpers
(define (bytes->signed b)
  (integer-bytes->integer b #t #t))

(define (bytes->unsigned b)
  (integer-bytes->integer b #f #t))

(define (signed->bytes n)
  (integer->integer-bytes n word-size #t #t))

(define (unsigned->bytes n)
  (integer->integer-bytes n word-size #f #t))


(struct word (raw op rs rt rd shmt fn i addr)
  #:transparent)


(define/contract
  (bytes->word bstr)
  (bytes? . -> . word?)
  (define val (bytes->unsigned bstr))
  (define signed-val (bytes->signed bstr))
  (word
    val ; raw value
    (arithmetic-shift (bitwise-and opcode-mask val) opcode-offset)
    (arithmetic-shift (bitwise-and rs-mask val) rs-offset)
    (arithmetic-shift (bitwise-and rt-mask val) rt-offset)
    (arithmetic-shift (bitwise-and rd-mask val) rd-offset)
    (arithmetic-shift (bitwise-and shamt-mask val) shamt-offset)
    (arithmetic-shift (bitwise-and funct-mask val) funct-offset)
    (bytes->signed (subbytes bstr 2 4)) ; immediate
    (arithmetic-shift (bitwise-and address-mask val) address-offset)))


(define/contract
  (word->binary-string w)
  (word? . -> . string?)
  (format "~a"
          (~r (word-raw w)
              #:sign #f
              #:base 2
              #:min-width 32
              #:pad-string "0")))


(define/contract
  (word->hex-string w)
  (word? . -> . string?)
  (format "~a"
          (~r (word-raw w)
              #:sign #f
              #:base 16
              #:min-width 8
              #:pad-string "0")))
