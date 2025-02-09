.eqv IN_ADDRESS_HEXA_KEYBOARD 0xFFFF0012 # Receive row and column of the key pressed, 0 if not key pressed 
.eqv OUT_ADDRESS_HEXA_KEYBOARD 0xFFFF0014
.eqv LEFT_7SEGMENT_LED 0xFFFF0011
.eqv RIGHT_7SEGMENT_LED 0xFFFF0010
.data
Number: .word 0x3F, 0x06, 0x5B, 0x4F, 0x66, 0x6D, 0x7D, 0x07, 0x7F, 0x6F
NumPad: .word 0x11, 0x21, 0x41, 0x81, 0x12, 0x22, 0x42, 0x82, 0x14, 0x24, 0x44, 0x84, 0x18, 0x28, 0x48, 0x88
NumPadEnd: .word
mess0: .asciz " and "
mess1: .asciz " is: "
addMess: .asciz "The addition of "
subMess: .asciz "The subtraction of "
mulMess: .asciz "The multiplication of "
divMess: .asciz "The division of "
modMess: .asciz "The modulo of "
newline: .asciz "\n"
prompt1: .asciz "\nContinue the calculation....\n"
prompt2: .asciz "\nCan not divide by 0. Reset the calculator.\n"
prompt3: .asciz "\nCan not mod 0. Reset the calculator.\n"
prompt4: .asciz "\nOverflow occurred. Reset the calculator.\n"
.text
init:
	li s0, IN_ADDRESS_HEXA_KEYBOARD
	li s1, OUT_ADDRESS_HEXA_KEYBOARD
	li s2, LEFT_7SEGMENT_LED
	li s3, RIGHT_7SEGMENT_LED
	li s4, 0 #number1 : x1
	li s5, 0 #number2 : x2
	li s7, 0 #check state 
	li s8, 10 # operator: + = 10, - = 11, * = 12, / = 13, % = 14
main:
	#store previous value
	la a1, Number
	lw s6, 0(a1) #start previous led = 0
	sb s6, 0(s2) #default left Led display 0	
	sb s6, 0(s3) #default right Led display 0
enterNumber:
	li t0, 0x01 #check row i (start from row i)
	li t1, 0x10 #if = row 5 then loop again
loop_enter:
	beq t0, t1, reset_row
	sb t0, 0(s0) #reassign each row
	lbu a1, 0(s1) #read enter button
	beq a1, zero, update_loop_enter
	
	la a2, NumPad # a2 = address(Numpad[0])
	la a3, NumPadEnd
	addi a3, a3, -4 # a3 = address(NumPad[n-1])
	li t2, 0 #number clicked	
checkNumPad: #function to find which number was clicked (determined by t2)
	lw t3, 0(a2) #t3 = Numpad[i]
	beq a1, t3, process_key #if button clicked is Numpad[i] then go find which button was clicked
	addi a2, a2, 4
	addi t2, t2, 1	
	j checkNumPad
process_key:
	li t3, 10 #number range
	blt t2, t3, Display_Number #if t2 < 10 then number was clicked
	#else the operator is clicked
	beq t2, t3, addition
	addi t3, t3, 1
	beq t2, t3, subtraction
	addi t3, t3, 1
	beq t2, t3, multiplication
	addi t3, t3, 1
	beq t2, t3, division
	addi t3, t3, 1
	beq t2, t3, modulo
	addi t3, t3, 1
	beq t2, t3, equals
update_loop_enter:
	slli t0, t0, 1 #row i + 1
	j loop_enter
addition:
	li s8, 10 # operator +
	li s7, 1 #change state
	j main
subtraction:
	li s8, 11 #operator -
	li s7, 1 #change state
	j main
multiplication:
	li s8, 12 #operator x
	li s7, 1 #change state
	j main
division:
	li s8, 13 #opearor /
	li s7, 1 #change state
	j main
modulo:
	li s8, 14 #operator %
	li s7, 1 #change state
	j main
equals: #check operator
	li t3, 10
	beq s8, t3, calc_add
	addi t3, t3, 1
	beq s8, t3, calc_sub
	addi t3, t3, 1
	beq s8, t3, calc_mul
	addi t3, t3, 1
	beq s8, t3, calc_div
	addi t3, t3, 1
	beq s8, t3, calc_mod
calc_add:
	add a0, s4, s5
	blt a0, s4, error_overflow #check for overflow
	blt a0, s5, error_overflow #check for overflow
	li a7, 4
	la a0, addMess
	ecall
	li a7, 1
	add a0, zero, s4
	ecall
	li a7, 4
	la a0, mess0
	ecall
	li a7, 1
	add a0, zero, s5
	ecall
	li a7, 4
	la a0, mess1
	ecall
	li a7, 1
	add a0, s4, s5
	ecall
	j next_cal
calc_sub:
	sub a0, s4, s5
	bgt a0, s4, error_overflow #check for overflow
	li a7, 4
	la a0, subMess
	ecall
	li a7, 1
	add a0, zero, s4
	ecall
	li a7, 4
	la a0, mess0
	ecall
	li a7, 1
	add a0, zero, s5
	ecall
	li a7, 4
	la a0, mess1
	ecall
	li a7, 1
	sub a0, s4, s5
	ecall
	j next_cal
calc_mul:
	mul a0, s4, s5
	div t3, a0, s5
	bne t3, s4, error_overflow #check for overflow
	li a7, 4
	la a0, mulMess
	ecall
	li a7, 1
	add a0, zero, s4
	ecall
	li a7, 4
	la a0, mess0
	ecall
	li a7, 1
	add a0, zero, s5
	ecall
	li a7, 4
	la a0, mess1
	ecall
	li a7, 1
	mul a0, s4, s5
	ecall
	j next_cal
calc_div:
	beq s5, zero, error_division
	li a7, 4
	la a0, divMess
	ecall
	li a7, 1
	add a0, zero, s4
	ecall
	li a7, 4
	la a0, mess0
	ecall
	li a7, 1
	add a0, zero, s5
	ecall
	li a7, 4
	la a0, mess1
	ecall
	li a7, 1
	div a0, s4, s5
	ecall
	j next_cal
calc_mod:
	beq s5, zero, error_modulo
	li a7, 4
	la a0, modMess
	ecall
	li a7, 1
	add a0, zero, s4
	ecall
	li a7, 4
	la a0, mess0
	ecall
	li a7, 1
	add a0, zero, s5
	ecall
	li a7, 4
	la a0, mess1
	ecall
	li a7, 1
	rem a0, s4, s5
	ecall
	j next_cal
Display_Number:
	#print number entered on LED
	la a1, Number #a1 = address of Number[0]
	slli t3, t2, 2
	add a1, a1, t3
	lw a2, 0(a1)
	sb a2, 0(s3) #Right Led display the value entered
	sb s6, 0(s2) #Left Led display the previous value entered
	mv s6, a2 #update previous value = value entered
	#update value base on state
	li t3, 10
	beq s7, zero, update_number1 #update the first Number
	j update_number2	#update the second Number
update_number1:
	mul s4, s4, t3	#x1 *= 10
	add s4, s4, t2 #x1 += x (value was entered)
	j sleep
update_number2:
	mul s5, s5, t3 #x2 *= 10
	add s5, s5, t2 #x2 += x (value was entered)
	j sleep
sleep:
	li a0, 100 # sleep 100ms
	li a7, 32
	ecall
reset_row:
	li t0, 0x01
	j loop_enter
next_cal:
	mv s4, a0 #update x1 = calculation result 
	li s5, 0 #reset x2 = 0
	li a7, 4
	la a0, prompt1
	ecall
	li s8, 10 #reset operator to default "+"
	j main
#handle case divide or mod by 0
error_handling:
error_division:
	li a7, 4
	la a0, prompt2
	ecall
	j init
error_modulo:
	li a7, 4
	la a0, prompt3
	ecall
	j init
#handle overflow
error_overflow:
	li a7, 4
	la a0, prompt4
	ecall
	j init
