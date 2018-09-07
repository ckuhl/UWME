#lang racket

(require "constants.rkt")

;; TODO: Structure of the program
; 0. Define necessary tools
; 1. Set up
; START LOOP
;     2. Fetch
;     3. Decode
;     4. Execute
; END LOOP
; 5. Tear down

(struct word-field (opcode rs rt rd shamt funct immediate address)
  #:transparent)

(define (split-word value)
  (word-field
     (bitwise-and opcode-mask value)
     (bitwise-and rs-mask value)
     (bitwise-and rt-mask value)
     (bitwise-and rd-mask value)
     (bitwise-and shamt-mask value)
     (bitwise-and funct-mask value)
     (bitwise-and funct-mask value)
     (bitwise-and address-mask value)
))

;; TODO
(printf "~a~n" (split-word #x00A71820))

