# src/main.s

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
	li $v0, 4
	la $a0, error_message
	syscall

	li $v0, 12
	syscall
	j command_finished
	
	addi $sp, $sp, -4
	sw $ra, 0($sp)

	jal play_note

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

	li $t0, 50
	li $v0, 11
	la $a0, 0xA
blank_line_loop:
	syscall # print a blank line
	addi $t0, $t0, -1
	bne $t0, $zero, blank_line_loop
	
	jr $ra

.data
input_string: .space 100 # 99 char string
error_message: .asciiz "ERROR: Unknown or malformed command\n [Press Enter]"# src/strings.s

	.data
splash_screen:	 .asciiz "\n\n                                           |\\\n                      __  __ __  __ ____   | |\n                     |  \\/  |  \\/  |  _ \\  |/\n                     | |\\/| | |\\/| | |_) |/|_ \n                     | |  | | |  | |  __///| \\\n                     |_|  |_|_|  |_|_|  | \\|_ |\n                                         \\_|_/\n                                           |\n                                          @'\n             _______________________________________________________\n            |:::::: o o o o . |..... . .. . | [45]  o o o o o ::::::|\n            |:::::: o o o o   | ..  . ..... |       o o o o o ::::::|\n            |::::::___________|__..._...__._|_________________::::::|\n            | # # | # # # | # # | # # # | # # | # # # | # # | # # # |\n            | # # | # # # | # # | # # # | # # | # # # | # # | # # # |\n            | # # | # # # | # # | # # # | # # | # # # | # # | # # # |\n            | | | | | | | | | | | | | | | | | | | | | | | | | | | | |\n            |_|_|_|_|_|_|_|_|_|_|_|_|_|_|_|_|_|_|_|_|_|_|_|_|_|_|_|_|\n\n\n\nHirsch Singhal			Sam Castelaz			David Jannotta		\nRob Meyer		  	         Devin Schwab                        Diego Waxemberg\n\n\n                               [Press Enter to continue]\n"

clear_screen:	.asciiz "\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n"

input_prompt:	.asciiz "$ "

test_str:	.asciiz "test input"

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
	
play_note_pp:
	li $a1, 10
	j play_note_arg2
	
play_note_p:
	li $a1, 32
	j play_note_arg2
	
play_note_mp:
	li $a1, 52
	j play_note_arg2

play_note_mf:
	li $a1, 73
	j play_note_arg2

play_note_f:
	li $a1, 94
	j play_note_arg2

play_note_ff:
	li $a1, 127
	
play_note_arg2:
	bgt $a2, $zero, play_note_arg2_milli

	# clamp at 1
	li $a2, 1000
	j play_note_arg2

play_note_arg2_milli:	
	li $t0, 1000
	mult $a2, $t0
	mflo $a2


play_note_arg3:
	bge $a3, $zero, play_note_arg3_max

	# clamp at 0
	add $a3, $zero, $zero
	j play_note_exec
play_note_arg3_max:
	li $t0, 127
	ble $a3, $t0, play_note_exec

	# clamp at 127
	add $a3, $t0, $zero
play_note_exec:
	add $t1, $a2, $zero
	add $t2, $a3, $zero
	add $t3, $a1, $zero

	add $a1, $t1, $zero
	add $a2, $t2, $zero
	add $a3, $t3, $zero

	li $v0, 33
	syscall
	jr $ra


play_song:
	li $v0, 4
	la $a0, play_song_msg
	syscall

	li $v0, 12
	syscall
	
	jr $ra

	.data
play_song_msg:	.asciiz "TODO: Implement play_song method\n[Press any key to continue]"
# src/file_handling.s

	.text
	.globl save_file
	.globl load_file

save_file:
	li $v0, 4
	la $a0 save_file_msg
	syscall

	li $v0, 12
	syscall
	
	jr $ra

load_file:
	li $v0, 4
	la $a0, load_file_msg
	syscall

	li $v0, 12
	syscall
	
	jr $ra

	.data
save_file_msg:	.asciiz "TODO: Implement save file\n [Press any key to continue]"
load_file_msg:	.asciiz "TODO: Implement load file\n [Press any key to continue]"# src/cat.s

	.text
	.globl cat

cat:
	li $v0, 4
	la $a0, cat_msg
	syscall

	li $v0, 12
	syscall
	jr $ra

	.data
cat_msg: .asciiz "TODO: Implement cat\n[Press any key to continue]"# src/help.s

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
	move $t2, $a0
	li $v0, 4
	la $a0, add_note_msg
	syscall

	#load byte 2,3 store byte 2,3 of time in MIDI_ON bytes 0,
	lw $t0, time
	sw $t0, MIDI_ON

	move $t3, $ra
	jal add_rest #increment time
	move $ra, $t3

	lw $t0, time($zero)
	sw $t0, MIDI_OFF($zero)
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
	li $t3, 6
	sb $a1, MIDI_ON($t3)
	sb $a1, MIDI_OFF($t3)


	# push the return address to the stack
	addi $sp, $zero, -4
	sw $ra, 0($sp)

	# Call Diego's add to track.
	move $t3, $ra
	jal mem_add #add MIDI_ON and MIDI_OFF to track.
	move $ra, $t3

	# pop the return address from the stack
	lw $ra, 0($sp)
	addi $sp, $zero, 4
	
	li $v0, 12
	syscall

	jr $ra

add_rest:
	li $v0, 4
	la $a0, add_rest_msg
	syscall

	lw $t0, time($zero)
	add $t0, $t0, $a2		# time += duration
	sw $t0, time($zero)

	li $v0, 12
	syscall

	jr $ra

	.data
add_note_msg:	.asciiz "Adding note\n"
add_rest_msg:	.asciiz "Adding rest\n[Press any key]"
MIDI_ON: .word  0, 0 	#  (hex) tt tt tt tt ci nn vv xx
MIDI_OFF: .word 0, 0 	#   	t: absolute time.
			#   	c: Command (9 = on, 8=0ff)
			#	i: note
			#	v: velocity
			#	x: undefined
time: .space 4		#	Current time.  Should be set at time of save/load.  Is a word, but only first 2 bytes should be used
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
    # expand the array by 1 note (8 bytes)
    li $a0, 8
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
    addi $t2, $t2, -8 # the last record
    add $t1, $t0, $t2 # store the location of the last record in t1

    add $t4, $t1, $zero # t4 points to the location to store the record
    beq $t2, $zero, foundLocation # if this is the first record we are inserting

    findLocation:
        addi $t1, $t1, -8 # go back one record
        # load the current record in t3 & t4
        lw $t3, 0($t1)
        lw $t4, 4($t1)

        add $t4, $t1, 8 # t4 points to the location to store the record

        # if time_new_record > time_current_record
        bgt $a0, $t3, foundLocation


        # store the current record in the next slot
        sw $t3, 0($t4)
        sw $t4, 4($t4)

        j findLocation


    foundLocation:
        # insert record in next slot
        sw $a0, 0($t4)
        sw $a1, 4($t4)

        jr $ra
