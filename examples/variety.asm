; variety
; INPUT: Nothing
; OUTPUT: ???
; PURPOSE: Test a variety of instructions

lis $1
.word 65
lis $2
.word 0xffff000c
lis $3
.word 0xffff0004
lw $4, 0($3)
sub $5, $4, $1
mult $5, $5
mflo $6
add $1, $6, $1
sw $6, 0($2)
jr $31
