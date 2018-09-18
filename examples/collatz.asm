;; collatz conjecture

init:
lis $11
.word 1
add $12, $11, $11 ; $12 = 2
add $13, $12, $11 ; $13 = 3

basecase:
beq $2, $11, end ; base case, $2 = 1

loop:
add $3, $3, $11 ; increment loop counter

; test if n is even, go to even / odd
div $2, $12 ; $HI = $2 % $12
mfhi $1 ; get remainder
beq $1, $11, odd ; if odd

even:
; if n is even, divide by 2
div $2, $12
mflo $2
bne $2, $11, loop ; if $2 isn't 1, loop again
beq $0, $0, end ; otherwise we're done!

odd:
; if n is odd, multiply by 3 and add 1
mult $2, $13
mflo $2
add $2, $2, $11
bne $2, $11, loop

; return if n is 1

end:
jr $31

