#lang racket/base

(provide vm
	get-register
	set-register
	get-memory
	set-memory)


;; Wrapper for registers / memory / PC
(define-struct vm (rf mem) #:transparent)


;; get the value of [register] from [machine]
(define (get-register machine register)
	(hash-ref (vm-rf machine) register))


;; Set [register] to [value] and return updated [machine]
(define (set-register machine register value)
	(struct-copy
		vm machine
		[rf (hash-set (vm-rf machine) register value)]))


;; the the value at [address] in the [machine]'s memory
(define (get-memory machine address)
	(hash-ref (vm-mem machine) address))


;; set [address] in the [machine]'s memory to [value]
(define (set-memory machine address value)
(struct-copy
		vm machine
		[mem (hash-set (vm-mem machine) address value)]))
