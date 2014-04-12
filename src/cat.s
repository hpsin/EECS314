	.text
	.globl cat

cat:
	li $v0, 4
	la $a0, cat_msg
	syscall

	li $v0, 12
	syscall
	jr $ra

	.data
cat_msg: .asciiz "TODO: Implement cat\n[Press any key to continue]"