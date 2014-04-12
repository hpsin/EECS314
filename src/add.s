	.text
	.globl add_note
	.globl add_rest

add_note:
	li $v0, 4
	la $a0, add_note_msg
	syscall

	li $v0, 12
	syscall

	jr $ra

add_rest:
	li $v0, 4
	la $a0, add_rest_msg
	syscall

	li $v0, 12
	syscall

	jr $ra

	.data
add_note_msg:	.asciiz "TODO: Implement add_note_msg\n[Press any key]"
add_rest_msg:	.asciiz "TODO: Implement add_rest_msg\n[Press any key]"