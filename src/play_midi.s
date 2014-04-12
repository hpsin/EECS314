	.text
	.globl play_note

# input:
#	$a0 pitch (0-127)
#	$a1 duration in seconds
#	$a2 instrument (0-127)
#	$a3 volume (0-127)
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
	bgt $a1, $zero, play_note_arg1_milli

	# clamp at 1
	li $a1, 1000
	j play_note_arg2

play_note_arg1_milli:	
	li $t0, 1000
	mult $a1, $t0
	mflo $a1

play_note_arg2:
	bge $a2, $zero, play_note_arg2_max

	# clamp at 0
	add $a2, $zero, $zero
	j play_note_arg3
play_note_arg2_max:
	li $t0, 127
	ble $a2, $t0, play_note_arg3

	# clamp at 127
	add $a2, $t0, $zero

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
	li $v0, 33
	syscall
	jr $ra