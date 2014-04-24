	.data
file_buffer: .space 100000 #MIDI file to read will not exceed 100K for complex files
midi_header: .byte 0x4d, 0x54, 0x68, 0x64, 0x00, 0x00, 0x00, 0x06, 0x00, 0x00, 0x00, 0x01, 0x01, 0xe0
track_header: .byte 0x4d, 0x54, 0x72, 0x6b
set_tempo: .byte 0x00, 0xff, 0x51, 0x03, 0x07, 0x53, 0x00,0x00, 0xB0, 0x00, 0x00, 0xB1, 0x08, 0x00, 0xB2, 0x10, 0x00, 0xB3, 0x18, 0x00, 0xB4, 0x20, 0x00, 0xB5, 0x28, 0x00, 0xB6, 0x30, 0x00, 0xB7, 0x38, 0x00, 0xB8, 0x40, 0x00, 0xB9, 0x48, 0x00, 0xBA, 0x50, 0x00, 0xBB, 0x58, 0x00, 0xBC, 0x60, 0x00, 0xBD, 0x68, 0x00, 0xBE, 0x70, 0x00, 0xBF, 0x78,0x00, 0xBF, 0x78
error_read_msg: .asciiz "ERROR reading file"
error_open_msg: .asciiz "ERROR opening file"
error_write_midi_header_msg: .asciiz "ERROR writing the midi header"
error_write_track_header_msg: .asciiz "ERROR writing the track header"
error_write_track_length_msg: .asciiz "ERROR writing the track length"
error_write_file_msg: .asciiz "ERROR writing to the file"
error_no_file: .asciiz "ERROR no notes to save to file"
error_set_tempo_msg: .asciiz "ERROR tempo didn't set correctly"

	.text
	.globl save_file
	.globl load_file

save_file:
#Check if the array is 0 before trying to save the file 
 	lw $t0, mem_size($0)
 	la $s0, error_no_file
	beq  $t0, $zero, errorMsg
 	
#Open a file to write with the user inputted filename
	li $v0, 13
	la $a0, filename
	li $a1, 9  #open for writing
	li $a2, 0 #mode ignored
	syscall
	move $s6, $v0
	#error check for open file
	la $s0, error_open_msg
	blt  $v0, $zero, errorMsg

	#write to the now open file

	#write the midi_header
	li $v0, 15
	move $a0, $s6
	la $a1, midi_header
	li $a2, 14 #number of bytes in the midi_header
	syscall
	#error check for writing the midi header
	la $s0, error_write_midi_header_msg
	blt  $v0, $zero, errorMsg

	#write the track_header (minus the length section)
	li $v0, 15
	move $a0, $s6
	la $a1, track_header
	li $a2, 4 #number of bytes in the midi_header
	syscall
	#error check for writing the track header
	la $s0, error_write_track_header_msg
	blt  $v0, $zero, errorMsg

	#write the track_header length section
	li $v0, 15
	move $a0, $s6
	la $a1, mem_size
	li $a2, 4 #number of bytes in the midi_header
	syscall
	#error check for writing the track length
	la $s0, error_write_track_length_msg
	blt  $v0, $zero, errorMsg

	#write the set_tempo section
	li $v0, 15
	move $a0, $s6
	la $a1, set_tempo
	li $a2, 58 #number of bytes in the midi_header
	syscall
	#error check for writing the track length
	la $s0, error_set_tempo_msg
	blt  $v0, $zero, errorMsg

	#write the fileBuffer to the file
	li $v0, 15
	move $a0, $s6
	la $a1, mem_loc
	la $t0, mem_size
	lw $a2, 0($t0) #load the length of the track to be written
	syscall
	#error check for writing the file
	la $s0, error_write_file_msg
	blt  $v0, $zero, errorMsg

	# Close the file 
  	li   $v0, 16       # system call for close file
  	move $a0, $s6      # file descriptor to close
  	syscall            # close file
	
	jr $ra

load_file:

	#Open a file to read with the user inputted filename
	li $v0, 13
	la $a0, filename
	add $a1, $zero, $zero #opened for read
	add $a2, $zero, $zero #mode ignored
	syscall
	#error check for open file
	la $s0, error_open_msg
	blt  $v0, $zero, errorMsg
	
	#Read from the file just opened
	add $a0, $zero, $v0
	li $v0, 14
	la $a1, file_buffer
	add $a2, $zero, 100000 #maximum size of file 
	syscall

	#Error check for read file
	la $s0, error_read_msg
	blt  $v0, $zero, errorMsg

	sb $zero, file_buffer($v0) #null terminates the fiie

	#gets the length of the track
	li $t0, 18
	lhu $t0, file_buffer($t0)
	li $t1, 20
	lhu $t1, file_buffer($t1)
	sll $t0, $t0, 16
	or $t0, $t1, $t0
	addi $t0, $t0, -58  #Gets length of track minus the patch headers
	


	#close file after reading it
	li $v0, 16
	la $a0, filename
	syscall	

	#print buffer for testing
	li $v0, 4
	la $a0, file_buffer
	syscall
	
	jr $ra

errorMsg:
	add $a0, $s0, $zero
	li $v0, 4
	syscall
	jr $ra

