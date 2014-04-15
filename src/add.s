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

	#load byte 2,3 store byte 2,3 of time in MIDI_ON bytes 0,1
	li $t3, 0
	lw $t0, time
	sw $t0, MIDI_ON($t3)
	
	move $t3, $ra
	jal add_rest #increment time
	move $ra, $t3
	
	lw $t0, time
	sw $t0, MIDI_OFF($t3)
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
	
	# Call Diego's add to track.
	move $t3, $ra
	#jal Diego's jank #add MIDI_ON and MIDI_OFF to track.
	move $ra, $t3	
	
	li $v0, 12
	syscall

	jr $ra

add_rest:
	li $v0, 4
	la $a0, add_rest_msg
	syscall

	lw $t0, time
	add $t0, $t0, $a2		# time += duration
	sw $t0, time

	li $v0, 12
	syscall
	
	jr $ra
	
	.data
add_note_msg:	.asciiz "Adding note\n[Press any key]"
add_rest_msg:	.asciiz "Adding rest\n[Press any key]"
MIDI_ON: .space  8 	#  (hex) tt tt tt tt ci nn vv xx
MIDI_OFF: .space 8 	#   	t: absolute time.
			#   	c: Command (9 = on, 8=0ff)
			#	i: note
			#	v: velocity
			#	x: undefined
time: .space 4		#	Current time.  Should be set at time of save/load.  Is a word, but only first 2 bytes should be used
