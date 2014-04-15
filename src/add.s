#a1 note
#a2 velocity
#a3 duration
#a4 instrument
#a5 
	.text
	.globl add_note
	.globl add_rest

add_note:
	li $v0, 4
	la $a0, add_note_msg
	syscall

	#load byte 2,3 store byte 2,3 of time in MIDI_ON bytes 0,1
	lw $t0, time(0)
	sb $t0, MIDI_ON(1)
	srl $t0, 8			# get next LSB
	sb $t0, MIDI_ON(0)
	
	jal add_rest #increment time

	lw $t0, time(0)
	sb $t0, MIDI_OFF(1)
	srl $t0, 8		
	sb $t0, MIDI_OFF(0)
	
	# store 0x90 (on) + ii in byte 2
	li $t0, 0x90
	
	add $t0, $t0, a4
	sb $t0, MIDI_ON(2)
	
	#Off signal
	li $t0, 0x80
	#TODO: a4 probably should be addressed like this.
	add $t0, $t0, a4
	sb $t0, MIDI_OFF(2)
	
	
	# store note in byte 3
	sb $a1, MIDI_ON(3)
	sb $a1, MIDI_OFF(3)
	# store velocity in byte 4
	sb $a2, MIDI_ON(4)
	sb $a2, MIDI_OFF(4)
	
	li $v0, 12
	syscall

	jr $ra

add_rest:
	li $v0, 4
	la $a0, add_rest_msg
	syscall

	lw $t0, time(0)
	add $t0, $t0, $a3		# time += duration
	sw $t0, time(0)

	li $v0, 12
	syscall
	
	jr $ra
	
	.data
add_note_msg:	.asciiz "Adding note\n[Press any key]"
add_rest_msg:	.asciiz "Adding rest\n[Press any key]"
MIDI_ON: .byte  6 	#  (hex) tttt cc ii nn vv 
MIDI_OFF: .byte 6 	#   t: absolute time.
					#   c: Command (9 = on, 8=0ff)
					#	i: note
					#	v: velocity
time: .byte 4		#	Current time.  Should be set at time of save/load.  Is a word, but only first 2 bytes should be used
