	.text
	.globl help

help:
	li $v0, 4
	la $a0, help_msg
	syscall

	li $v0, 12
	syscall

	jr $ra

	.data
help_msg: .asciiz "TODO: Implement help\n[Press any key]"