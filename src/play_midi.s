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
        addi $sp, $sp, -4
        sw $ra, 0($sp)

        jal map_dynamics_to_volume

        lw $ra, 0($sp)
        addi $sp, $sp, 4



play_note_arg2:
	bgt $a2, $zero, play_note_arg2_milli

	# clamp at 1
	li $a2, 1000
	j play_note_arg2

play_note_arg2_milli:
	li $t0, 120
	mult $a2, $t0
	mflo $a2


play_note_arg3:
	bge $a3, $zero, play_note_arg3_max

	# clamp at 0
	add $a3, $zero, $zero
	j play_note_exec
play_note_arg3_max:
	li $t0, 15
	ble $a3, $t0, play_note_exec

	# clamp at 127
	add $a3, $t0, $zero
play_note_exec:
	add $t1, $a2, $zero
        # scale the instrument
        li $t2, 8
        mult $a3, $t2
        mflo $t2
	add $t3, $a1, $zero

	add $a1, $t1, $zero
	add $a2, $t2, $zero
	add $a3, $t3, $zero

	li $v0, 33
	syscall
	jr $ra


play_song:

	la $t0, mem_size
	lw $t0, 0($t0)

	beq $t0, $0, empty_song

	la $t1, mem_loc
	lw $t1, 0($t1)

	addi $sp, $sp, 8 # push frame onto stack
	sw $ra, 0($sp) # push return address onto stack
	sw $s0, 4($sp) # push s0 onto stack

	add $s0, $t0, $t1 # store end of array in s0

	play_list_of_notes:

		beq $t1, $s0, exit

		# a0 now contains the first 4 bytes (start delta)
		lb $a0, 0($t1)
		sll $a0, $a0, 8

		lb $t2, 1($t1)
		or $a0, $a0, $t2
		sll $a0, $a0, 8

		lb $t2, 2($t1)
		or $a0, $a0, $t2
		sll $a0, $a0, 8

		lb $t2, 3($t1)
		or $a0, $a0, $t2

		addi $sp, $sp, -4 # push frame onto stack
		sw $t1, 0($sp) # push t1 onto stack

		jal mem_eight_bit # convert a0 to eight bit bytes

		lw $t1, 0($sp) # pop t1 from stack
		addi $sp, $sp, 4 # pop frame from stack

		add $a1, $v0, $zero # move converted delta to a1

		lb $a2, 4($t1) # a2 now contains command/instrument byte
		andi $a2, $a2, 0x0F # a2 is now the instrument

		lb $a0, 5($t1) # a0 now contains the note byte note
		lb $a3, 7($t1) # a3 now contains the velocity byte

		li $v0, 33
		syscall

		# a0 now contains the first 4 bytes (start delta)
		lb $a0, 8($t1)
		sll $a0, $a0, 8

		lb $t2, 9($t1)
		or $a0, $a0, $t2
		sll $a0, $a0, 8

		lb $t2, 10($t1)
		or $a0, $a0, $t2
		sll $a0, $a0, 8

		lb $t2, 11($t1)
		or $a0, $a0, $t2



		addi $sp, $sp, -4 # push frame onto stack
		sw $t1, 0($sp) # push t1 onto stack

		jal mem_eight_bit # convert a0 to eight bit bytes

		lw $t1, 0($sp) # pop t1 from stack
		addi $sp, $sp, 4 # pop frame from stack

		add $a1, $v0, $zero # move converted delta to a1

		lb $a2, 12($t1) # a2 now contains command/instrument byte
		andi $a2, $a2, 0x0F # a2 is now the instrument

		lb $a0, 13($t1) # a0 now contains the note byte note
		lb $a3, 15($t1) # a3 now contains the velocity byte

		li $v0, 33
		syscall

		addi $t1, $t1, 16 # sets t0 to the next note

		j play_list_of_notes

	exit:

	lw $ra, 0($sp)
	addi $sp, $sp, 4

	empty_song:
	jr $ra

#
map_dynamics_to_volume:
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

map_dynamics_to_volume_end:
    jr $ra

play_note_pp:
	li $a1, 10
	j map_dynamics_to_volume_end

play_note_p:
	li $a1, 32
	j map_dynamics_to_volume_end

play_note_mp:
	li $a1, 52
	j map_dynamics_to_volume_end

play_note_mf:
	li $a1, 73
	j map_dynamics_to_volume_end

play_note_f:
	li $a1, 94
	j map_dynamics_to_volume_end

play_note_ff:
	li $a1, 127
    j map_dynamics_to_volume_end

	.data
play_song_msg:	.asciiz "TODO: Implement play_song method\n[Press any key to continue]"
