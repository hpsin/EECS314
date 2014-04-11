	.text
	.globl parse_input
# this method takes in
# $a0 start of input string
# and returns
# $a0 command code
# $a1 heap allocated list of arguments

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

	addi $a0, $zero, 3
	add $a1, $zero, $zero
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

	# check if fifth character is a newline
	li $t1, 0xA
	bne $t0, $t1, parse_play_song

	# parse play not command
	addi $a0, $zero, 2
	add $a1, $zero, $zero
	jr $ra
	
parse_play_song:	
	# check if fifth character is a space
	li $t1, 0x20
	bne $t0, $t1, parse_unknown

	addi $a0, $zero, 1
	add $a1, $zero, $zero
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

	# check if fourth character is a newline
	li $t1, 0xA
	bne $t0, $t1, parse_unknown

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

	# check if fifth character is a newline
	li $t1, 0xA
	bne $t0, $t1, parse_unknown

	addi $a0, $zero, 8
	add $a1, $zero, $zero
	jr $ra

parse_unknown:
	# unknown command
	addi $a0, $zero, -1
	add $a1, $zero, $zero
	jr $ra
