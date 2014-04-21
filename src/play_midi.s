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
	ble $a3, $t0, play_note_exec

	# clamp at 127
	add $a3, $t0, $zero
play_note_exec:
	add $t1, $a2, $zero
	add $t2, $a3, $zero
	add $t3, $a1, $zero

	add $a1, $t1, $zero
	add $a2, $t2, $zero
	add $a3, $t3, $zero

	li $v0, 33
	syscall
	jr $ra


play_song:

	addi $sp, $sp, -4
	sw $ra, 0($sp)
	jal mem_master
	
	add $t0, $v0, $0
	
	lw $t1, mem_size($0)
		
	sra $t1, $t1, 1 # gets the array size
	
	play_list_of_notes:
		
	beq $t1, $0, exit
		lw $a1, 0($t1) # t4 now contains the first 4 bytes
		lb $a0, 5($t1) # a0 now contains the sixith byte (note)
		lb $a2, 4($t1) 
		andi $a2, $a2, 0x0F # a2 is now the instrument
		lb $a3, 6($t1) # a3 is the velocity

		addi $t0, $t0, 8 # sets t0 to the next note
		
		li $v0, 33
		syscall
		
		addi $t1, $t1, -1
		
		j play_list_of_notes		
	
	exit:
	
	#deallocates the array from mem_master
	jal mem_master_dealloc	
	
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra

	.data
play_song_msg:	.asciiz "TODO: Implement play_song method\n[Press any key to continue]"
