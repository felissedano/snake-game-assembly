# This MIPS program illustrates an infinite loop where characters
# from the keyboard are read in, one at a time, and simply echo'd to the display


	.data
	
str1:	.asciiz "\nStart entering characters in the MMIO Simulator"

	.text 
	
	.globl echo

	li $v0, 4		# single print statement	
	la $a0, str1
	syscall
	
echo:	jal Read		# reading and writing using MMIO
	add $a0,$v0,$zero	# in an infinite loop
	jal Write
	j echo

Read:  	lui $t0, 0xffff 	# $t0 = 0xffff0000
Loop1:	lw $t1, 0($t0) 		# $t1 = value(0xffff0000)
	andi $t1,$t1,0x0001	# Is Device ready?
	beq $t1,$zero,Loop1	# No: Check again..
	lw $v0, 4($t0) 		# Yes : read data from 0xffff0004
	jr $ra

Write:  lui $t0, 0xffff 	# $t0 = 0xffff0000
Loop2: 	lw $t1, 8($t0) 		# $t1 = value(0xffff0008)
	andi $t1,$t1,0x0001	# Is Device ready?
	beq $t1,$zero,Loop2	# No: check again
	sw $a0, 12($t0) 	# Yes write to device register @ (0xffff000c) 	
	jr $ra
