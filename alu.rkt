#lang racket/base

; ALU: Mathematical actions on the registerfile

(provide name-to-function) ; decode opcode names to functions

(require racket/format ; ~r

         "constants.rkt" ; magic numbers
         "memory.rkt" ; memory
         "registerfile.rkt" ; registers
         "word.rkt") ; word


; global configuration
(define show-binary (make-parameter #f))


;; Look up ALU functions by their name
;; Hash of: Identifier -> ((word registerfile memoryfile) -> (list registerfile memoryfile))
(define name-to-function
  (make-immutable-hash
    (list

      ; add :: $d = $s + $t
      (cons
        'add
        (lambda (w rf mem)
          (list
            (registerfile-integer-set
              rf
              (word-rd w)
              (+ (registerfile-integer-ref rf (word-rs w) #t)
                 (registerfile-integer-ref rf (word-rt w) #t))
              #t)
            mem)))


      ; sub :: $d = $s - $t
      (cons
        'sub
        (lambda
          (w rf mem)
          (list
            (registerfile-integer-set
              rf
              (word-rd w)
              (- (registerfile-integer-ref rf (word-rs w) #t)
                 (registerfile-integer-ref rf (word-rt w) #t))
              #t)
            mem)))


      ;; mult :: $HI:$LO = $rs * $rd
      (cons
        'mult
        (lambda (w rf mem)
          (define s (registerfile-integer-ref rf (word-rs w) #t))
          (define t (registerfile-integer-ref rf (word-rt w) #t))
          (list
            (registerfile-integer-set-swap
              rf
              #t
              'HI
              (arithmetic-shift (bitwise-and (* s t) hi-result-mask) ; mask off LO
                                (- (* word-size 8))) ; Shift to fit word
              'LO
              (bitwise-and (* s t) lo-result-mask))
            mem)))


      ;; multu :: $HI:$LO = $rs * $rt
      (cons
        'multu
        (lambda (w rf mem)
          (define s (registerfile-integer-ref rf (word-rs w) #f))
          (define t (registerfile-integer-ref rf (word-rt w) #f))
          (list
            (registerfile-integer-set-swap
              rf
              #t
              'HI (arithmetic-shift (bitwise-and (* s t) hi-result-mask) (- (* word-size 8)))
              'LO (bitwise-and (* s t) lo-result-mask))
            mem)))


      ;; div :: $LO = $s / $t, $HI = $s % $t
      (cons
        'div
        (lambda (w rf mem)
          (define s (registerfile-integer-ref rf (word-rs w) #t))
          (define t (registerfile-integer-ref rf (word-rt w) #t))
          (when (zero? t) (raise-user-error "CPU error: Division by zero"))
          (list
            (registerfile-integer-set-swap
              rf
              #f
              'HI (remainder s t)
              'LO (quotient s t))
            mem)))


      ;; divu :: $LO = $s / $t, $HI = $s % $t
      (cons
        'divu
        (lambda (w rf mem)
          (define s (registerfile-integer-ref rf (word-rs w) #f))
          (define t (registerfile-integer-ref rf (word-rt w) #f))
          (when (zero? t) (raise-user-error "CPU error: Division by zero"))
          (list
            (registerfile-integer-set
              rf #f
              'HI (remainder s t)
              'LO (quotient s t))
            mem)))


      ;; mfhi :: $d = $HI
      (cons
        'mfhi
        (lambda (w rf mem)
          (list (registerfile-set rf (word-rd w) (registerfile-ref rf 'HI)) mem)))


      ;; mflo :: $d = $LO
      (cons
        'mflo
        (lambda (w rf mem)
          (list (registerfile-set rf (word-rd w) (registerfile-ref rf 'LO)) mem)))


      ;; lis :: d = MEM[pc]; pc += 4
      (cons
        'lis
        (lambda (w rf mem)
          (define new-rf
            (registerfile-set-swap
              rf
              (word-rd w) (memory-ref
                            mem
                            (integer-bytes->integer (registerfile-ref rf 'PC) #f #t))
              'PC (integer->integer-bytes
                    (+ word-size
                       (registerfile-integer-ref rf 'PC #f))
                    word-size
                    #f
                    #t)))

          (when (show-binary)
            (printf "~a: ~a~n"
                    (format-word-hex (bytes->word (registerfile-ref new-rf 'PC)))
                    (format-word-binary (bytes->word (registerfile-ref new-rf (word-rd w))))))

          (list new-rf mem)))


      ;; slt :: $d = 1 if $s < $t; 0 otherwise
      (cons
        'slt
        (lambda (w rf mem)
          (define s (registerfile-integer-ref rf (word-rs w) #t))
          (define t (registerfile-integer-ref rf (word-rt w) #t))
          (list
            (registerfile-integer-set (word-rd w) (if (< s t) 1 0) #f)
            mem)))


      ;; sltu :: $d = 1 if $s < $t; 0 otherwise
      (cons
        'sltu
        (lambda (w rf mem)
          (define s (registerfile-integer-ref rf (word-rs w) #f))
          (define t (registerfile-integer-ref rf (word-rt w) #f))
          (list
            (registerfile-integer-set rf (word-rd w) (if (< s t) 1 0) #f)
            mem)))


      ;; jr :: pc = $s
      (cons
        'jr
        (lambda (w rf mem)
          (when (not (zero? (word-rt w)))
            (raise-user-error 'jr "$rt is expected to be zero for opcode jr"))

          (when (not (zero? (word-rd w)))
            (raise-user-error 'jr "$rd is expected to be zero for opcode jr"))

          (list
            (registerfile-set rf 'PC (registerfile-ref rf (word-rs w)))
            mem)))


      ;; jalr :: temp = $s; $31 = pc; $PC = temp
      (cons
        'jalr
        (lambda (w rf mem)
          (list
            (registerfile-set-swap
              rf
              (word-rs w) (registerfile-ref rf 'PC)
              'PC (registerfile-ref rf (word-rs w)))
            mem)))

      )))
