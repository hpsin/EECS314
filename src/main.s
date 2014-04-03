	.text
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

	jal read_command

	# restore the resturn address and return
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra
	nop

read_command:
	li $t0, 0xA
	la $t1, input_string # start of the input buffer

	# now loop reading characters until a newline is detected
read_command_loop:
	li $v0, 12
	syscall

	sb $v0, ($t1)
	addi $t1, $t1, 1
	
	bne $v0, $t0, read_command_loop

	# terminate string
	add $t2, $zero, $zero # null terminater
	sb $t2, ($t1)
	addi $t1, $t1, 1
	la $a0, input_string
	add $a1, $t1, $zero

	# stick the resturn address on the stack
	addi $sp, $sp, -4
	sw $ra, 0($sp)

	jal refresh_screen

	# restore the resturn address and return
	lw $ra, 0($sp)
	addi $sp, $sp, 4

	j read_command
	jr $ra
	nop

refresh_screen:
	add $t2, $zero, $a0

	li $v0, 4
	la $a0, clear_screen
	syscall
	
	li $v0, 4
	la $a0, input_prompt
	syscall

	li $v0, 4
	add $a0, $t2, $zero
	syscall

	li $v0, 11
	li $a0, 0xA
	syscall

	# figure out the number of blanks line needed
	# to redraw the screen
	addi $t0, $zero, 30
	addi $t1, $zero, 50
	sub $t2, $a1, $t2
	div $t2, $t1
	mflo $t1
	sub $t0, $t0, $t1
	li $v0, 11
	la $a0, 0xA
blank_line_loop:
	syscall
	addi $t0, $t0, -1
	bne $t0, $zero, blank_line_loop
	
	jr $ra

.data
input_string: .space 100 # 99 char string
