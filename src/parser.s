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
