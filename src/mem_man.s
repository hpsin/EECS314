    .data
mem_loc: .word 0    # store the starting address of the array
mem_size: .word 0    # store the size of the array
    .text

mem_add:
    # push the return address to the stack
    addi $sp, $sp, -4
    sw $ra, 0($sp)

    # load the record into a0 and a1
    jal expand
    la $t0, MIDI_ON
    lw $a0, 0($t0)
    lw $a1, 4($t0)
    jal addRecord

    jal expand
    la $t0, MIDI_OFF
    lw $a0, 0($t0)
    lw $a1, 4($t0)
    jal addRecord

    # pop the return address from the stack
    lw $ra, 0($sp)
    addi $sp, $sp, 4

    jr $ra

expand:
    # check how much memory we have used
    la $t1, mem_size
    lw $t1, 0($t1)

    addi $a0, $0, 8 # the amount we increase the allocation by
    # expand the array by 1 note (8 bytes)
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
        add $t1, $t1, $a0
        sw $t1, 0($t0)
        jr $ra

addRecord:
    # search for the appropriate location to insert the new record
    la $t0, mem_loc
    la $t1, mem_size
    lw $t0, 0($t0) # get the location of the array
    lw $t2, 0($t1) # get the size of the array

    add $t3, $t0, $0 # location of first note
    beq $t2, $0, insert_note # if no notes, insert at beginning

    add $t3, $t0, $t2 # add number of notes to start location
    addi $t3, $t3, -8 # move back one note

    insert_note:
    sw $a0, 0($t3) # insert record in next slot
    sw $a1, 4($t3)

    jr $ra


# this function will turn the word in a0 into a 7 bit word in v0
mem_seven_bit:
    # convert msb to 7 bit
    sll $t0, $a0, 3
    ori $t0, $t0, 0x80000000
    andi $t0, $t0, 0xFF000000

    # convert 2nd byte to 7 bit
    sll $t1, $a0, 2
    ori $t1, $t1, 0x00800000
    andi $t1, $t1, 0x00FF0000

    # convert 3rd byte to 7 bit
    sll $t2, $a0, 1
    ori $t2, $t2, 0x00008000
    andi $t2, $t2, 0x0000FF00

    # convert lsb to 7 bit
    andi $t3, $a0, 0x0000007F

    add $v0, $0, $0 # clear v0
    or $v0, $v0, $t0
    or $v0, $v0, $t1
    or $v0, $v0, $t2
    or $v0, $v0, $t3

    jr $ra

# this function will turn the 7 bit word in a0 into a 8 bit word in v0
mem_eight_bit:
    andi $t0, $a0, 0x7F
    andi $t1, $a0, 0x7F00
    srl $t1, $t1, 1
    add $t0, $t0, $t1

    andi $t1, $a0, 0x7F0000
    srl $t1, $t1, 2
    add $t0, $t0, $t1

    andi $t1, $a0, 0x7F000000
    srl $t1, $t1, 3
    add $t0, $t0, $t1

    add $v0, $t0, $0

    jr $ra
