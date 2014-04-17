    .data
mem_loc: .word 0    # store the starting address of the array
mem_size: .word 0    # store the size of the array
    .text

mem_add:
    # push the return address to the stack
    addi $sp, $zero, -4
    sw $ra, 0($sp)

    # load the record into a0 and a1
    la $t0, MIDI_ON
    lw $a0, 0($t0)
    lw $a1, 4($t0)
    jal expand
    jal addRecord

    la $t0, MIDI_OFF
    lw $a0, 0($t0)
    lw $a1, 4($t0)
    jal expand
    jal addRecord

    # pop the return address from the stack
    lw $ra, 0($sp)
    addi $sp, $zero, 4

    jr $ra

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
    la $t0, mem_loc
    la $t1, mem_size
    lw $t2, 0($t1) # get the size of the array
    addi $t2, $t2, -8 # the last record
    add $t1, $t0, $t2 # store the location of the last record in t1

    add $t4, $t1, $zero # t4 points to the location to store the record
    beq $t2, $zero, foundLocation # if this is the first record we are inserting

    findLocation:
        addi $t1, $t1, -8 # go back one record
        # load the current record in t3 & t4
        lw $t3, 0($t1)
        lw $t4, 4($t1)

        add $t4, $t1, 8 # t4 points to the location to store the record

        # if time_new_record > time_current_record
        bgt $a0, $t3, foundLocation


        # store the current record in the next slot
        sw $t3, 0($t4)
        sw $t4, 4($t4)

        j findLocation


    foundLocation:
        # insert record in next slot
        sw $a0, 0($t4)
        sw $a1, 4($t4)

        jr $ra
