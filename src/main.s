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

# this is the main function call
# it listens for keypresses and then
# updates the screen with them
# $t0 is a temp used for storing ascii char codes for comparison
# $t1 stores the start of the input string
# $t2 stores the character that was entered
read_command:
	la $t1, input_string # start of the input buffer

	# now loop reading characters until a newline is detected
read_command_loop:
	li $v0, 12 # wait for a new keypress
	syscall

	add $t2, $v0, $zero # store the character in the input string

	# check for backspace
	li $t0, 0x8
	bne $t2, $t0, append_char

# if a backspace was entered remove the last character
remove_char:
	addi $t1, $t1, -1 # 
	sb $zero, ($t1)
	j finish_str_update
	
append_char:	
	
	sb $t2, ($t1)
	addi $t1, $t1, 1
	sb $zero, ($t1) # terminate the string

finish_str_update:	
	# stick the resturn address on the stack
	addi $sp, $sp, -12
	sw $ra, -8($sp)
	sw $t1, -4($sp)
	sw $t2, 0($sp)

	la $a0, input_string
	add $a1, $t1, $zero
	jal refresh_screen

	# restore the resturn address and return
	lw $ra, -8($sp)
	lw $t1, -4($sp)
	lw $t2, 0($sp)
	addi $sp, $sp, 8

	# if this is a new line then clear the
	# string and restart
	li $t0, 0xA
	bne $t2, $t0, read_command_loop

	# parse the command
	la $a0, input_string
	jal parse_input
	
	j read_command
	jr $ra
	nop

# will redraw the screen
# a0 is the input string to print
# a1 is the end of the input string
refresh_screen:
	add $t2, $zero, $a0 # store the argument

	# insert a bunch of blank lines to clear the screen
	li $v0, 4
	la $a0, clear_screen
	syscall

	# print the $ sign
	li $v0, 4
	la $a0, input_prompt
	syscall

	# print what has been typed
	li $v0, 4
	add $a0, $t2, $zero
	syscall

	# print a new line
	li $v0, 11
	li $a0, 0xA
	syscall

	li $t0, 73
	li $v0, 11
	la $a0, 0xA
blank_line_loop:
	syscall # print a blank line
	addi $t0, $t0, -1
	bne $t0, $zero, blank_line_loop
	
	jr $ra

.data
input_string: .space 100 # 99 char string
