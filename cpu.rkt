#lang racket/base

; Operations: CPU operations on the registerfile and memory

(provide name-to-operation) ; decode opcode names to functions

(require racket/contract ; ->
         racket/format ; ~r

         "alu.rkt" ; name-to-function
         "constants.rkt" ; magic numbers
         "memory.rkt" ; memory
         "registerfile.rkt" ; registers
         "word.rkt") ; word

;; Constants
; next byte of stdin will be placed into LSB of dest register
(define mmio-read-address #xffff0004)

; if you sw here, the LSB will be written out
(define mmio-write-address #xFFFF000C)


;; Helpers
(define/contract
  (compute-offset-addr rf w)
  (registerfile? word? . -> . exact-integer?)
  (+ (registerfile-integer-ref rf (word-rs w) #f))
  (word-i w))

;; Look up opcode functions by their name
;; Hash of: Identifier -> ((word registerfile memoryfile) -> (list registerfile memoryfile))
(define name-to-operation
  (make-immutable-hash
    (list

      ;; R-type
      (cons
        'r-type
        (lambda (w rf mem)
          (apply (hash-ref
                   name-to-function
                   (hash-ref funct-to-name (word-fn w))
                   (lambda () (raise-user-error
                                'ALU
                                "given funct ~a does not exist"
                                (~r (word-fn w) #:sign #f #:base 2 #:min-width 6 #:pad-string "0"))))
                 (list w rf mem))))


      ;; lw :: $t = MEM [$s + i]
      (cons
        'lw
        (lambda (w rf mem)
          (define addr (compute-offset-addr rf w))
          (cond
            ; reading from MMIO
            [(equal? addr mmio-read-address)
             (list (registerfile-set rf (word-rt w) (bitwise-and (read-byte (current-input-port)) lsb-mask)) mem)]
            ; reading from memory
            [else
              (list (registerfile-set rf (word-rt w) (memory-ref mem addr)) mem)])))


      ;; sw :: MEM [$s + i] = $t
      (cons
        'sw
            (lambda (w rf mem)
              (define addr (compute-offset-addr rf w))
              (cond
                ; writing to MMIO
                [(equal? addr mmio-write-address)
                 (write-byte (registerfile-ref rf (word-rt w) (current-output-port)))
                 (list rf mem)]
                ; write to memory from register
                [else
                  (list rf (memory-set mem addr (registerfile-ref rf (word-rt w))))])))


      ;; beq :: if ($s == $t) pc += i * 4
      (cons
        'beq
        (lambda (w rf mem)
          (list
            (cond
              [(equal? (registerfile-ref rf (word-rs w))
                       (registerfile-ref rf (word-rt w)))
               (registerfile-integer-set
                 rf
                 'PC
                 (+ (registerfile-integer-ref rf 'PC #f) (* (word-i w) word-size))
                 #f)]
              [else rf])
            mem)))


      ;; bne :: if ($s != $t) pc += i * 4
      (cons
        'bne
        (lambda (w rf mem)
          (list
            (cond
              [(not (equal? (registerfile-ref rf (word-rs w))
                            (registerfile-ref rf (word-rt w))))
               (registerfile-integer-set
                 rf
                 'PC (+ (registerfile-integer-ref rf 'PC #f)
                        (* (word-i w) word-size))
                 #f)]
              [else rf])
            mem)))

      )))
