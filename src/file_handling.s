	.text
	.globl save_file
	.globl load_file

save_file:
	li $v0, 4
	la $a0 save_file_msg
	syscall

	li $v0, 12
	syscall
	
	jr $ra

load_file:
	li $v0, 4
	la $a0, load_file_msg
	syscall

	li $v0, 12
	syscall
	
	jr $ra

	.data
save_file_msg:	.asciiz "TODO: Implement save file\n [Press any key to continue]"
load_file_msg:	.asciiz "TODO: Implement load file\n [Press any key to continue]"