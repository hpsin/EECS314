	.ktext 0x80000180
	move $k0, $v0 # save $v0 value
	move $k1, $a0 # save $a0 value
	la $a0, trap_msg # address of string to print
	li $v0, 4 # print string
	syscall
	addi $v0, $zero, 0x8 # insert a backspace character
	move $a0, $k1 # restore $a0
	mfc0 $k0, $14 # Coprocessor 0 register $14 has address of trapping instruction
	addi $k0, $k0, 4 # add 4 to point to next instruction
	mtc0 $k0, $14 # store new address back into $14
	eret # error return	; set PC to value in $14
	.kdata
trap_msg:
	.asciiz "Trap generated"
