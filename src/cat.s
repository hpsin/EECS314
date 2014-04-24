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

	lw $t3, 0($a3) # gets the duration
	lb $t4, 5($a3) # get the current note
	lb $t5, 6($a3) # get the current velocity
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
	bne $t5, 1, test_p # test if velocity is not pp

	li $v0, 4
	la $a0, msgPP
	syscall
	j continue_cat

test_p:

	bne $t5, 2, test_mp
	li $v0, 4
	la $a0, msgP
	syscall
	j continue_cat

test_mp:

	bne $t5, 3, test_mf
	li $v0, 4
	la $a0, msgMP
	syscall
	j continue_cat

test_mf:

	bne $t5, 4, test_f
	li $v0, 4
	la $a0, msgMF
	syscall
	j continue_cat

test_f:

	bne $t5, 5, test_ff
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
	addi $a3, $a3, 8
	add $t0, $zero, $zero
	lw $t7 0($a3)
	sub $t1, $t7, $t3

	li $v0, 1
	add $a0, $zero, $t1
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