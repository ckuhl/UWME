#lang racket

; definition of a word object

; todo can i bind a strct contract to the struct?
(provide (contract-out [struct word ((raw integer?)
				     (op integer?)
				     (rs integer?)
				     (rt integer?)
				     (rd integer?)
				     (shmt integer?)
				     (fn integer?)
				     (i integer?)
				     (addr integer?))])
	 bytes->word
	 word->bytes
	 integer->word
	 word->integer)

(require "constants.rkt") ; magic numbers

(struct word (raw op rs rt rd shmt fn i addr)
  #:transparent)

(define/contract
  (bytes->word bstr)
  (bytes? . -> . word?)
  (printf "~b ~b~n"
	  (integer-bytes->integer bstr #f 4)
	  (bitwise-bit-field (integer-bytes->integer (bytes 0 0 #x08 #x14) #f) 26 32))
  (define val (integer-bytes->integer bstr #f))
  (word
    (integer-bytes->integer bstr #f 4) ; raw

    (arithmetic-shift (bitwise-and opcode-mask    val) opcode-offset)    ; opcode
    (arithmetic-shift (bitwise-and rs-mask        val) rs-offset)        ; rs
    (arithmetic-shift (bitwise-and rt-mask        val) rt-offset)        ; rt
    (arithmetic-shift (bitwise-and rd-mask        val) rd-offset)        ; rd
    (arithmetic-shift (bitwise-and shamt-mask     val) shamt-offset)     ; shamt
    (arithmetic-shift (bitwise-and funct-mask     val) funct-offset)     ; funct
    (arithmetic-shift (bitwise-and immediate-mask val) immediate-offset) ; immediate
    (arithmetic-shift (bitwise-and address-mask   val) address-offset))) ; addr


(define/contract
  (word->bytes w)
  (word? . -> . bytes?)
  (integer->integer-bytes (word-raw w)))

(define/contract
  (integer->word n)
  (integer? . -> . word?)
  (bytes->word (integer->integer-bytes n 4 #f)))

(define/contract
  (word->integer w)
  (word? . -> . integer?)
  (word-raw w))

