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
	ble $a2, $t0, play_note_exec

	# clamp at 127
	add $a3, $t0, $zero
play_note_exec:
	add $t1, $a2, $zero
	add $t2, $a3, $zero
	add $t3, $a1, $zero

	add $a1, $t1, $zero
	add $a2, $a2, $zero
	add $a3, $a3, $zero

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