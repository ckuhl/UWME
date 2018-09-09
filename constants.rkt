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

;; Other
(define hi-result-mask #b11111111111111111111111111111111000000000000000000000000000000000)
(define lo-result-mask #b00000000000000000000000000000000111111111111111111111111111111111)
(define       lsb-mask #x00000000000000000000000011111111)

; Offsets ====================================================================
(define opcode-offset -26)
(define rs-offset -21)
(define rt-offset -16)
(define rd-offset -11)
(define shamt-offset -6)
(define funct-offset 0)
(define immediate-offset 0)
(define address-offset 0)



; opcodes ====================================================================
(define r-type-opcode #b000000)
(define     lw-opcode #b100011)
(define     sw-opcode #b101011)
(define    beq-opcode #b000100)
(define    bne-opcode #b000101)


; R-type funct codes =========================================================
(define   add-funct #b100000)
(define   sub-funct #b100001)
(define  mult-funct #b011000)
(define multu-funct #b011001)
(define   div-funct #b011010)
(define  divu-funct #b011011)
(define  mfhi-funct #b010000)
(define  mflo-funct #b010010)
(define   lis-funct #b010100)
(define   slt-funct #b101010)
(define  sltu-funct #b101011)
(define    jr-funct #b001000)
(define  jalr-funct #b001001)


;; Special addresses ============================================================
(define return-address #x8123456c)

; next byte of stdin will be placed into LSB of dest register
(define     mmio-read-address #xffff0004)

; if you sw here, the LSB will be written out
(define    mmio-write-address #xFFFF000C)

; TODO find way to optionally override default values
(define stack-pointer  #x01000000)
(define MEMORY-SIZE #x01000000)
(define MEMORY-LOAD-OFFSET #x00000000)

;; Magic values
; size of word in bytes
(define word-size 4)

