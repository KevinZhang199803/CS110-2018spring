# CS 61C Spring 2015 Project 1-2 
# parsetools.s

#==============================================================================
#                              Project 1-2 Part 3a
#                              parsetools.s README
#==============================================================================
# Implement hex_to_str() only. Do not modify any other functions.
#==============================================================================

.text	

#------------------------------------------------------------------------------
# function hex_to_str()
#------------------------------------------------------------------------------
# Writes a 32-bit number in hexadecimal format to a string buffer, followed by
# the newline character and the NUL-terminator. The output must contain 8 digits
# so if neccessary put leading 0s in the buffer. Therefore, you should always 
# be writing 10 characters (8 digits, 1 newline, 1 NUL-terminator).
#
# For example:
#  0xabcd1234 => "abcd1234\n\0"
#  0x134565FF => "134565ff\n\0"
#  0x38       => "00000038\n\0"
#
# Write hex letters using lowercase, not uppercase. Do not add the prefix '0x'.
#
# Hint: Consider each group of 4 bits at a time and look at an ASCII table. If 
# you code has more than a few branch statements, you are probably not doing
# things very efficiently.
#
# Arguments:
#  $a0 = int to write
#  $a1 = character buffer to write into
#
# Returns: none
#------------------------------------------------------------------------------

hex_to_str:
	# $t0 -> every 4 bits, #$t1 offset
	# convert to lowercase letter, if $t0 > 9 -> addiu $t0 $t0 97
	# convert to numebr string, else -> addiu $t0 $t0 48
	addi 			$sp, $sp, -4
	sw 				$s6, 0($sp)
	# store the $s6 register
	addi 			$sp, $sp, -4
	sw 				$s7, 0($sp)
	# store the $s7 register
	addi 			$sp, $sp, -16
	sw 				$t2, 0($sp)
	# store the $t2 register
	sw 				$t3, 4($sp)
	# store the $t3 register
	sw 				$t4, 8($sp)
	# store the $t4 register
	sw 				$t5, 12($sp)
	# store the $t5 register

	sb 				$zero, 9($a1)
	# the ninth element in one num is \0, which is 0 in ASCII
	addi 			$t4, $zero, 10

	sb 				$t4, 8($a1)
	# the ninth element in one num is \n, which is 10 in ASCII
	addi 			$t3, $zero, 7
	# $t2 records the bit of the number, in total 8 bits

	hex_conduct:

		blt 		$t3, $zero, hex_exit
		# judge whether we reach the end
		andi 		$t4, $a0, 15
		# $a0 & 15,get the last 4 bits 
		srl 		$a0, $a0, 4
		# shift right for 4 bits, remove the last 4 numbers
		addi 		$s6, $zero, 9
		# 9 = 0111, to judge whether $t4 does not have the first bit
		ble 		$t4, $s6, hex_trans_less_bit
		# If a 4 bit int less than or equal 9 (0111),
		# It means the number in fact has less than 3 bits.
		addi 		$t4, $t4, 87
		# 87 = 97 - 10 ('a' - 10)
		add 		$t5, $a1, $t3
		# add shift to the address (n-th word) 
		sb 			$t4, 0($t5)
		# save the char into destination
		addi 		$t3, $t3, -1
		# deduct one position
		j 			hex_conduct
		# looping

	hex_trans_less_bit:
		addi 		$t4, $t4, 48
		# set the fourth, fifth and sixth bits as 1
		add 		$t5, $a1, $t3
		# add shift to the address (n-th word) 
		sb 			$t4, 0($t5)
		# save the char into destination
		addi 		$t3, $t3, -1
		# deduct one position
		j 			hex_conduct
		# looping

	hex_exit:
		lw 			$t2, 0($sp)
		# save the original $t2 back
		lw 			$t3, 4($sp)
		# save the original $t3 back
		lw 			$t4, 8($sp)
		# save the original $t4 back
		lw 			$t5, 12($sp)
		# save the original $t5 back
		addi 		$sp, $sp, 16
		# set the stack ptr back
		lw 			$s6, 0($sp)
		# save the original $s6 back
		addi 		$sp, $sp, 4
		# set the stack ptr back
		lw 			$s7, 0($sp)
		# save the original $s7 back
		addi 		$sp, $sp, 4
		# set the stack ptr back
		jr 			$ra
		# return to where we are

###############################################################################
#                 DO NOT MODIFY ANYTHING BELOW THIS POINT                       
###############################################################################

#------------------------------------------------------------------------------
# function parse_int() - DO NOT MODIFY THIS FUNCTION
#------------------------------------------------------------------------------
# Parses the string as an unsigned integer. The only bases supported are 10 and
# 16. We will assume that the number is valid, and that overflow does not happen.
#
# Arguments: 
#  $a0 = string containing a number
#  $a1 = base (will be either 10 or 16)
#
# Returns: the number
#------------------------------------------------------------------------------
parse_int:
	li $v0, 0				# Begin parse_int()
	li $t1, 'A'
	li $t2, 'F'
parse_int_loop:
	lb $t0, 0($a0)
	beq $t0, $0, parse_int_done
	mul $v0, $v0, $a1		# multiply by the base
	blt $t0, $t1, parse_int_dec
	ble $t0, $t2, parse_int_hex_upper
	# parse as lowercase hex:
	addiu $t0, $t0, -87		# 'a' - 10
	j parse_int_common
parse_int_dec:
	addiu $t0, $t0, -48		# 0 - '0'
	j parse_int_common
parse_int_hex_upper:
	addiu $t0, $t0, -55		# 'A' - 10
parse_int_common:
	addu $v0, $v0, $t0
	addiu $a0, $a0, 1
	j parse_int_loop
parse_int_done:
	jr $ra				# End parse_int()

#------------------------------------------------------------------------------
# function tokenize() - DO NOT MODIFY THIS FUNCTION
#------------------------------------------------------------------------------
# Converts a line of symbol/relocation table output into a numerical address
# and a name string, which can then be added into the appropriate SymbolList
# after you add the appropriate offset to the addr. Note that this function
# returns TWO values. This is just a shortcut to make the MIPS shorter.
#
# Arguments:
#  $a0 = string containing a line from symbol/relocation table output
#
# Returns: 	$v0: the address of the symbol
#	$v1: name of the string
#------------------------------------------------------------------------------	
tokenize:
	addiu $sp, $sp, -20			# Begin tokenize()
	sw $s0, 16($sp)
	sw $s1, 12($sp)
	sw $s2, 8($sp)
	sw $s3, 4($sp)
	sw $ra, 0($sp)
	move $s0, $a0		# $s0 = start of string
	li $s1, 0			# $s1 = offset from start
	li $s2, 9			# $s2 = tab character
tokenize_loop:
	addu $t0, $s0, $s1
	lb $t1, 0($t0)
	beq $t1, $0, tokenize_fail	
	beq $t1, $s2, tokenize_done
	addiu $s1, $s1, 1
	j tokenize_loop
tokenize_done:
	sb $0, 0($t0)
	li $a1, 10
	jal parse_int		# $v0 = int result
	addu $v1, $s0, $s1
	addiu $v1, $v1, 1		# $v1 = beginning of string
tokenize_fail: # fallthrough (we should never directly jump to here unless input is invalid)
	lw $s0, 16($sp)
	lw $s1, 12($sp)
	lw $s2, 8($sp)
	lw $s3, 4($sp)
	lw $ra, 0($sp)
	addiu $sp, $sp, 20
	jr $ra				# End tokenize()

#------------------------------------------------------------------------------
# function readline() - DO NOT MODIFY THIS FUNCTION
#------------------------------------------------------------------------------
# Reads the next line from the file until a newline or end of file is reached.
# If a newline was reached, the last newline character is discarded. A NUL-
# terminator is added to the end of the string read. 
#
# The buffer is returned in $v1. It is VOLATILE - the next time readline() is
# called, the buffer will be overwritten. This should be fine for most linker
# functions except for the symbol/relocation table (you will have to create a
# copy of the string then -- see add_to_list() in Part 2). 
#
# Arguments:	
#  $a0 = File handle
#
# Returns: 	$v0: the # of bytes read, or -1 if error and nothing was read
#	$v1: pointer to buffer with chars read
#------------------------------------------------------------------------------
readline:	
	la $t0, buffer			# Begin readline()
	li $t1, 512
	la $a1, buffer
	li $a2, 1
readline_next:
	li $v0, 14			# read until a newline is reached
	syscall			
	beq $v0, $0, readline_done	# only end-of-file is left, nothing was read
	blt $v0, $0, readline_err	# error, nothing was read
	lbu $t2, 0($a1)
	li $t3, 0x0a		# newline char
	beq $t2, $t3, readline_done
	addiu $a1, $a1, 1
	subu $t4, $a1, $t0
	bgt $t4, $t1, readline_err2
	j readline_next
readline_done:			# at this point, $v0 contains the # bytes read
	sb $0, 0($a1)
	move $v1, $t0
	jr $ra
readline_err:
	la $a0, readline_err_syscall
	li $v0, 4
	syscall
	li $v0, -1
	jr $ra
readline_err2:
	la $a0, readline_err_bufsize
	li $v0, 4
	syscall
	li $v0, -1
	jr $ra				# End readline()

.data
buffer:	.space 1024
.data
readline_err_syscall:
	.asciiz "Error in readline: Could not read from file.\n"
readline_err_bufsize:
	.asciiz "Error in readline: Exceeded maximum buffer size.\n"
