	.globl main
main:
	# stick the resturn address on the stack
	addi $sp, $sp, -4
	sw $ra, 0($sp)

	li $v0, 4
	la $a0, splash_screen
	syscall

	li $v0, 12
	syscall

	li $v0, 4
	la $a0, clear_screen
	syscall

	la $a0, test_str
	li $a1, 10
	jal refresh_screen

	# restore the resturn address and return
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
	nop

refresh_screen:
	add $t0, $zero, $a0
	
	li $v0, 4
	la $a0, input_prompt
	syscall

	li $v0, 4
	add $a0, $t0, $zero
	syscall

	li $v0, 11
	li $a0, 0xA
	syscall

	# figure out the number of blanks line needed
	# to redraw the screen
	addi $t0, $zero, 30
	addi $t1, $zero, 50
	div $a1, $t1
	mflo $t1
	sub $t0, $t0, $t1
	li $v0, 11
	la $a0, 0xA
blank_line_loop:
	syscall
	addi $t0, $t0, -1
	bne $t0, $zero, blank_line_loop
	
	jr $ra