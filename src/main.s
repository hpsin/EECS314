	.globl main
main:
	# stick the resturn address on the stack
	addi $sp, $sp, -4
	sw $ra, 0($sp)

	li $v0, 4
	la $a0, splash_screen
	syscall

	# restore the resturn address and return
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
	nop

