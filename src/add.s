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
	li $t3, 6
	addi $a1, $a1, 0x8000
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

	sw $v0, MIDI_ON($zero)
	
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
	
	sw $v0, MIDI_OFF($zero)
	
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
	
	lw $t0, time($zero)
	add $t0, $t0, $a2		# time += duration
	sw $t0, time($zero)

	jr $ra

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
