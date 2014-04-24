	.text
	.globl main
main:
	# stick the resturn address on the stack
	addi $sp, $sp, -4
	sw $ra, 0($sp)

	la $t0, input_history
	li $t1, 0xA
	sb $t1, 0($t0)
	sw $t0, input_history_start
	addi $t0, $t0, 1
	sw $t0, input_history_end

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

	
	addi $sp, $sp, -8
	sw $ra, 4($sp)
	sw $t1, 0($sp)
	la $a0, input_string
	jal add_string_to_history
	lw $t1, 0($sp)
	lw $ra, 4($sp)
	addi $sp, $sp, 8
	
	# erase the newline character
	addi $t1, $t1, -1
	sb $zero 0($t1)

	# parse the command
	addi $sp, $sp, -4
	sw $ra, 0($sp)

	la $a0, input_string
	jal parse_input

	lw $ra, 0($sp)
	addi $sp, $sp, 4

	# check for an error
	li $t0, -1
	beq $a0, $t0, call_unknown

	addi $sp, $sp, -4
	sw $ra, 0($sp)

	li $t0, 1
	beq $a0, $t0, call_play_song
	li $t0, 2
	beq $a0, $t0, call_play_note
	li $t0, 3
	beq $a0, $t0, call_add_rest
	li $t0, 4
	beq $a0, $t0, call_add_note
	li $t0, 5
	beq $a0, $t0, call_cat
	li $t0, 6
	beq $a0, $t0, call_load
	li $t0, 7
	beq $a0, $t0, call_save
	li $t0, 8
	beq $a0, $t0, call_help
	j call_unknown

call_play_song:
	jal play_song
	j command_finished

call_play_note:
	add $a0, $zero, $a1
	add $a1, $zero, $a2
	add $a2, $zero, $a3
	lw $a3, a4
	jal play_note
	j command_finished

call_add_rest:
	add $a0, $zero, $a1
	jal add_rest
	j command_finished

call_add_note:
	add $a0, $zero, $a1
	add $a1, $zero, $a2
	add $a2, $zero, $a3
	lw $a3, a4
	jal add_note
	j command_finished

call_cat:
	jal cat
	j command_finished

call_load:
	la $a0, filename
	jal load_file
	j command_finished

call_save:
	la $a0, filename
	jal save_file
	j command_finished

call_help:
	jal help
	j command_finished

call_unknown:
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	la $a0, error_message
	jal print_string_with_history
	lw $ra, 0($sp)
	addi $sp, $sp, 4

	li $v0, 12
	syscall
	j command_finished

command_finished:
	
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	
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
	

	# print the input history
	#########################

	# check and see where circular buffer pointer is
	la $t0, input_history_start
	lw $t1, 0($t0)
	la $t0, input_history


	beq $t0, $t1, print_input_history_aligned

	li $v0, 4
	la $a0, input_history_start
	syscall

	li $v0, 4
	la $a0, input_history
	syscall
	j print_input_history_end
	
print_input_history_aligned:
	li $v0, 4
	la $a0, input_history
	syscall
	
print_input_history_end:

	li $v0, 11
	li $a0, 0xA
	syscall
	
	# print the $ sign
	li $v0, 4
	la $a0, input_prompt
	syscall

	# print current command
	li $v0, 4
	add $a0, $t2, $zero
	syscall

	# print a new line
	li $v0, 11
	li $a0, 0xA
	syscall

	li $v0, 11
	la $a0, 0xA
	syscall # print a blank line

	jr $ra

print_string_with_history:
	# print the string
	li $v0,  4
	syscall

add_string_to_history:	
	add $t0, $a0, $zero
	# get pointer to start of history
	la $t1, input_history_start
	lw $t1, 0($t1)
	# get pointer to end of history
	la $t2, input_history_end
	lw $t2, 0($t2)
	la $t3, input_history_size
	lw $t3, 0($t3)
	addi $t3, $t3, -1
	la $t4, input_history
	add $t3, $t3, $t4
	li $t7, 0xA

# while(*string_pos != '\0')
print_string_with_history_outer_loop:
	lb $t4, 0($t0)
	beq $t4, $zero, print_string_with_history_outer_loop_end

	# if(input_history_end == history_size -1)
	bne $t2, $t3, print_string_with_history_no_cycle1

	add $t2, $t1, $zero # cycle around
	
print_string_with_history_no_cycle1:

	# if(input_history_end == input_history_start)
	bne $t1, $t2, print_string_with_history_write_char

print_string_with_history_inner_loop:
	lb $t4, 0($t1)
	# while(*input_history_start != '\n')
	beq $t4, $t7, print_string_with_history_inner_loop_end

	# *input_history_start = '\0'
	sb $zero, 0($t1)
	# input_history_start++
	addi $t1, $t1, 1

	# if(input_history_start == history_size - 1)
	bne $t1, $t3, print_string_with_history_no_cycle2
	la $t1, input_history
	
print_string_with_history_no_cycle2:
	# if(input_history_start == input_history_end)
	beq $t1, $t3, print_string_with_history_inner_loop_end

	j print_string_with_history_inner_loop

print_string_with_history_inner_loop_end:
	# *input_history_start = '\0'
	sb $zero, 0($t1)
	# input_history_start++
	addi $t1, $t1, 1
	
print_string_with_history_write_char:	
	# *input_history_end = *string_pos
	lb $t4, 0($t0)
	sb $t4, 0($t2)
	addi $t0, $t0, 1 # string_pos++
	addi $t2, $t2, 1 # input_history_end++
	
	j print_string_with_history_outer_loop
print_string_with_history_outer_loop_end:

	# save the registers back to memory
	la $t4, input_history_start
	sw $t1, 0($t4)
	la $t4, input_history_end
	sw $t2, 0($t4)
	
	jr $ra
	

.data
input_string: .space 100 # 99 char string
input_history_size: .word 10000 # size of input history buffer
input_history: .space 10000 # 9999 char string
input_history_start: .word 0
input_history_end: .word 0
blank_string: .asciiz "\n"
error_message: .asciiz "ERROR: Unknown or malformed command\n [Press Enter]"
