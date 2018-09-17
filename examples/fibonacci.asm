; fibonacci (loop)
; INPUT: n, stored in $2
; OUTPUT: the nth fibonacci number, stored in $3
constants:
lis $10
.word 1

init:
add $11, $0, $10
beq $2, $0, end ; if n = 0, return F_0
beq $2, $11, end ; if n = 1, return F_1
sub $2, $2, $10 ; n -= 1

loop:
add $3, $11, $12 ;  set $r = F_0 + F_1
add $11, $0, $12 ; set F_0 = F_1
add $12, $0, $3 ; set F_1 = $r
sub $2, $2, $10 ; n -= 1
bne $2, $0, loop

end:
jr $31
