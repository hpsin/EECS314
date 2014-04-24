    .data
mem_loc: .word 0    # store the starting address of the array
mem_size: .word 0    # store the size of the array
mem_alloc: .word 0     # store the amount of memory we have allocated
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
    # check how much memory we have allocated
    la $t0, mem_alloc
    lw $t0, 0($t0)
    # check how much memory we have used
    la $t1, mem_size
    lw $t1, 0($t1)

    sub $t2, $t0, $t1 # get the amount of unused allocated memory

    addi $a0, $0, 8 # the amount we increase the allocation by
    bge $t2, $a0, already_allocated
    # expand the array by 1 note (8 bytes)
    li $v0, 9 # sbrk
    syscall

    # get ammound allocated
    la $t0, mem_alloc
    lw $t1, 0($t0)

    add $t1, $t1, $a0 # add the amount we just allocated
    sw $t1, 0($t0) # store it back

    already_allocated:

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


    # findLocation:
    #     addi $t1, $t1, -8 # go back one record
    #     # load the current record in t3 & t5
    #     lw $t3, 0($t1)
    #     lw $t5, 4($t1)
    #
    #     add $t4, $t1, 8 # t4 points to the location to store the record
    #
    #     # if time_new_record > time_current_record
    #     bgt $a0, $t3, foundLocation
    #
    #
    #     # store the current record in the next slot
    #     sw $t3, 0($t4)
    #     sw $t5, 4($t4)
    #
    #     j findLocation
    #
    #



# This method will move the notes into the file_buffer in proper MIDI format
# The length of the track will be stored in track_length when this method returns
mem_master_dump:
    # load array size and address into registers
    la $t0, mem_size
    lw $t0, 0($t0) # get array size
    la $t1, mem_loc
    lw $t1, 0($t1) # get array address


    la $a0, file_buffer # get the buffer's address

    # a1 will store the previous event's time
    add $a1, $zero, $zero # initialize to 0

    add $a2, $t0, $t1 # store the last address in the array

    store_midi_loop:

        lw $t2, 0($t1) # load event time into t2
        lw $t3, 4($t1) # load event data into t3

        # convert to delta time
        sub $t2, $t2, $a1
        add $a1, $zero, $t2 # set previous event time to this event's time


        addi $sp, $sp, -4 # push frame onto stack
        sw $ra, 0($sp) # push return address onto stack
        sw $a0, 4($sp) # push a0 onto stack

        add $a0, $t2, $0 # assign a0 with the event time
        jal mem_seven_bit # convert event time to 7 bit


        add $t2, $v0, $0 # assign t2 with the new event time

        lw $a0, 4($sp) # pop a0 from stack
        lw $ra, 0($sp) # pop return address from stack
        addi $sp, $sp, 4 # pop frame from stack


        sw $t2, 0($a0) # store event time
        sw $t3, 2($a0) # store event data

        addi $a0, $a0, 8 # move to next event slot in buffer

        addi $t1, $t1, 8 # move to next event in array


        # while current address is less than last address
        bne $t1, $a2, store_midi_loop



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
    andi $t3, $a0, 0x000000EF

    add $v0, $0, $0 # clear v0
    or $v0, $v0, $t0
    or $v0, $v0, $t1
    or $v0, $v0, $t2
    or $v0, $v0, $t3

    jr $ra

# this function will turn the 7 bit word in a0 into a 8 bit word in v0
mem_eight_bit:
    andi $t0, $a0, 0xEF
    andi $t1, $a0, 0xEF00
    srl $t1, $t1, 1
    add $t0, $t0, $t1

    andi $t1, $a0, 0xEF0000
    srl $t1, $t1, 2
    add $t0, $t0, $t1

    andi $t1, $a0, 0xEF000000
    srl $t1, $t1, 3
    add $t0, $t0, $t1

    add $v0, $t0, $0

    jr $ra

# This method will create an array of notes that contain the duration of each note
# rather than the start/stop times
# The address of the array will be stored in $v0
mem_master:
    la $t0, mem_size
    lw $t0, 0($t0) # load amount used

    la $t1, mem_alloc
    lw $t2, 0($t1) # load allocated amount

    sub $t3, $t2, $t0 # find difference between allocated and used

    srl $t4, $t0, 1 # divide mem_size by 2 to get new array size

    la $t5, mem_loc
    lw $t5, 0($t5) # get memory address

    add $v0, $t5, $t0 # set new array address to end of currently used

    bge $t3, $t4, enough_free

    addi $v0, $zero, 9 # sbrk syscall
    sub $a0, $t4, $t3 # amount to allocate is (amount we need - amount free)
    syscall

    la $t0, mem_alloc
    lw $t1, 0($t0) # get the amount of memory allocated
    add $t1, $t1, $a0 # increment allocated by the size we just allocated
    sw $t1, 0($t0) # store the amount of allocated memory

    enough_free:

    addi $sp, $sp, -8 # push frame onto stack
    sw $s0, 0($sp) # push s0 onto stack
    sw $ra, 4($sp) # push return address onto stack

    add $s0, $zero, $v0 # store array address in s0

    la $t0, mem_size
    lw $t0, 0($t0) # load used memory size
    la $t1, mem_loc
    lw $t1, 0($t1) # load array address


    add $t3, $t1, $t0 # move to end of array

    note_loop:

        lw $t4, 0($t1) # load event start time
        lw $t5, 4($t1) # load other start event info
        lw $t6, 8($t1) # load event stop time

        sub $t4, $t6, $t4 # convert to duration

        sw $t4, 0($s0) # store event duration
        sw $t5, 4($s0) # store event info

        addi $s0, $s0, 8 # move one event
        addi $t1, $t1, 16 # move 2 events (ON and OFF)

        bne $t1, $t3, note_loop # while we have not reached the end of the array

    lw $ra, 4($sp) # pop return address from stack
    lw $s0, 0($sp) # pop s0 from stack
    addi $sp, $sp, 8 # pop frame from stack

    jr $ra
