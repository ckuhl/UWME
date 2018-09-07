#lang racket
(provide (all-defined-out))

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


; opcodes ====================================================================
(define r-type #b000000)
(define     lw #b100011)
(define     sw #b101011)
(define    beq #b000100)
(define    bne #b000101)


; R-type funct codes =========================================================
(define   add #b100000)
(define   sub #b100001)
(define  mult #b011000)
(define multu #b011001)
(define   div #b011010)
(define  divu #b011011)
(define  mfhi #b010000)
(define  mflo #b010010)
(define   lis #b010100)
(define   slt #b101010)
(define  sltu #b101011)
(define    jr #b001000)
(define  jalr #b001001)

