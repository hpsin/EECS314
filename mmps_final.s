# src/main.s

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
	la $a0, input_prompt
	jal add_string_to_history
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
# src/strings.s

	.data
splash_screen:	 .asciiz "\n\n                                           |\\\n                      __  __ __  __ ____   | |\n                     |  \\/  |  \\/  |  _ \\  |/\n                     | |\\/| | |\\/| | |_) |/|_ \n                     | |  | | |  | |  __///| \\\n                     |_|  |_|_|  |_|_|  | \\|_ |\n                                         \\_|_/\n                                           |\n                                          @'\n             _______________________________________________________\n            |:::::: o o o o . |..... . .. . | [45]  o o o o o ::::::|\n            |:::::: o o o o   | ..  . ..... |       o o o o o ::::::|\n            |::::::___________|__..._...__._|_________________::::::|\n            | # # | # # # | # # | # # # | # # | # # # | # # | # # # |\n            | # # | # # # | # # | # # # | # # | # # # | # # | # # # |\n            | # # | # # # | # # | # # # | # # | # # # | # # | # # # |\n            | | | | | | | | | | | | | | | | | | | | | | | | | | | | |\n            |_|_|_|_|_|_|_|_|_|_|_|_|_|_|_|_|_|_|_|_|_|_|_|_|_|_|_|_|\n\n\n\nHirsch Singhal			Sam Castelaz			David Jannotta		\nRob Meyer		  	         Devin Schwab                        Diego Waxemberg\n\n\n                               [Press Enter to continue]\n"

clear_screen:	.asciiz "\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n"

input_prompt:	.asciiz "$ "

# src/backspace_handler.s

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
# src/parser.s

	.text
	.globl parse_input
# this method takes in
# $a0 start of input string
# and returns
# $a0 command code
# $a1 parsed arg1
# $a2 parsed arg2
# $a3 parsed arg3
# additional arguments are stored in memory a4, and a5

# command codes are as follows
# play song = 1
# play note = 2
# add rest = 3
# add note = 4
# cat = 5
# load = 6
# save = 7
# help = 8
# unknown = -1
parse_input:
	lb $t0, 0($a0) # get the first character
	add $t2, $a0, $zero

	li $t1, 0x61 # see if first char is an 'a'
	beq $t0, $t1, parse_add
	li $t1, 0x70 # see if first char is a 'p'
	beq $t0, $t1, parse_play
	li $t1, 0x63 # see if first char is a 'c'
	beq $t0, $t1, parse_cat
	li $t1, 0x6c # see if first char is an 'l'
	beq $t0, $t1, parse_load
	li $t1, 0x73 # see if first char is an 's'
	beq $t0, $t1, parse_save
	li $t1, 0x68 # see if first char is an 'h'
	beq $t0, $t1, parse_help

	j parse_unknown

parse_add:
	# load second character
	addi $t2, $t2, 1
	lb $t0, 0($t2)
	
	# see if second character is a d
	li $t1, 0x64
	bne $t0, $t1, parse_unknown

	#load the third character
	addi $t2, $t2, 1
	lb $t0, 0($t2)

	# see if third character is a d
	bne $t0, $t1, parse_unknown

	# load the fourth character
	addi $t2, $t2, 1
	lb $t0, 0($t2)

	# see if fourth character is a space
	li $t1, 0x20
	bne $t0, $t1, parse_unknown

	# parse the next set of characters to an integer
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	addi $a0, $t2, 1
	jal str_to_int

	lw $ra, 0($sp)
	addi $sp, $sp, 4

	# error occured while converting
	bne $a1, $zero, parse_unknown

	add $t2, $zero, $a2
	
	# see if the last character parsed was string
	# or a null character
	lb $t0, 0($t2)
	bne $t0, $zero, parse_add_note

	# set the arguments and return
	add $a1, $a0, $zero
	addi $a0, $zero, 3
	jr $ra

parse_add_note:

	# get the next character
	addi $t2, $t2, 1

	addi $sp, $sp, -8
	sw $a0, 4($sp)
	sw $ra, 0($sp)

	# parse the velocity
	add $a0, $zero, $t2
	jal parse_velocity

	lw $ra, 0($sp)
	addi $sp, $sp, 4

	# make sure a valid velocity was entered
	li $t0, -1
	bne $t0, $a0, parse_add_note_arg3

	# pop the stack and jump to parse_unknown
	addi $sp, $sp, 4
	j parse_unknown
	
parse_add_note_arg3:
	# store the velocity on the stack
	addi $sp, $sp, -8
	sw $a0, 4($sp)
	sw $ra, 0($sp)

	# convert the third argument
	addi $a0, $a1, 1
	jal str_to_int

	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	# make sure no errors occurred
	beq $a1, $zero, parse_add_note_arg4

	# pop the stock and jump to parse_unknown
	addi $sp, $sp, 8
	j parse_unknown
	
parse_add_note_arg4:
	# store the duration on the stack
	addi $sp, $sp, -8
	sw $a0, 4($sp)
	sw $ra, 0($sp)

	# convert the fourth argument
	addi $a0, $a2, 1
	jal str_to_int

	lw $ra, 0($sp)
	addi $sp, $sp, 4

	# make sure no errors occurred
	beq $a1, $zero, parse_add_note_end

	# pop the stack and jump to parse_unknown
	addi $sp, $sp, 12
	j parse_unknown
	
parse_add_note_end:	

	sw $a0, a4
	addi $a0, $zero, 4
	lw $a1, 8($sp)
	lw $a2, 4($sp)
	lw $a3, 0($sp)
	addi $sp, $sp, 12
	jr $ra

parse_play:
	# load second character
	addi $t2, $t2, 1
	lb $t0, 0($t2)

	# check if second character is an l
	li $t1, 0x6c
	bne $t0, $t1, parse_unknown

	# load third character
	addi $t2, $t2, 1
	lb $t0, 0($t2)

	# check if second character is an a
	li $t1, 0x61
	bne $t0, $t1, parse_unknown

	# load fourth character
	addi $t2, $t2, 1
	lb $t0, 0($t2)

	# check if fourth character is a y
	li $t1, 0x79
	bne $t0, $t1, parse_unknown

	# load fifth character
	addi $t2, $t2, 1
	lb $t0, 0($t2)

	# check if fifth character is a null
	beq $t0, $zero, parse_play_song

	# parse play note args
	addi $sp, $sp, -4
	sw $ra 0($sp)

	addi $a0, $t2, 1
	jal str_to_int

	lw $ra, 0($sp)
	addi $sp, $sp, 4

	# an error occurred while converted
	bne $a1, $zero, parse_unknown

	addi $sp, $sp, -8
	sw $a0, 4($sp)
	sw $ra, 0($sp)

	# parse the velocity
	addi $a0, $a2, 1
	jal parse_velocity

	lw $ra, 0($sp)
	addi $sp, $sp, 4

	# make sure a valid velocity was entered
	li $t0, -1
	bne $t0, $a0, parse_play_note_arg3

	# pop the stack and jump to parse_unknownb
	addi $sp, $sp, 4
	j parse_unknown
	
parse_play_note_arg3:	
	# store the velocity on the stack
	addi $sp, $sp -8
	sw $a0, 4($sp)
	sw $ra, 0($sp)

	# convert the third argument
	addi $a0, $a1, 1
	jal str_to_int

	lw $ra, 0($sp)
	addi $sp, $sp, 4

	# make sure no errors occurred
	beq $a1, $zero, parse_play_note_arg4

	# pop the stack and jump to parse unknown
	addi $sp, $sp, 8
	j parse_unknown

parse_play_note_arg4:
	# store the duration on the stack
	addi $sp, $sp, -8
	sw $a0, 4($sp)
	sw $ra, 0($sp)

	# convert the fourth argument
	addi $a0, $a2, 1
	jal str_to_int

	lw $ra, 0($sp)
	addi $sp, $sp, 4

	# make sure no errors occurred
	beq $a1, $zero, parse_play_note_end

	# pop the stack and jump to parse_unknown
	addi $sp, $sp, 12
	j parse_unknown
	
parse_play_note_end:	

	sw $a0, a4
	addi $a0, $zero, 2
	lw $a1, 8($sp)
	lw $a2, 4($sp)
	lw $a3, 0($sp)
	addi $sp, $sp, 12
	jr $ra
	
parse_play_song:	
	addi $a0, $zero, 1
	jr $ra

parse_cat:
	# load second character
	addi $t2, $t2, 1
	lb $t0, 0($t2)

	# check if second character is an a
	li $t1, 0x61
	bne $t0, $t1, parse_unknown

	# load third character
	addi $t2, $t2, 1
	lb $t0, 0($t2)

	# check if third character is a t
	li $t1, 0x74
	bne $t0, $t1, parse_unknown

	# load fourth character
	addi $t2, $t2, 1
	lb $t0, 0($t2)

	# check if fourth character is a null
	bne $t0, $zero, parse_unknown

	addi $a0, $zero, 5
	add $a1, $zero, $zero
	jr $ra

parse_load:
	# load second character
	addi $t2, $t2, 1
	lb $t0, 0($t2)

	# check if second character is an o
	li $t1, 0x6F
	bne $t0, $t1, parse_unknown

	# load third character
	addi $t2, $t2, 1
	lb $t0, 0($t2)

	# check if third character is an a
	li $t1, 0x61
	bne $t0, $t1, parse_unknown

	# load fourth character
	addi $t2, $t2, 1
	lb $t0, 0($t2)

	# check if fourth character is a d
	li $t1, 0x64
	bne $t0, $t1, parse_unknown

	# load fifth character
	addi $t2, $t2, 1
	lb $t0, 0($t2)

	# check if fifth character is a space
	li $t1, 0x20
	bne $t0, $t1, parse_unknown

	# extract the filename string
	addi $sp, $sp, -4
	sw $ra, 0($sp)

	add $a0, $t2, 1
	la $a1, filename
	jal str_copy

	lw $ra, 0($sp)
	addi $sp, $sp, 4

	addi $a0, $zero, 6
	add $a1, $zero, $zero
	jr $ra

parse_save:
	# load second character
	addi $t2, $t2, 1
	lb $t0, 0($t2)

	# check if second character is an a
	li $t1, 0x61
	bne $t0, $t1, parse_unknown

	# load third character
	addi $t2, $t2, 1
	lb $t0, 0($t2)

	# check if third character is an v
	li $t1, 0x76
	bne $t0, $t1, parse_unknown

	# load fourth character
	addi $t2, $t2, 1
	lb $t0, 0($t2)

	# check if fourth character is a e
	li $t1, 0x65
	bne $t0, $t1, parse_unknown

	# load fifth character
	addi $t2, $t2, 1
	lb $t0, 0($t2)

	# check if fifth character is a space
	li $t1, 0x20
	bne $t0, $t1, parse_unknown

	# extract the filename string
	addi $sp, $sp, -4
	sw $ra, 0($sp)

	add $a0, $t2, 1
	la $a1, filename
	jal str_copy

	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	addi $a0, $zero, 7
	add $a1, $zero, $zero
	jr $ra
	
parse_help:
	# load second character
	addi $t2, $t2, 1
	lb $t0, 0($t2)

	# check if second character is an e
	li $t1, 0x65
	bne $t0, $t1, parse_unknown

	# load third character
	addi $t2, $t2, 1
	lb $t0, 0($t2)

	# check if third character is an l
	li $t1, 0x6C
	bne $t0, $t1, parse_unknown

	# load fourth character
	addi $t2, $t2, 1
	lb $t0, 0($t2)

	# check if fourth character is a p
	li $t1, 0x70
	bne $t0, $t1, parse_unknown

	# load fifth character
	addi $t2, $t2, 1
	lb $t0, 0($t2)

	# check if fifth character is a null
	bne $t0, $zero, parse_unknown

	addi $a0, $zero, 8
	add $a1, $zero, $zero
	jr $ra

parse_unknown:
	# unknown command
	addi $a0, $zero, -1
	add $a1, $zero, $zero
	jr $ra

# takes in an ascii string
# returns a code specifying which velocity it is
# input: $a0 start of string
# output: $a0 velocity code
#	  $a1 last character parsed

# velocity codes are as follows:
# pp = 1
# p = 2
# mp = 3
# mf = 4
# f = 5
# ff = 6
# unknown = -1
parse_velocity:

	# check the first character
	lb $t0, 0($a0)

	li $t1, 0x70
	beq $t0, $t1, parse_velocity_p
	li $t1, 0x6D
	beq $t0, $t1, parse_velocity_m
	li $t1, 0x66
	beq $t0, $t1, parse_velocity_f

	j parse_velocity_unknown

parse_velocity_p:
	# check the next character
	addi $a0, $a0, 1
	lb $t0, 0($a0)

	# if this is a space or null then
	# the velocity is pianissimo
	beq $t0, $zero, parse_velocity_p_end
	li $t1, 0x20
	beq $t0, $t1, parse_velocity_p_end

	# if this is a p then the velocity may be pp
	li $t1, 0x70
	beq $t0, $t1, parse_velocity_pp

	# otherwise something was entered wrong
	j parse_velocity_unknown
parse_velocity_p_end:
	add $a1, $a0, $zero
	li $a0, 2
	jr $ra
	
parse_velocity_pp:
	# make sure the next character is either a space or null
	addi $a0, $a0, 1
	lb $t0, 0($a0)

	# if this is a space or null then
	# the velocity is pianissimo
	beq $t0, $zero, parse_velocity_pp_return
	li $t1, 0x20
	beq $t0, $t1, parse_velocity_pp_return

	j parse_velocity_unknown
	
parse_velocity_pp_return:	
	add $a1, $a0, $zero
	li $a0, 1
	jr $ra

parse_velocity_m:	
	addi $a0, $a0, 1
	lb $t0, 0($a0)

	# see if this is a p
	li $t1, 0x70
	beq $t0, $t1, parse_velocity_mp
	# see if this is an f
	li $t1, 0x66
	beq $t0, $t1, parse_velocity_mf

	# otherwise this is an invalid velocity
	j parse_velocity_unknown
	
parse_velocity_mp:
	# make sure the next character is either a space or null
	addi $a0, $a0, 1
	lb $t0, 0($a0)

	# if this is a space or null then
	# the velocity is pianissimo
	beq $t0, $zero, parse_velocity_mp_return
	li $t1, 0x20
	beq $t0, $t1, parse_velocity_mp_return

	j parse_velocity_unknown

parse_velocity_mp_return:	
	add $a1, $a0, $zero
	li $a0, 3
	jr $ra

parse_velocity_mf:
	# make sure the next character is either a space or null
	addi $a0, $a0, 1
	lb $t0, 0($a0)

	# if this is a space or null then
	# the velocity is pianissimo
	beq $t0, $zero, parse_velocity_mf_return
	li $t1, 0x20
	beq $t0, $t1, parse_velocity_mf_return

parse_velocity_mf_return:	
	add $a1, $a0, $zero
	li $a0, 4
	jr $ra

parse_velocity_f:
	# check the next character
	addi $a0, $a0, 1
	lb $t0, 0($a0)

	# if this is a space or null then
	# the velocity is fortissimo
	beq $t0, $zero, parse_velocity_f_end
	li $t1, 0x20
	beq $t0, $t1, parse_velocity_f_end

	# if this is a f then the velocity may be ff
	li $t1, 0x66
	beq $t0, $t1, parse_velocity_ff

	# otherwise something was entered wrong
	j parse_velocity_unknown

parse_velocity_f_end:
	add $a1, $a0, $zero
	li $a0, 5
	jr $ra

parse_velocity_ff:
	# make sure the next character is either a space or null
	addi $a0, $a0, 1
	lb $t0, 0($a0)

	# if this is a space or null then
	# the velocity is pianissimo
	beq $t0, $zero, parse_velocity_ff_return
	li $t1, 0x20
	beq $t0, $t1, parse_velocity_ff_return

	j parse_velocity_unknown

parse_velocity_ff_return:	
	add $a1, $a0, $zero
	li $a0, 6
	jr $ra

parse_velocity_unknown:
	add $a1, $a0, $zero
	addi $a0, $zero, -1
	jr $ra

# takes in an ascii string
# representing an int and
# returns an integer. This method
# will read the characters until either
# a space or null character is found.
# if something other than an ascii character 0 through 9
# is encountered the method will terminate with an error code
# input: $a0 ascii string
# output: $a0 integer
#         $a1 0 if no error
#         $a2 last character processed (i.e. end of number string
str_to_int:
	add $t0, $zero, $a0 # save $a0

	add $a1, $zero, $zero
	add $a0, $zero, $zero
	add $t7, $zero, $zero
	
	# see if the first character is negative sign
	lb $t1, 0($t0)
	li $t2, 0x2D
	bne $t1, $t2, str_to_int_loop

	addi $t7, $zero, 1 # mark the number as negative
	addi $t0, $t0, 1
	lb $t1, 0($t0)
	
str_to_int_loop:
	# if this is a null character then end the loop
	beq $t1, $zero, str_to_int_loop_end

	# if this is a space then end the loop
	li $t2, 0x20
	beq $t1, $t2, str_to_int_loop_end

	# make sure this is not a number < '0'
	li $t2, 0x30
	blt $t1, $t2, str_to_int_bad_char

	# make sure this not a number > '9'
	li $t2, 0x39
	bgt $t1, $t2, str_to_int_bad_char

	# multiply the result by 10
	li $t2, 10
	mult $a0, $t2
	mflo $a0

	# find out the character - '0' value
	li $t2, 0x30
	sub $t3, $t1, $t2
	# add the character to the result
	add $a0, $a0, $t3
	
	# move the char pointer forward one
	addi $t0, $t0, 1
	lb $t1, 0($t0)
	
	j str_to_int_loop

str_to_int_bad_char:
	addi $a1, $zero, 1
	
str_to_int_loop_end:
	# if the number is negative then subtract the result from 0
	beq $t7, $zero, str_to_int_return
	sub $a0, $zero, $a0

str_to_int_return:
	add $a2, $zero, $t0
	jr $ra

# takes as input a pointer to the start of a string
# it then copies bytes into the specified memory
# until either a space or a null character is hit.
# this method will then terminate the copied string with a null character
# input: $a0 source string
# 	 $a1 target string
str_copy:
	lb $t0, 0($a0)
	beq $t0, $zero, str_copy_loop_end
	li $t1, 0x20
	beq $t0, $t1, str_copy_loop_end

	# copy the character
	sb $t0, 0($a1)

	addi $a0, $a0, 1
	addi $a1, $a1, 1
	j str_copy
	
str_copy_loop_end:
	sb $zero, 0($a1)
	jr $ra
	
	
	.data
a4: .word 0
a5: .word 0
filename: .space 256
# src/play_midi.s

	.text
	.globl play_note
	.globl play_song

# input:
#	$a0 pitch (0-127)
#	$a1 volume (0-127)
#	$a2 duration in seconds
#	$a3 instrument (0-127)
play_note:
	bge $a0, $zero, play_note_arg0_max

	# clamp at zero
	add $a0, $zero, $zero
	j play_note_arg1
play_note_arg0_max:
	li $t0, 127
	ble $a0, $t0, play_note_arg1

	# clamp at 127
	add $a0, $t0, $zero

play_note_arg1:
        addi $sp, $sp, -4
        sw $ra, 0($sp)

        jal map_dynamics_to_volume

        lw $ra, 0($sp)
        addi $sp, $sp, 4



play_note_arg2:
	bgt $a2, $zero, play_note_arg2_milli

	# clamp at 1
	li $a2, 1000
	j play_note_arg2

play_note_arg2_milli:
	li $t0, 120
	mult $a2, $t0
	mflo $a2


play_note_arg3:
	bge $a3, $zero, play_note_arg3_max

	# clamp at 0
	add $a3, $zero, $zero
	j play_note_exec
play_note_arg3_max:
	li $t0, 15
	ble $a3, $t0, play_note_exec

	# clamp at 127
	add $a3, $t0, $zero
play_note_exec:
	add $t1, $a2, $zero
        # scale the instrument
        li $t2, 8
        mult $a3, $t2
        mflo $t2
	add $t3, $a1, $zero

	add $a1, $t1, $zero
	add $a2, $t2, $zero
	add $a3, $t3, $zero

	li $v0, 33
	syscall
	jr $ra


play_song:

	la $t0, mem_size
	lw $t0, 0($t0)

	beq $t0, $0, empty_song

	la $t1, mem_loc
	lw $t1, 0($t1)

	addi $sp, $sp, 8 # push frame onto stack
	sw $ra, 0($sp) # push return address onto stack
	sw $s0, 4($sp) # push s0 onto stack

	add $s0, $t0, $t1 # store end of array in s0

	play_list_of_notes:

		beq $t1, $s0, exit

		# a0 now contains the first 4 bytes (start delta)
		lb $a0, 0($t1)
		sll $a0, $a0, 8

		lb $t2, 1($t1)
		andi $t2, $t2, 0xFF
		or $a0, $a0, $t2
		sll $a0, $a0, 8

		lb $t2, 2($t1)
		andi $t2, $t2, 0xFF
		or $a0, $a0, $t2
		sll $a0, $a0, 8

		lb $t2, 3($t1)
		andi $t2, $t2, 0xFF
		or $a0, $a0, $t2

		addi $sp, $sp, -4 # push frame onto stack
		sw $t1, 0($sp) # push t1 onto stack

		jal mem_eight_bit # convert a0 to eight bit bytes

		lw $t1, 0($sp) # pop t1 from stack
		addi $sp, $sp, 4 # pop frame from stack

		add $a1, $v0, $zero # move converted delta to a1

		lb $a2, 4($t1) # a2 now contains command/instrument byte
		andi $a2, $a2, 0x0F # a2 is now the instrument

		lb $a0, 5($t1) # a0 now contains the note byte note
		lb $a3, 7($t1) # a3 now contains the velocity byte

		li $v0, 33
		syscall

		# a0 now contains the first 4 bytes (start delta)
		lb $a0, 8($t1)
		sll $a0, $a0, 8

		lb $t2, 9($t1)
		andi $t2, $t2, 0xFF
		or $a0, $a0, $t2
		sll $a0, $a0, 8

		lb $t2, 10($t1)
		andi $t2, $t2, 0xFF
		or $a0, $a0, $t2
		sll $a0, $a0, 8

		lb $t2, 11($t1)
		andi $t2, $t2, 0xFF
		or $a0, $a0, $t2


		addi $sp, $sp, -4 # push frame onto stack
		sw $t1, 0($sp) # push t1 onto stack

		jal mem_eight_bit # convert a0 to eight bit bytes

		lw $t1, 0($sp) # pop t1 from stack
		addi $sp, $sp, 4 # pop frame from stack

		add $a1, $v0, $zero # move converted delta to a1

		lb $a2, 12($t1) # a2 now contains command/instrument byte
		andi $a2, $a2, 0x0F # a2 is now the instrument

		lb $a0, 13($t1) # a0 now contains the note byte note
		lb $a3, 15($t1) # a3 now contains the velocity byte

		li $v0, 33
		syscall

		addi $t1, $t1, 16 # sets t0 to the next note

		j play_list_of_notes

	exit:

	lw $ra, 0($sp)
	addi $sp, $sp, 4

	empty_song:
	jr $ra

#
map_dynamics_to_volume:
    li $t0, 1
    beq $a1, $t0, play_note_pp
    li $t0, 2
    beq $a1, $t0, play_note_p
    li $t0, 3
    beq $a1, $t0, play_note_mp
    li $t0, 4
    beq $a1, $t0, play_note_mf
    li $t0, 5
    beq $a1, $t0, play_note_f
    j play_note_ff

map_dynamics_to_volume_end:
    jr $ra

play_note_pp:
	li $a1, 10
	j map_dynamics_to_volume_end

play_note_p:
	li $a1, 32
	j map_dynamics_to_volume_end

play_note_mp:
	li $a1, 52
	j map_dynamics_to_volume_end

play_note_mf:
	li $a1, 73
	j map_dynamics_to_volume_end

play_note_f:
	li $a1, 94
	j map_dynamics_to_volume_end

play_note_ff:
	li $a1, 127
    j map_dynamics_to_volume_end

	.data
play_song_msg:	.asciiz "TODO: Implement play_song method\n[Press any key to continue]"
# src/file_handling.s

	.data
file_buffer: .word 0 #MIDI file to read will not exceed 100K for complex files
midi_header: .byte 0x4d, 0x54, 0x68, 0x64, 0x00, 0x00, 0x00, 0x06, 0x00, 0x00, 0x00, 0x01, 0x01, 0xe0
track_header: .byte 0x4d, 0x54, 0x72, 0x6b
set_tempo: .byte 0x00, 0xff, 0x51, 0x03, 0x07, 0x53, 0x00,0x00, 0xB0, 0x00, 0x00, 0xB1, 0x08, 0x00, 0xB2, 0x10, 0x00, 0xB3, 0x18, 0x00, 0xB4, 0x20, 0x00, 0xB5, 0x28, 0x00, 0xB6, 0x30, 0x00, 0xB7, 0x38, 0x00, 0xB8, 0x40, 0x00, 0xB9, 0x48, 0x00, 0xBA, 0x50, 0x00, 0xBB, 0x58, 0x00, 0xBC, 0x60, 0x00, 0xBD, 0x68, 0x00, 0xBE, 0x70, 0x00, 0xBF, 0x78,0x00, 0xBF, 0x78
error_read_msg: .asciiz "ERROR reading file"
error_open_msg: .asciiz "ERROR opening file"
error_write_midi_header_msg: .asciiz "ERROR writing the midi header"
error_write_track_header_msg: .asciiz "ERROR writing the track header"
error_write_track_length_msg: .asciiz "ERROR writing the track length"
error_write_file_msg: .asciiz "ERROR writing to the file"
error_no_file: .asciiz "ERROR no notes to save to file"
error_set_tempo_msg: .asciiz "ERROR tempo didn't set correctly"
midi_track_length: .word 0
file_temp: .space 4

	.text
	.globl save_file
	.globl load_file

save_file:
#Check if the array is 0 before trying to save the file
 	lw $t0, mem_size($0)
 	la $s0, error_no_file
	beq  $t0, $zero, errorMsg

#Open a file to write with the user inputted filename
	li $v0, 13
	la $a0, filename
	li $a1, 1 #open for writing
	li $a2, 0 #mode ignored
	syscall
	move $s6, $v0
	#error check for open file
	la $s0, error_open_msg
	blt  $v0, $zero, errorMsg

	#write to the now open file

#write the track_header length section
	li $v0, 15
	move $a0, $s6
	la $a1, mem_size
	li $a2, 4 #number of bytes in the track length
	syscall
	#error check for writing the track length
	la $s0, error_write_track_length_msg
	blt  $v0, $zero, errorMsg

	#write the fileBuffer to the file
	li $v0, 15
	move $a0, $s6
	lw $a1, mem_loc
	la $t0, mem_size
	lw $a2, 0($t0) #load the length of the track to be written
	syscall
	#error check for writing the file
	la $s0, error_write_file_msg
	blt  $v0, $zero, errorMsg

	# Close the file
  	li   $v0, 16       # system call for close file
  	move $a0, $s6      # file descriptor to close
  	syscall            # close file

	jr $ra



	#write the midi_header
	li $v0, 15
	move $a0, $s6
	la $a1, midi_header
	li $a2, 14 #number of bytes in the midi_header
	syscall
	#error check for writing the midi header
	la $s0, error_write_midi_header_msg
	blt  $v0, $zero, errorMsg

	#write the track_header (minus the length section)
	li $v0, 15
	move $a0, $s6
	la $a1, track_header
	li $a2, 4 #number of bytes in the track_header
	syscall
	#error check for writing the track header
	la $s0, error_write_track_header_msg
	blt  $v0, $zero, errorMsg

	#write the track_header length section
	li $v0, 15
	move $a0, $s6
	la $a1, mem_size
	lw $t0, 0($a1)
	addi $t0, $t0, 58
	la $a1, midi_track_length
	la $t1, file_temp
	sw $t0, 0($t1)
	addi $t1, $t1, -3
	lb $t2, 0($t1)
	sb $t2, 0($a1)
	addi $t1, $t1, 1
	lb $t2, 0($t1)
	sb $t2, 1($a1)
	addi $t1, $t1, 1
	lb $t2, 0($t1)
	sb $t2, 2($a1)
	addi $t1, $t1, 1
	lb $t2, 0($t1)
	sb $t2, 3($a1)
	li $a2, 4 #number of bytes in the track length
	syscall
	#error check for writing the track length
	la $s0, error_write_track_length_msg
	blt  $v0, $zero, errorMsg

	#write the set_tempo section
	li $v0, 15
	move $a0, $s6
	la $a1, set_tempo
	li $a2, 58 #number of bytes in the midi_header
	syscall
	#error check for writing the track length
	la $s0, error_set_tempo_msg
	blt  $v0, $zero, errorMsg

	#write the fileBuffer to the file
	li $v0, 15
	move $a0, $s6
	lw $a1, mem_loc
	la $t0, mem_size
	lw $a2, 0($t0) #load the length of the track to be written
	syscall
	#error check for writing the file
	la $s0, error_write_file_msg
	blt  $v0, $zero, errorMsg

	# Close the file
  	li   $v0, 16       # system call for close file
  	move $a0, $s6      # file descriptor to close
  	syscall            # close file

	jr $ra

load_file:

	#Open a file to read with the user inputted filename
	li $v0, 13
	la $a0, filename
	add $a1, $zero, $zero #opened for read
	add $a2, $zero, $zero #mode ignored
	syscall
	#error check for open file
	la $s0, error_open_msg
	blt  $v0, $zero, errorMsg

	#Read from the file just opened
	add $a0, $zero, $v0
	li $v0, 14
	la $a1, file_buffer
	add $a2, $zero, 4 #read the first 4 bytes
	syscall
	move $s6, $a0
	 # push the return address to the stack
    addi $sp, $sp, -4
    sw $ra, 0($sp)

    #Call diegos method to allocate the  memory
	la $a0, file_buffer
    lw $a0, 0($a0)
    jal mem_load
     # pop the return address from the stack
    lw $ra, 0($sp)
    addi $sp, $sp, 4

	#Error check for read file
	la $s0, error_read_msg
	blt  $v0, $zero, errorMsg

	#Read from the file just opened
	add $a0, $zero, $s6
	li $v0, 14
	lw $a1, mem_loc
	lw $a2, file_buffer($zero) #read the first 4 bytes
	syscall

	#close file after reading it
	li $v0, 16
	la $a0, filename
	syscall

	jr $ra

errorMsg:
	add $a0, $s0, $zero
	li $v0, 4
	syscall
	jr $ra
# src/cat.s

# cat function which prints out current notes in load tracked
# with their start time, velocity, duration, and instrument
    .data
msgNum: .asciiz "\n#: "
msgNote: .asciiz "\tNote: "
msgNoteVel: .asciiz "\tVelocity:"
msgNoteDur: .asciiz "\tDuration: "
msgNoteInst: .asciiz "\tInstrument: "
msgPP: .asciiz "PP"
msgP: .asciiz "P "
msgMP: .asciiz "MP"
msgMF: .asciiz "MF"
msgF: .asciiz "F "
msgFF: .asciiz "FF"
msgPiano: .asciiz "Piano"
msgChromaticPercussion: .asciiz "Chromatic Percussion"
msgOrgan: .asciiz "Organ"
msgGuitar: .asciiz "Guitar"
msgBass: .asciiz "Bass"
msgStrings: .asciiz "Strings"
msgEnsemble: .asciiz "Ensemble"
msgBrass: .asciiz "Brass"
msgReed: .asciiz "Reed"
msgPipe: .asciiz "Pipe"
msgSynthLead: .asciiz "Synth Lead"
msgSynthPad: .asciiz "Synth Pad"
msgSynthEffect: .asciiz "Synth Effect"
msgEthnic: .asciiz "Ethnic"
msgPercussion: .asciiz "Percussion"
msgSoundEffect: .asciiz "Sound Effect"
msgNoTrackForCat: .asciiz "****Error: There is currently no track in use****"

    .text
cat:

# get the number of notes currently loaded
la $a1, mem_size
    lw $a1, 0($a1) # load amount used
    beq $a1, $zero, cat_no_track
    la $a3, mem_loc
    lw $a3, 0($a3)

	addi $a2, $zero, 1
	addi $t0, $zero, 0

	j cat_loop

cat_no_track:

	li $v0, 4
	la $a0, msgNoTrackForCat
	syscall
	jr $ra

cat_loop:

	# prints the number of the note
	li $v0, 4
	la $a0, msgNum
	syscall

	li $v0, 1
	add $a0, $zero, $a2
	syscall

	lw $a0, 0($a3) # gets the duration
	addi $sp, $sp, -8
	sw $ra, 0($sp)
	jal mem_eight_bit
	lw $ra, 0($sp)
	addi $sp, $sp, 8
	add $t3, $a0, $zero # puts the start time in $t3
	lb $t4, 5($a3) # get the current note
	lb $t5, 7($a3) # get the current velocity
	lb $t6, 4($a3) # get the current instrument
	andi $t6, $t6, 0x0F # removes command from byte

	# prints note label
	li $v0, 4
	la $a0, msgNote
	syscall

	# prints the current note
	li $v0, 1
	add $a0, $zero, $t4
	syscall

	#prints the velocity label
	li $v0, 4
	la $a0, msgNoteVel
	syscall

	# tests velocities to see what value should be printed out
	bne $t5, 10, test_p # test if velocity is not pp

	li $v0, 4
	la $a0, msgPP
	syscall
	j continue_cat

test_p:

	bne $t5, 32, test_mp
	li $v0, 4
	la $a0, msgP
	syscall
	j continue_cat

test_mp:

	bne $t5, 52, test_mf
	li $v0, 4
	la $a0, msgMP
	syscall
	j continue_cat

test_mf:

	bne $t5, 73, test_f
	li $v0, 4
	la $a0, msgMF
	syscall
	j continue_cat

test_f:

	bne $t5, 94, test_ff
	li $v0, 4
	la $a0, msgF
	syscall
	j continue_cat

test_ff:

	li $v0, 4
	la $a0, msgFF
	syscall
	j continue_cat

continue_cat:

	#prints out duration label
	li $v0, 4
	la $a0, msgNoteDur
	syscall

	# calculates the duration
	addi $a3, $a3, 8 # increments the event to the off state
	
	lb $a0, 0($a3)
	sll $a0, $a0, 8
	
	lb $t1, 1($a3)
	sll $a0 $a0, 8
	andi $t1, $t1, 0xFF
	or $a0, $a0, $t1
	
	lb $t1, 2($a3)
	sll $a0 $a0, 8
	andi $t1, $t1, 0xFF
	or $a0, $a0, $t1

	lb $t1, 3($a3)
	sll $a0 $a0, 8
	andi $t1, $t1, 0xFF
	or $a0, $a0, $t1

	addi $sp, $sp, -8
	sw $ra, 0($sp)
	jal mem_eight_bit
	lw $ra, 0($sp)
	addi $sp, $sp, 8
	add $t7, $v0, $zero # transfers the 8-bit word to $t7


	li $v0, 1
	add $a0, $zero, $t7
	syscall

	#prints the instrument label
	li $v0, 4
	la $a0, msgNoteInst
	syscall

	bne $t6, 0, test_chromatic_percussion
	li $v0, 4
	la $a0, msgPiano
	syscall
	j continue_cat_2

test_chromatic_percussion:

	bne $t6, 1, test_organ
	li $v0, 4
	la $a0, msgChromaticPercussion
	syscall
	j continue_cat_2

test_organ:

	bne $t6, 2, test_guitar
	li $v0, 4
	la $a0, msgOrgan
	syscall
	j continue_cat_2

test_guitar:

	bne $t6, 3, test_bass
	li $v0, 4
	la $a0, msgGuitar
	syscall
	j continue_cat_2

test_bass:

	bne $t6, 4, test_strings
	li $v0, 4
	la $a0, msgBass
	syscall
	j continue_cat_2

test_strings:

	bne $t6, 5, test_ensemble
	li $v0, 4
	la $a0, msgStrings
	syscall
	j continue_cat_2

test_ensemble:

	bne $t6, 6, test_brass
	li $v0, 4
	la $a0, msgEnsemble
	syscall
	j continue_cat_2

test_brass:

	bne $t6, 7, test_reed
	li $v0, 4
	la $a0, msgBrass
	syscall
	j continue_cat_2

test_reed:

	bne $t6, 8, test_pipe
	li $v0, 4
	la $a0, msgReed
	syscall
	j continue_cat_2

test_pipe:

	bne $t6, 9, test_synth_lead
	li $v0, 4
	la $a0, msgPipe
	syscall
	j continue_cat_2

test_synth_lead:

	bne $t6, 10, test_synth_pad
	li $v0, 4
	la $a0, msgSynthLead
	syscall
	j continue_cat_2

test_synth_pad:

	bne $t6, 11, test_synth_effect
	li $v0, 4
	la $a0, msgSynthPad
	syscall
	j continue_cat_2

test_synth_effect:

	bne $t6, 12, test_ethnic
	li $v0, 4
	la $a0, msgSynthEffect
	syscall
	j continue_cat_2

test_ethnic:

	bne $t6, 13, test_percussion
	li $v0, 4
	la $a0, msgEthnic
	syscall
	j continue_cat_2

test_percussion:

	bne $t6, 14, test_effect
	li $v0, 4
	la $a0, msgPercussion
	syscall
	j continue_cat_2

test_effect:

	li $v0, 4
	la $a0, msgSoundEffect
	syscall
	j continue_cat_2

continue_cat_2:

	addi $a2, $a2, 1
	addi $a3, $a3, 8
	addi $a1, $a1, -16
	bne $a1, $zero, cat_loop
	jr $ra
# src/help.s

	.text
	.globl help

help:
	li $v0, 4
	la $a0, help_msg
	syscall

	li $v0, 12
	syscall

	jr $ra

	.data
help_msg: .asciiz "TODO: Implement help\n[Press any key]"# src/add.s

#a0 note
#a1 velocity
#a2 duration
#a3 instrument
	.text
	.globl add_note
	.globl add_rest

add_note:
	li $t0, 15
	bgt $a3, $t0, add_note_bad_instrument

	addi $sp, $sp, -4
	sw $ra, 0($sp)
	# Convert volume for playability.
	jal map_dynamics_to_volume
	# pop the return address from the stack
	lw $ra, 0($sp)
	addi $sp, $sp, 4


	move $t2, $a0
	li $v0, 4
	la $a0, add_note_msg
	syscall

	# store 0x90 (on) + ii in byte 4
	li $t3, 4
	li $t0, 0x90
	add $t0, $t0, $a3
	sb $t0, MIDI_ON($t3)

	#Off signal
	li $t0, 0x80
	add $t0, $t0, $a3
	sb $t0, MIDI_OFF($t3)

	li $t3, 5
	# store note in byte 5
	sb $t2, MIDI_ON($t3)
	sb $t2, MIDI_OFF($t3)
	# store velocity in byte 6
	li $t3, 7
	addi $a1, $a1, 0x8000
	sb $a1, MIDI_ON($t3)
	sb $a1, MIDI_OFF($t3)
	srl $a1, $a1, 8
	addi $t3, $t3, -1
	sb $a1, MIDI_ON($t3)
	sb $a1, MIDI_OFF($t3)

	#load byte 2,3 store byte 2,3 of time in MIDI_ON bytes 0,
	lw $a0, time		# Get rest time
	li $t0, 120			#480 ticks per quarter note
	mul $a0, $a0, $t0  #convert to ticks from 16th notes
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	# Call convert time to 7 bit.
	jal mem_seven_bit
	# pop the return address from the stack
	lw $ra, 0($sp)
	addi $sp, $sp, 4

	la $t7, MIDI_ON
	sb $v0, 3($t7)
	srl $v0, $v0, 8
	sb $v0, 2($t7)
	srl $v0, $v0, 8
	sb $v0, 1($t7)
	srl $v0, $v0, 8
	sb $v0, 0($t7)


	# Reset time to 0
	sw $zero, time

	move $a0, $a2		#Get delta
	li $t0, 120			#480 ticks per quarter note
	mul $a0, $a0, $t0  #Convert from 16th notes to ticks

	addi $sp, $sp, -4
	sw $ra, 0($sp)
	# Call convert duration to 7 bit.
	jal mem_seven_bit
	# pop the return address from the stack
	lw $ra, 0($sp)
	addi $sp, $sp, 4

	la $t7, MIDI_OFF
	sb $v0, 3($t7)
	srl $v0, $v0, 8
	sb $v0, 2($t7)
	srl $v0, $v0, 8
	sb $v0, 1($t7)
	srl $v0, $v0, 8
	sb $v0, 0($t7)

	# push the return address to the stack
	addi $sp, $sp, -4
	sw $ra, 0($sp)

	# Call Diego's add to track.
	jal mem_add #add MIDI_ON and MIDI_OFF to track.
	# pop the return address from the stack
	lw $ra, 0($sp)
	addi $sp, $sp, 4

	jr $ra

add_note_bad_instrument:
        li $v0, 4
        la $a0, add_note_bad_instrument_msg
        syscall

        jr $ra

add_rest:

	li $v0, 4
	la $a0, add_rest_msg
	syscall

	add $a2, $0, $a1 # set a2 to duration
	addi $a0, $0, 0 # note 0
	addi $a1, $0, 1 # velocity pp
	addi $a3, $0, 0 # instrument 0

	j add_note

	.data
add_note_msg:	.asciiz "Adding note\n"
add_note_bad_instrument_msg:	 .asciiz "Invalid instrument. Enter a number between 0 and 15 (inclusive)\n"
add_rest_msg:	.asciiz "Adding rest\n"
MIDI_ON: .word  0, 0 	#  (hex) tt tt tt tt ci nn 80vv
MIDI_OFF: .word 0, 0 	#   	t: absolute time.
			#   	c: Command (9 = on, 8=0ff)
			#	i: note
			#	v: velocity
			#	x: undefined
time: .space 4		#	Current rest duration.  Should only go up to 2^28
# src/mem_man.s

    .data
mem_loc: .word 0    # store the starting address of the array
mem_size: .word 0    # store the size of the array
    .text

mem_add:
    # push the return address to the stack
    addi $sp, $sp, -4
    sw $ra, 0($sp)

    # load the record into a0 and a1
    jal expand
    la $t0, MIDI_ON
    lw $a0, 0($t0)
    lw $a1, 4($t0)
    jal addRecord

    jal expand
    la $t0, MIDI_OFF
    lw $a0, 0($t0)
    lw $a1, 4($t0)
    jal addRecord

    # pop the return address from the stack
    lw $ra, 0($sp)
    addi $sp, $sp, 4

    jr $ra

expand:
    # check how much memory we have used
    la $t1, mem_size
    lw $t1, 0($t1)

    addi $a0, $0, 8 # the amount we increase the allocation by
    # expand the array by 1 note (8 bytes)
    li $v0, 9 # sbrk
    syscall

    # check if we need to store the address of the list
    la $t0, mem_loc
    lw $t1, 0($t0)
    bne $t1, $zero, skip_save_addr
    sw $v0, 0($t0)

    skip_save_addr:
        # update the size of the array
        la $t0, mem_size
        lw $t1, 0($t0)
        add $t1, $t1, $a0
        sw $t1, 0($t0)
        jr $ra

addRecord:
    # search for the appropriate location to insert the new record
    la $t0, mem_loc
    la $t1, mem_size
    lw $t0, 0($t0) # get the location of the array
    lw $t2, 0($t1) # get the size of the array

    add $t3, $t0, $0 # location of first note
    beq $t2, $0, insert_note # if no notes, insert at beginning

    add $t3, $t0, $t2 # add number of notes to start location
    addi $t3, $t3, -8 # move back one note

    insert_note:
    sw $a0, 0($t3) # insert record in next slot
    sw $a1, 4($t3)

    jr $ra


# this function will turn the word in a0 into a 7 bit word in v0
mem_seven_bit:
    # convert msb to 7 bit
    sll $t0, $a0, 3
    ori $t0, $t0, 0x80000000
    andi $t0, $t0, 0xFF000000

    # convert 2nd byte to 7 bit
    sll $t1, $a0, 2
    ori $t1, $t1, 0x00800000
    andi $t1, $t1, 0x00FF0000

    # convert 3rd byte to 7 bit
    sll $t2, $a0, 1
    ori $t2, $t2, 0x00008000
    andi $t2, $t2, 0x0000FF00

    # convert lsb to 7 bit
    andi $t3, $a0, 0x0000007F

    add $v0, $0, $0 # clear v0
    or $v0, $v0, $t0
    or $v0, $v0, $t1
    or $v0, $v0, $t2
    or $v0, $v0, $t3

    jr $ra

# this function will turn the 7 bit word in a0 into a 8 bit word in v0
mem_eight_bit:
    andi $t0, $a0, 0x7F
    andi $t1, $a0, 0x7F00
    srl $t1, $t1, 1
    add $t0, $t0, $t1

    andi $t1, $a0, 0x7F0000
    srl $t1, $t1, 2
    add $t0, $t0, $t1

    andi $t1, $a0, 0x7F000000
    srl $t1, $t1, 3
    add $t0, $t0, $t1

    add $v0, $t0, $0

    jr $ra

# expands memory allocated if needed to fit the amount of space requested in a0
mem_load:
    la $t0, mem_size
    lw $t1, 0($t0)

    sub $t1, $a0, $t1 # find difference in needed vs current
    sw $a0, 0($t0) # store a0 as new mem_size

    bltz $t1, done_allocating

    addi $v0, $0, 9 # sbrk syscall
    add $a0, $t1, $0 # amount to allocate
    syscall

    # check if we need to store the address of the list
    la $t0, mem_loc
    lw $t1, 0($t0)
    bne $t1, $zero, done_allocating
    sw $v0, 0($t0)

    done_allocating:

    jr $ra
