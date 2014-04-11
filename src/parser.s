	.text
	.globl parse_input
# this method takes in
# $a0 start of input string
# and returns
# $a0 command code
# $a1 heap allocated list of arguments

# command codes are as follows
# play = 1
# play with args = 2
# add rest = 3
# add note = 4
# cat = 5
# load = 6
# save = 7
# help = 8
# unknown = -1
parse_input:
	lb $t0, 0($a0) # get the first character

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
	add $t2, $a0, $zero

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

	addi $a0, $zero, 3
	add $a1, $zero, $zero
	jr $ra

parse_play:
	jr $ra

parse_cat:
	jr $ra

parse_load:
	jr $ra

parse_save:
	jr $ra

parse_help:
	jr $ra

parse_unknown:
	# unknown command
	addi $a0, $zero, -1
	add $a1, $zero, $zero
	jr $ra
