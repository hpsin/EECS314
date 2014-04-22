# cat function which prints out current notes in load tracked 
# with their start time, velocity, duration, and instrument
    .globl cat
    .data

msgNote: .asciiz "\nNote: "
msgNoteST: .asciiz "\tStart Time:"
msgNoteVel: .asciiz "\tVelocity:"
msgNoteDur: .asciiz "\tDuration: "
msgNoteInst: .asciiz "\tInstrument: "
msgPP: .asciiz "PP"
msgP: .asciiz "P "
msgMP: .asciiz "MP"
msgMF: .asciiz "MF"
msgF: .asciiz "F "
msgFF: .asciiz "FF"
msgVelError: .asciiz "\n\n****Error: A note does not have a velocity****"
msgInstError: .asciiz "\n\n****Error: A note does not have an instrument"

    .text
cat:
	
	# get the number of notes currently loaded
	lw $a1, mem_size($zero)
	addi $a2, $zero , 1
	bne $a1, $zero, cat_loop
	jr $ra

cat_loop:
	addi $t0, $a2, -1
	sll $t0, $t0, 3 # substarcts the current note by 1 and multiplies it by 8 to get the index
	lw $t1, mem_loc($t0)
	addi $t0, $t0, 4
	lw $t2, mem_loc($t0)

	lb $t4, 1($t2) # the current note
	lb $t5, 2($t2) # the velocity of the note
	lb $t6, 0($t2) # the instrument of the note

	# prints the what note it is
	li $v0, 4
	la $a0, msgNote
	syscall

	li $v0, 1
	add $a0, $zero, $t4
	syscall

	# prints the start time of the note
	li $v0, 4
	la $a0, msgNoteST
	syscall

	li $v0, 1
	lw $a0, 0($t1)
	syscall

	#prints the velocity of the note
	li $v0, 4
	la $a0, msgNoteVel
	syscall

	# tests velocities to see what value should be printed out
	bne $t5, 1, test_p
	li $v0, 4
	la $a0, msgPP
	syscall
	j continue_cat

test_p:

	bne $t5, 2, test_p
	li $v0, 4
	la $a0, msgPP
	syscall
	j continue_cat

test_mp:

	bne $t5, 3, test_mf
	li $v0, 4
	la $a0, msgPP
	syscall
	j continue_cat

test_mf:

	bne $t5, 4, test_f
	li $v0, 4
	la $a0, msgPP
	syscall
	j continue_cat

test_f:

	bne $t5, 5, test_ff
	li $v0, 4
	la $a0, msgPP
	syscall
	j continue_cat

test_ff:

	bne $t5, 6, cat_no_vel
	li $v0, 4
	la $a0, msgPP
	syscall
	j continue_cat

cat_no_vel: 

	li $v0, 4
	la $a0, msgVelError
	syscall
	jr $ra

continue_cat:

	#prints the duration of the note
	li $v0, 4
	la $a0, msgNoteDur
	syscall

	li $v0, 4
	add $a0, $zero, $zero 
	syscall

	#prints the instrument of the note
	li $v0, 4
	la $a0, msgNoteInst
	syscall

	li $v0, 4
	la $a0, continue_cat_msg
	syscall

	addi $a2, $a2, 1
	addi $a1, $a1, -1
	bne $a1, $zero, cat_loop
	jr $ra

    .data
continue_cat_msg: .asciiz "Need instrument list. Use same format as velocity"
