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
msgPia: .asciiz "Piano"
msgCP: .asciiz "Chromatic Percussion"
msgOrg: .asciiz "Organ"
msgGui: .asciiz "Guitar"
msgBass: .asciiz "Bass"
msgStri: .asciiz "Strings"
msgEns: .asciiz "Ensemble"
msgBra: .asciiz "Brass"
msgReed: .asciiz "Reed"
msgPipe: .asciiz "Pipe"
msgSL: .asciiz "Synth Lead"
msgSP: .asciiz "Synth Pad"
msgSE: .asciiz "Synth Effect"
msgEth: .asciiz "Ethnic"
msgPer: .asciiz "Percussion"
msgEff: .asciiz "Sound Effect"
msgVelError: .asciiz "****Error: A note does not have a velocity****"
msgInstError: .asciiz "****Error: A note does not have an instrument****"
msgNoTrackForCat: .asciiz "****Error: There is currently no track in use****"

    .text
cat:
	
	# get the number of notes currently loaded
	la $a1, mem_size
    lw $a1, 0($a1) # load amount used
    beq $a1, $zero, cat_no_track
	la $a1, mem_size # reset $a1 and divide it by 16 to get
    lw $a1, 0($a1) # the true number of notes in the track
    srl $a1, $a1, 4
	addi $a2, $zero, 1
	la $a3, mem_loc($zero)
	addi $t0, $zero, -8
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

	addi $t0, $t0, 8
	lw $t3, 0($a3)
	lb $t4, 5($a3) # get the current note
	lb $t5, 6($a3) # get the current velocity
	lb $t6, 4($a3) # get the current instrument
	andi $t6, $t6, 0x0F

	# prints the what note it is
	li $v0, 4
	la $a0, msgNote
	syscall

	li $v0, 1
	add $a0, $zero, $t4
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

	bne $t5, 6, cat_no_vel
	li $v0, 4
	la $a0, msgFF
	syscall
	j continue_cat

cat_no_vel: 

	li $v0, 1
	add $a0, $t5, $zero
	syscall
	j continue_cat

continue_cat:

	#prints the duration of the note
	li $v0, 4
	la $a0, msgNoteDur
	syscall

	addi $t0, $t0, 8
	lw $t1, mem_loc($t0)
	sub $t1, $t1, $t3

	li $v0, 4
	add $a0, $zero, $t1 
	syscall

	#prints the instrument of the note
	li $v0, 4
	la $a0, msgNoteInst
	syscall

	bne $t6, 0, test_c_p
	li $v0, 4
	la $a0, msgPia
	syscall
	j continue_cat_2

test_c_p:

	bne $t6, 1, test_org
	li $v0, 4
	la $a0, msgCP
	syscall
	j continue_cat_2

test_org:

	bne $t6, 2, test_gui
	li $v0, 4
	la $a0, msgOrg
	syscall
	j continue_cat_2

test_gui:

	bne $t6, 3, test_bass
	li $v0, 4
	la $a0, msgGui
	syscall
	j continue_cat_2

test_bass:

	bne $t6, 4, test_stri
	li $v0, 4
	la $a0, msgBass
	syscall
	j continue_cat_2

test_stri:

	bne $t6, 5, test_ens
	li $v0, 4
	la $a0, msgStri
	syscall
	j continue_cat_2

test_ens:

	bne $t6, 6, test_bra
	li $v0, 4
	la $a0, msgEns
	syscall
	j continue_cat_2

test_bra:

	bne $t6, 7, test_reed
	li $v0, 4
	la $a0, msgBra
	syscall
	j continue_cat_2

test_reed:

	bne $t6, 8, test_pipe
	li $v0, 4
	la $a0, msgReed
	syscall
	j continue_cat_2

test_pipe:

	bne $t6, 9, test_s_l
	li $v0, 4
	la $a0, msgPipe
	syscall
	j continue_cat_2

test_s_l:

	bne $t6, 10, test_s_p
	li $v0, 4
	la $a0, msgSL
	syscall
	j continue_cat_2

test_s_p:

	bne $t6, 11, test_s_e
	li $v0, 4
	la $a0, msgSP
	syscall
	j continue_cat_2

test_s_e:

	bne $t6, 12, test_eth
	li $v0, 4
	la $a0, msgSE
	syscall
	j continue_cat_2

test_eth:

	bne $t6, 13, test_per
	li $v0, 4
	la $a0, msgEth
	syscall
	j continue_cat_2

test_per:

	bne $t6, 14, test_eff
	li $v0, 4
	la $a0, msgPer
	syscall
	j continue_cat_2

test_eff:

	bne $t6, 15, cat_no_inst
	li $v0, 4
	la $a0, msgEff
	syscall
	j continue_cat_2

cat_no_inst:

	li $v0, 1
	add $a0, $t6, $zero
	syscall
	j continue_cat_2

continue_cat_2:

	addi $a2, $a2, 1
	addi $a1, $a1, -1
	bne $a1, $zero, cat_loop
	jr $ra