# TODO: modify the info below
# Student ID: 260897013
# Name: Felis Sedano Luo
# TODO END
########### COMP 273, Winter 2022, Assignment 4, Question 3 - Snake ###########

# Constant definition. You can use them like using an immediate.
# color definition:
.eqv BLACK	0x00000000
.eqv RED	0x00ff0000
.eqv GREEN	0x0000ff00
.eqv BLUE	0x000000ff
.eqv YELLOW	0x00ffff00
.eqv BROWN	0x00994c00
.eqv GRAY	0x00f0f0f0
.eqv WHITE	0x00ffffff

# tile definition
.eqv EMPTY	BLACK
.eqv SNAKE	WHITE
.eqv FOOD	YELLOW
.eqv RED_PILL	RED
.eqv BLUE_PILL	BLUE
.eqv WALL	BROWN

# Direction definition
.eqv DIR_RIGHT	0
.eqv DIR_DOWN	1
.eqv DIR_LEFT	2
.eqv DIR_UP  3

# game state definition
.eqv STATE_NORMAL	0
.eqv STATE_PAUSE	1
.eqv STATE_RESTART	2
.eqv STATE_EXIT		3

# some constants for buffer
.eqv WIDTH	64
.eqv HEIGHT	32
.eqv DISPLAY_BUFFER_SIZE	0x2000
.eqv SNAKE_BUFFER_SIZE		0x2000

# initial postion of the snake
.eqv INIT_HEAD_X	32
.eqv INIT_HEAD_Y	16
.eqv INIT_TAIL_X	31
.eqv INIT_TAIL_Y	16

# initial length of the snake
.eqv INIT_LENGTH	2

# maximum number of pills
.eqv MAX_NUM_PILLS	10

# TODO: add any constants here you if you need
.eqv IS_RIGHT	100
.eqv IS_DOWN	115
.eqv IS_LEFT	97
.eqv IS_UP	119
.eqv PAUSE	112
.eqv QUIT	113
.eqv RESET	114

# TODO END


.data
displayBuffer:	.space	DISPLAY_BUFFER_SIZE	# 64x32 display buffer. Each pixel takes 4 bytes.
snakeSegment:	.space	SNAKE_BUFFER_SIZE	# Array to store the offsets of the snake segments in the display buffer.
						# E.g., head_offset, 2nd_segment_offset, ..., tail_offset
						# Each offset takes 4 bytes.
snakeLength:	.word	INIT_LENGTH		# length of the snake
headX:		.word	INIT_HEAD_X		# head position x
headY:		.word	INIT_HEAD_Y		# head position y
numPills:	.word	0	# number of pills (red and blue)
direction:	.word	0	# moving direction of the snake head:
				#	0: right
				#	1: down
				#	2: left
				#	3: up
state:		.word	0	# game state:
				#	0: normal
				#	1: pause
				#	2: retstart
				#	3: exit
score:		.word	0	# score in the game. increase by 1 everying time eating a regular food
msgScore:	.asciiz "Score: "
.align 2
timeInterval:	.word   100
incSpeed:	.float 0.833333
decSpeed:	.float 1.25

# TODO: add any variables here you if you need
wallMap:	.asciiz "map.txt"
wallBuffer:	.space 1

# TODO END


.text
main:
	jal initGame

gameLoop:
	li $v0, 32
	lw $a0, timeInterval
	syscall
	
# TODO: objective 1, Handle Keyboard Input using MMIO 
    	lui $t0, 0xffff
    	li $t1, 0x2
    	sw $t1, ($t0)        # set I.E. bit of receiver controller to enable keyboard interrupt

# TODO END
	
	lw $t0, state
	beq $t0, STATE_NORMAL, main.normal
	beq $t0, STATE_PAUSE, main.pause
	beq $t0, STATE_RESTART, main.restart
	j main.exit
main.normal:
	jal updateDisplay	
	j gameLoop
main.pause:
	j gameLoop
main.restart:
	jal initGame
	j gameLoop
main.exit:
	la $a0, msgScore
	li $v0, 4
	syscall
	lw $a0, score
	li $v0, 1
	syscall
	li $v0, 10
	syscall
	
	
# void initGame()
initGame:
	sub $sp, $sp, 4
	sw $ra, ($sp)
	
	la $a0, displayBuffer
	li $a1, DISPLAY_BUFFER_SIZE
	jal clearBuffer
	
	jal initMap
	
	# initialize variables
	li $t0, INIT_LENGTH
	sw $t0, snakeLength
	li $t0, INIT_HEAD_X
	sw $t0, headX
	li $t0, INIT_HEAD_Y
	sw $t0, headY
	li $t0, DIR_RIGHT
	sw $t0, direction
		
	li $a0, INIT_HEAD_X
	li $a1, INIT_HEAD_Y
	jal pos2offset
	li $t0, SNAKE
	sw $t0, displayBuffer($v0)	# draw head pixel
	sw $v0, snakeSegment		# head offset

	li $a0, INIT_TAIL_X
	li $a1, INIT_TAIL_Y
	jal pos2offset
	li $t0, SNAKE
	sw $t0, displayBuffer($v0)	# draw tail pixel
	sw $v0, snakeSegment+4		# tail offset
	
	sw $zero, numPills
	li $t0, STATE_NORMAL
	sw $t0, state
	sw $zero, score
	
	# set seed for corresponding pseudorandom number generator using system time
	li $v0, 30
	syscall
	move $a1, $a0
	li $a0, 0	# ID = zero
	li $v0, 40
	syscall	
	
	# spawn food
	jal spawnFood

	lw $ra, ($sp)
	add $sp, $sp, 4	
	jr $ra
	
	
# void updateDisplay()
updateDisplay:
	sub $sp, $sp, 8
	sw $ra, ($sp)
	sw $s0, 4($sp)
	
	lw $a0, headX
	lw $a1, headY
	lw $t0, direction
	beq $t0, DIR_RIGHT, updateDisplay.goRight
	beq $t0, DIR_DOWN, updateDisplay.goDown
	beq $t0, DIR_LEFT, updateDisplay.goLeft
	beq $t0, DIR_UP, updateDisplay.goUp
updateDisplay.goRight:
	add $a0, $a0, 1
	blt $a0, WIDTH, updateDisplay.headUpdateDone
	sub $a0, $a0, WIDTH	# wrap over if exceeds boundary
	j updateDisplay.headUpdateDone
updateDisplay.goDown:
	add $a1, $a1, 1
	blt $a1, HEIGHT, updateDisplay.headUpdateDone
	sub $a1, $a1, HEIGHT	# wrap over if exceeds boundary
	j updateDisplay.headUpdateDone
updateDisplay.goLeft:
	sub $a0, $a0, 1
	bge $a0, 0, updateDisplay.headUpdateDone
	add $a0, $a0, WIDTH	# wrap over if exceeds boundary
	j updateDisplay.headUpdateDone
updateDisplay.goUp:
	sub $a1, $a1, 1
	bge $a1, 0, updateDisplay.headUpdateDone
	add $a1, $a1, HEIGHT	# wrap over if exceeds boundary
	j updateDisplay.headUpdateDone
updateDisplay.headUpdateDone:
	sw $a0, headX
	sw $a1, headY
	jal pos2offset
	move $s0, $v0		# store the head offset because we need it later

	lw $t0, displayBuffer($s0) # what is in the next posion of head?
	beq $t0, EMPTY, updateDisplay.empty
	beq $t0, FOOD, updateDisplay.food
	beq $t0, RED_PILL, updateDisplay.redPill
	beq $t0, BLUE_PILL, updateDisplay.bluePill
	# else hit into bad thing
	li $t0, STATE_EXIT
	sw $t0, state
	j updateDisplay.ObjectDetectionDone
	
updateDisplay.empty:	# nothing
	li $t0, SNAKE
	sw $t0, displayBuffer($s0)	# draw head pixel
	
	# erase old tail in display (set color to black)
	lw $t0, snakeLength
	sub $t0, $t0, 1
	sll $t0, $t0, 2
	lw $t1, snakeSegment($t0)	# load the tail offset
	li $t2, EMPTY
	sw $t2, displayBuffer($t1)
	
	j updateDisplay.ObjectDetectionDone
	
updateDisplay.food:	#regular food
	li $t0, SNAKE
	sw $t0, displayBuffer($s0)	# draw head pixel
	lw $t0, snakeLength
	add $t0, $t0, 1
	sw $t0, snakeLength	# increase snake length
	
	jal spawnFood
	lw $t0, score
	add $t0, $t0, 1
	sw $t0, score
	
	j updateDisplay.ObjectDetectionDone
	
updateDisplay.redPill:
	li $t0, SNAKE
	sw $t0, displayBuffer($s0)	# draw head pixel
	
	# erase old tail in display (set color to black)
	lw $t0, snakeLength
	sub $t0, $t0, 1
	sll $t0, $t0, 2
	lw $t1, snakeSegment($t0)	# load the tail offset
	li $t2, EMPTY
	sw $t2, displayBuffer($t1)
	
	lw $t0, numPills
	sub $t0, $t0, 1
	sw $t0, numPills
	
	# increase game speed
	lw $t0, timeInterval
	mtc1 $t0, $f0
	cvt.s.w $f0, $f0
	l.s $f1, incSpeed
	mul.s $f0, $f0, $f1
	cvt.w.s $f0, $f0
	mfc1 $t0, $f0
	sw $t0, timeInterval
	
	j updateDisplay.ObjectDetectionDone
	
updateDisplay.bluePill:
	li $t0, SNAKE
	sw $t0, displayBuffer($s0)	# draw head pixel
	
	# erase old tail in display (set color to black)
	lw $t0, snakeLength
	sub $t0, $t0, 1
	sll $t0, $t0, 2
	lw $t1, snakeSegment($t0)	# load the tail offset
	li $t2, EMPTY
	sw $t2, displayBuffer($t1)
	
	lw $t0, numPills
	sub $t0, $t0, 1
	sw $t0, numPills
	
	# decrease game speed
	lw $t0, timeInterval
	mtc1 $t0, $f0
	cvt.s.w $f0, $f0
	l.s $f1, decSpeed
	mul.s $f0, $f0, $f1
	cvt.w.s $f0, $f0
	mfc1 $t0, $f0
	sw $t0, timeInterval
	
	j updateDisplay.ObjectDetectionDone

updateDisplay.ObjectDetectionDone:
	
	
	# update snake segments
	# for i = length-1 to 1
	#	snakeSegment[i] = snakeSegment[i-1]
	# snakeSegment[0] = new head position (stored in $s0)
	lw $t0, snakeLength	# index i
updateDisplay.snakeUpdateLoop:
	sub $t0, $t0, 1
	blt $t0, 1, updateDisplay.snakeUpdateLoopDone
	sll $t1, $t0, 2		# convert index to offset
	sub $t2, $t1, 4		# offset of previous segment
	lw $t4, snakeSegment($t2)
	sw $t4, snakeSegment($t1) # snakeSegment[i] = snakeSegment[i-1]
	j updateDisplay.snakeUpdateLoop
updateDisplay.snakeUpdateLoopDone:
	sw $s0, snakeSegment	# update head offset in snakeSegment
	
	lw $ra, ($sp)
	lw $s0, 4($sp)
	add $sp, $sp, 8
	jr $ra
	

# int pos2offset(int x, int y)
# offset = (y * WIDTH + x) * 4
# Note that each pixel takes 4 bytes!
pos2offset:
	mul $v0, $a1, WIDTH
	add $v0, $v0, $a0
	sll $v0, $v0, 2
	jr $ra


# void spawnFood()
spawnFood:
	sub $sp, $sp, 4
	sw $ra, ($sp)
	
	# spawn regular food (yellow)
spawnFood.regular:
	li $a0, WIDTH	# range: 0 <= x < WIDTH
	jal randInt
	move $t0, $v0,	# position x
	li $a0, HEIGHT	# range: 0 <= y < HEIGHT
	jal randInt
	move $t1, $v0,	# position y
	move $a0, $t0
	move $a1, $t1
	jal pos2offset
	lw $t0, displayBuffer($v0)		# get "thing" on (x, y)
	bne $t0, EMPTY, spawnFood.regular	# find another place if it is not empty
	li $t0 FOOD
	sw $t0, displayBuffer($v0)	# put the food
	
# TODO: objective 2, Spawn Pills
# see spawnFood.regular for example
spawnFood.redCheck:
	lw $t9, numPills	# get how many pills exist now
	bge $t9, MAX_NUM_PILLS, spawnFood.pillFinish	# if reaches max num of pills, do not spawn pill
	li $a0, 100	# get number between 0 and 100
	jal randInt
	move $t0, $v0
	bge $a0, 20, spawnFood.blueCheck	# if the number is greater than 20, then do not spawn red pill
spawnFood.redSpawn:	
	li $a0, WIDTH	# range: 0 <= x < WIDTH
	jal randInt
	move $t0, $v0,	# position x
	li $a0, HEIGHT	# range: 0 <= y < HEIGHT
	jal randInt
	move $t1, $v0,	# position y
	move $a0, $t0
	move $a1, $t1
	jal pos2offset
	lw $t0, displayBuffer($v0)		# get "thing" on (x, y)
	bne $t0, EMPTY, spawnFood.redSpawn	# find another place if it is not empty
	li $t0 RED_PILL
	sw $t0, displayBuffer($v0)	# put the food
	addi $t9, $t9, 1	#increase number of current pills
	sw $t9, numPills
	
spawnFood.blueCheck:
	lw $t9, numPills	# get how many pills exist now
	bge $t9, MAX_NUM_PILLS, spawnFood.pillFinish	# if reaches max num of pills, do not spawn pill
	li $a0, 100	# get number between 0 and 100
	jal randInt
	move $t0, $v0
	bge $a0, 15, spawnFood.pillFinish	# if the number is greater than 15, then do not spawn red pill
spawnFood.blueSpawn:	
	li $a0, WIDTH	# range: 0 <= x < WIDTH
	jal randInt
	move $t0, $v0,	# position x
	li $a0, HEIGHT	# range: 0 <= y < HEIGHT
	jal randInt
	move $t1, $v0,	# position y
	move $a0, $t0
	move $a1, $t1
	jal pos2offset
	lw $t0, displayBuffer($v0)		# get "thing" on (x, y)
	bne $t0, EMPTY, spawnFood.blueSpawn	# find another place if it is not empty
	li $t0 BLUE_PILL
	sw $t0, displayBuffer($v0)	# put the food
	addi $t9, $t9, 1
	sw $t9, numPills

spawnFood.pillFinish:

# TODO END
	
	lw $ra, ($sp)
	add $sp, $sp, 4
	jr $ra


# void clearBuffer(char* buffer, int size)
clearBuffer:
	li $t0, 0
clearBuffer.loop:
	bge $t0, $a1, clearBuffer.return
	add $t1, $a0, $t0
	sb $zero, ($t1)
	add $t0, $t0, 1
	j clearBuffer.loop
clearBuffer.return:
	jr $ra


# int randInt(int max)
# generate an random integer n where 0 <= n < max
randInt:
	move $a1, $a0
	li $a0, 0
	li $v0, 42
	syscall
	move $v0, $a0
	jr $ra
	
# void initMap()
initMap:
# TODO: objective 3, Add Walls
# load the map file you create and add wall to displayBuffer

	addi $sp, $sp, -4
	sw $ra, 0($sp)	
	
	la $a0, wallMap	# load wallmap buffer to store pixel byte
getMap1:
	# open and read file to a buffer and determine the row and collunm count
	li   $v0, 13       
	li   $a1, 0        
	li   $a2, 0
	syscall           
	move $a0, $v0      # save the file descriptor 
	

	li $s1, 0	# x counter
	li $s2, 0	# y counter
	
	# this is a loop to get number of collums
getMap2:
	li  $v0, 14     
	la $a1, wallBuffer 
	move $a0, $a0    
	li  $a2, 1     	
	syscall
	
	beq $v0, $0, getMapDone # if done reading
	
	lb $t0, 0($a1)
	beq $t0, 10, getMap4	#if new line charcter, reset counter and go to the next row
	
	bne $t0, 49, getMap3	#if the data is not ascii "1" then its not a wall, just ignore it
	
	addi $sp, $sp, -8
	sw $a0, 0($sp)	# store file descriptor
	sw $a1, 4($sp)	# store buffer location
	move $a0, $s1	# move x and y value to a0 and a1
	move $a1, $s2
	jal pos2offset	
	li $t0, WALL
	sw $t0, displayBuffer($v0)	# draw wall pixel	
	lw $a0, 0($sp)	#restore variables
	lw $a1, 4($sp)
	addi $sp, $sp, 8

getMap3:	
	addi $s1, $s1, 1	# x counter increase
	j getMap2	# continue to read next pixel
	
getMap4:
	li $s1, 0	# reset x
	addi $s2, $s2, 1	# increase y
	j getMap2	# continue the loop
		
getMapDone:
	# close file and return 
	li $v0, 16
	move $a0, $a0
	syscall
	
	lw $ra, 0($sp)
	addi $sp, $sp, 4
# TODO END
	jr $ra
	
# TODO: add any helper functions here you if you need
.ktext    0x80000180        # interrupt/exception handling code must start from 0x80000180 in kernel space
    	la $k0, kbuffer
   	sw $a0, 0($k0)
    	sw $v0, 4($k0)        # must save the user mode registers if we are gonna change the values
    	mfc0 $k1, $13        # get value in the cause register
    	and $a0, $k1, 0x7c
    	bne $a0, $zero, kexit    # bits 2-6 of cause register tells the cause of the interrupt. "0" means a hardware interrupt.
    	and $a0, $k1, 0x100
    	beq $a0, $zero, kexit    # if bit 8 is 1, the interrupt comes from the keyboard
    	lui $k1, 0xffff
    	lw $a0, 4($k1)	# get ascii data of from the keyboard
	
	# find the corresponding state depending on the input key
    	beq $a0, PAUSE, kreadPause	
	beq $a0, QUIT, kreadQuit
	beq $a0, RESET, kreadReset
	
	beq $a0, IS_RIGHT, kreadRight
	beq $a0, IS_DOWN, kreadDown
	beq $a0, IS_LEFT, kreadLeft
	beq $a0, IS_UP, kreadUp
	j kexit
kreadPause:
	lw $k1, state
	beq $k1, STATE_PAUSE, kreadUnpause
	li $k1, STATE_PAUSE
	sw $k1, state
	j kexit
kreadUnpause:
	li $k1, STATE_NORMAL
	sw $k1, state
	j kexit
kreadQuit:
	li $k1, STATE_EXIT
	sw $k1, state
	j kexit
kreadReset:
	li $k1, STATE_RESTART
	sw $k1, state
	j kexit
	
kreadRight:
	lw $k1, state
	beq $k1, STATE_PAUSE, kexit	# if game paused, no change
	lw $k1, direction
	beq $k1, DIR_LEFT, kexit	# if going opposite dir, no change
	beq $k1, DIR_RIGHT, kexit	# if going same dir, no change
	
	li $k1, DIR_RIGHT
	sw $k1, direction
	j kexit
kreadDown:
	lw $k1, state
	beq $k1, STATE_PAUSE, kexit	# if game paused, no change
	lw $k1, direction
	beq $k1, DIR_UP, kexit
	beq $k1, DIR_DOWN, kexit
	
	li $k1, DIR_DOWN
	sw $k1, direction
	j kexit
kreadLeft:
	lw $k1, state
	beq $k1, STATE_PAUSE, kexit	# if game paused, no change
	lw $k1, direction
	beq $k1, DIR_RIGHT, kexit
	beq $k1, DIR_LEFT, kexit
	
	li $k1, DIR_LEFT
	sw $k1, direction
	j kexit
kreadUp:
	lw $k1, state
	beq $k1, STATE_PAUSE, kexit	# if game paused, no change
	lw $k1, direction
	beq $k1, DIR_DOWN, kexit
	beq $k1, DIR_UP, kexit
	
	li $k1, DIR_UP
	sw $k1, direction
	j kexit
	
kexit:
    	lw $a0, 0($k0)
    	lw $v0, 4($k0)        # remember to restore registers!
    	mfc0 $k1, $12
    	ori $k1, 0x1
    	mtc0 $k1, $12        # set bit 0 of the state register to allow interrupt (it's automatically unset when entering the interrupt handling code
    	eret
   
    
.kdata
kbuffer: .space 0x2000    # data segment in kernel space to store used registers


# TODO END
