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


# This method will move the notes into the file_buffer in proper MIDI format
# The length of the track will be stored in track_length when this method returns
mem_master_dump:
    # load array size and address into registers
    lw $t0, mem_size($0)
    lw $t1, mem_loc($0)

    # get the buffer's address
    la $a0, file_buffer

    # a1 will store the previous event's time
    add $a1, $zero, $zero # initialize to 0

    add $a2, $t0, $t1 # store the last address in the array

    # divide array size by 8 to get number of events
    srl $a3, $t0, 3
    addi $t2, $zero, 6
    mul $a3, $a3, $t2 # multiply by 6 to get number of MIDI bytes
    la $t7, track_length
    sw $a3, 0($t7) # store MIDI bytes in track length

    store_midi_loop:

        lw $t2, 0($t1) # load event time into t2
        lw $t3, 4($t1) # load event data into t3

        # convert to delta time
        sub $t2, $t2, $a1
        add $a1, $zero, $t2 # set previous event time to this event's time

        sh $t2, 0($a0) # store event time
        sw $t3, 2($a0) # store event data

        # NOTE: even though we store 8 bytes, we advance 6
        # because the 2 least significant bytes are empty and not used in MIDI
        addi $a0, $a0, 6 # move to next event slot in buffer

        addi $t1, $t1, 8 # move to next event in array


        # while current address is less than last address
        bne $t1, $a2, store_midi_loop



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

    addi $sp, $sp, -4 # push frame onto stack
    sw $s0, 0($sp) # push s0 onto stack
    add $s0, $zero, $v0 # store array address in s0

    la $t0, mem_size
    lw $t0, 0($t0) # load used memory size
    la $t1, mem_loc
    lw $t1, 0($t1) # load array address


    add $t3, $t1, $t0 # move to end of array
    addi $t3, $t3, -8 # get the location of the last event

    # this is a little janky, but it makes my life easier
    addi $t1, $t1, -8 # move to one event worth before the start of the array

    note_loop:

        addi $t1, $t1, 8 # move to next event


        lw $a0, 0($t1) # load start time into a0
        lbu $a1, 4($t1) # load command byte into a1

        srl $a1, $a1, 4 # shift the instrument bits out of the command

        addi $t2, $zero, 9 # note_on command
        beq $a1, $t2, note_on


        # if we haven't reached the last event, loop
        bne $t3, $t1, note_loop

        lw $s0, 0($sp) # pop s0 from stack
        addi $sp, $sp, 4 # pop frame from stack

        jr $ra

        note_on:

            add $t4, $zero, $t1 # store the event address in t4

            lbu $a2, 5($t4) # load the note byte into a2

            find_off:
                addi $t4, $t4, 8 # move to the next event

                lbu $a3, 5($t4) # load note byte into a3

                beq $a3, $a2, found_off

                j find_off

            found_off:
                lw $t5, 0($t4) # load note off time into t5
                lw $t6, 4($t4) # load other event info into t6
                sub $t5, $t5, $a0 # find difference between note_on and note_off

                sw $t5, 0($s0) # store delta in array
                sw $t6, 4($s0) # store other event info in array
                addi $s0, $s0, 8 # move array pointer to next index

                j note_loop
