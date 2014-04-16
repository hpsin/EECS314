    .data
mem_loc: .word 0    # store the starting address of the array
mem_size: .word 0    # store the size of the array
    .text

mem_add:
    # push the return address to the stack
    addi $sp, $zero, -4
    sw $ra, 0($sp)

    jal expand

    # load the record into a0 and a1
    la $t0, MIDI_ON
    lw $a0, 0($t0)
    lw $a1, 4($t0)
    jal addRecord

    # pop the return address from the stack
    lw $ra, 0($sp)
    addi $sp, $zero, 4

expand:
    # expand the array by 1 note (8 bytes)
    li $a0, 8
    li $v0, 9 # sbrk
    syscall

    # check if we need to store the address of the list
    la $t0, mem_loc
    lw $t1, 0($t0)
    bne $t1, $zero, skip_save_addr
    sw $v0, 0($t0)

skip_save_addr:
    # update the size of the array
    la $t0, mem_size
    lw $t1, 0($t0)
    add $t1, $t0, $a0
    sw $t1, 0($t0)
    jr $ra

addRecord:
    # search for the appropriate location to insert the new record
    addi $t0, $zero, 0
    la $t1, mem_loc


    bgt $a0, $t1, foundLocation


    foundLocation:
