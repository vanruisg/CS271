TITLE Program #6     (main.asm)

; Author: Gerrit Van Ruiswyk
; Last Modified: 12/9/2019
; OSU email address: vanruisg@oregonstate.edu
; Course number/section: 271-400
; Project Number: 6                
; Due Date: 12/8/2019 (one day late- no grace days left)
; Description: The program uses macros to fill an array with 10 integers. The sum and 
; average of the integers are also computed.

INCLUDE Irvine32.inc


; both macros borrowed from lecture slides
getString MACRO memLoc, lenOfStr
	push	edx
	push	ecx

	mov		edx, memLoc
	mov		ecx, lenOfStr
	call	ReadString
	
	pop		ecx
	pop		edx
ENDM

displayString MACRO buffer
	push	edx
	mov		edx, buffer
	call	WriteString
	pop		edx
ENDM


; constant for size of array
MAX_NUM = 10


.data

progname		BYTE		"Demonstrating low-level I/O procedures", 0
author			BYTE		"Written by: Gerrit Van Ruiswyk", 0

instr1			BYTE		"Please provide 10 decimal integers.", 0
instr2			BYTE		"Each number needs to be small enough to fit inside a 32 bit register.", 0
instr3			BYTE		"After you have finished inputting the raw numbers I will display a list", 0
instr4			BYTE		"of the integers, their sum, and their average value.", 0

enterPrompt		BYTE		"Please enter an integer:  ", 0
errorMsg		BYTE		"ERROR: You did not enter an integer number or your number was too big.", 0

dispNums		BYTE		"You entered the following numbers: ", 0
dispSum			BYTE		"The sum of these numbers is:  ", 0
dispAve			BYTE		"The average is:  ", 0

spacer			BYTE		"  ", 0

goodbye			BYTE		"Thanks for playing!", 0

numArray		DWORD		10 DUP(0)
sum				DWORD		0
ave				DWORD		0

inString		BYTE		255 DUP(0)
outString		BYTE		32 DUP(?)


.code
main PROC

	; display instructions to user
	push	OFFSET progname					; 28
	push	OFFSET author					; 24
	push	OFFSET instr1					; 20
	push	OFFSET instr2					; 16
	push	OFFSET instr3					; 12
	push	OFFSET instr4					; 8
	call	Introduction

	; add ten valid numbers to the array
	mov		ecx, MAX_NUM
	mov		edi, OFFSET numArray

	inputLoop:
		; ask user for number
		displayString	OFFSET enterPrompt

		; read in the string that the user enters
		push	OFFSET inString					; 20
		push	SIZEOF inString					; 16
		push	OFFSET errorMsg					; 12
		push	OFFSET enterPrompt				; 8
		call	ReadVal

		; add valid integer to the array
		mov		eax, DWORD PTR inString
		mov		[edi], eax
		; move to next open spot in array
		add		edi, 4
		; keep looping until all ten spots are filled w/ valid numbers
		loop	inputLoop

	; reset ecx to display numbers back to the user
	mov		ecx, MAX_NUM
	mov		esi, OFFSET numArray

	; display message before printing array
	call	Crlf
	displayString	OFFSET dispNums

	displayLoop:
		; print out current value of array
		mov		eax, [esi]
		push	eax								; 12
		push	OFFSET outString				; 8
		call	WriteVal

		; move to next value in array
		add		esi, 4
		; loop until all numbers have been printed
		loop	displayLoop
		call	Crlf

	; calculate and display the sum to the user
	push	OFFSET	sum							; 16
	push	OFFSET	dispSum						; 12
	push	OFFSET	numArray					; 8
	call	CalcSum

	; calculate and display the average to the user
	push	sum									; 12
	push	OFFSET dispAve						; 8
	call	CalcAve

	; say goodbye to the user
	push	OFFSET goodbye						; 8
	call	farewell

	exit	; exit to operating system

main ENDP


;---------------------------------------------------------------------------------------------
; Name: Introduction
; Procedure to display the name, the author, and purpose the program.
; Receives: progname, author, instr1-4
; Returns: program name, author, basic instructions
; Preconditions: program has been initiated
; Registers changed: ebp, edx
;---------------------------------------------------------------------------------------------

Introduction PROC
	
	push	ebp
	mov		ebp, esp

	; print out the name of the program
	displayString	[ebp+28]
	call	Crlf

	; print out the author's name
	displayString	[ebp+24]
	call	Crlf
	call	Crlf

	; print out the first part of the instructions
	displayString	[ebp+20]
	call	Crlf

	; print out the second part of the instructions
	displayString	[ebp+16]
	call	Crlf

	; print out the third part of the instructions
	displayString	[ebp+12]
	call	Crlf

	; print out the fourth part of the instructions
	displayString	[ebp+8]
	call	Crlf
	call	Crlf

	pop		ebp
	ret		24

Introduction ENDP


;---------------------------------------------------------------------------------------------
; Name: readVal
; Procedure to take in user input and validate that it is an integer
; Receives: inString (SIZEOFF and OFFSET)
; Returns: none
; Preconditions: none
; Registers changed: ebp, edx, ecx, esi, ebx, ax
;---------------------------------------------------------------------------------------------

readVal PROC

	push	ebp
	mov		ebp, esp
	pushad

	; start by getting input from user
	beginVal:
		; place address of inString in edx
		mov		edx, [ebp+20]
		; place length of inString in ecx
		mov		ecx, [ebp+16]		
		getString	edx, ecx

		; initialize registers for loop
		mov		esi, edx
		mov		eax, 0
		mov		ebx, MAX_NUM
		mov		ecx, 0

	; validate the string entered by the user, character by character
	valLoop:
		
		lodsb

		; if character is 0, we have reached the end of the string
		cmp		ax, 0
		je		endVal	

		; if character is outside of a to z in ASCII, print error message
		cmp		ax, 48
		jl		invalidNum
		cmp		ax, 57
		jg		invalidNum

		; convert character to digit
		sub		ax, 48
		xchg	eax, ecx
		; multiply by correct power of 10
		mul		ebx
		; if number is too big, print error message
		jc		invalidNum
		jmp		ValidNum

	; prints error message and asks for different input
	invalidNum:
		displayString	[ebp+12]
		call	Crlf
		displayString	[ebp+8]
		jmp		beginVal

	; add digit to total
	validNum:
		add		eax, ecx
		xchg	eax, ecx
		jmp		valLoop

	; place complete integer on stack
	endVal:
		xchg	ecx, eax
		mov		DWORD PTR inString, eax

	popad
	pop		ebp
	ret		16

readVal ENDP


;---------------------------------------------------------------------------------------------
; Name: writeVal
; Procedure to write out the numbers
; Receives: outString, number to print
; Returns: none
; Preconditions: none
; Registers changed: ebp, eax, edi, ebx, edx
;---------------------------------------------------------------------------------------------

writeVal PROC

	push	ebp
	mov		ebp, esp
	pushad

	; access current number to be printed
	mov		eax, [ebp+12]
	; access outString
	mov		edi, [ebp+8]
	; 
	mov		ebx, MAX_NUM
	push	0

	convert:
		mov		edx, 0
		div		ebx
		; convert back to character
		add		edx, 48
		push	edx

		; if you reach 0, then you've reached the end of the string
		cmp		eax, 0
		jne		convert

	addToString:
		; add the current character to the string
		pop		[edi]
		mov		eax, [edi]
		; move to next character
		inc		edi
		; if you reach 0, then you've reached the end of the string
		cmp		eax, 0
		jne		addToString


	; print the resulting string and spacer
	mov		edx, [ebp+8]
	displayString	OFFSET outString
	displayString	OFFSET spacer

	popad
	pop		ebp
	ret		8

WriteVal ENDP


;---------------------------------------------------------------------------------------------
; Name: CalcAve
; Procedure to calculate the average of a list of numbers
; Receives: sum, dispAve
; Returns: A message printing out the average
; Preconditions: none
; Registers changed: ebp, esp, eax, ebx, edx
;---------------------------------------------------------------------------------------------

CalcAve PROC

	push	ebp
	mov		ebp, esp
	pushad

	; print the display message
	displayString	[ebp+8]

	; divide the sum by 10
	mov		eax, [ebp+12]
	mov		ebx, MAX_NUM
	mov		edx, 0
	div		ebx

	; print out the average
	push	eax
	push	OFFSET outString
	call	writeVal
	call	Crlf

	popad
	pop		ebp
	ret		8

CalcAve ENDP


;---------------------------------------------------------------------------------------------
; Name: CalcSum
; Procedure to calculate the sum of the list of numbers
; Receives: dispSum, numArray
; Returns: A message printing out the sum
; Preconditions: none
; Registers changed: ebp, esi, ecx, eax, ebx
;---------------------------------------------------------------------------------------------

CalcSum PROC

	push	ebp
	mov		ebp, esp
	pushad

	; print out the display message
	displayString	[ebp+12]

	; access the array
	mov		esi, [ebp+8]
	; set loop counter to 10
	mov		ecx, MAX_NUM
	; initialize the sum
	mov		eax, 0
	mov		ebx, [ebp+16]

	sumLoop:
		; add num to sum
		add		eax, [esi]
		; move to next num in array
		add		esi, 4
		loop	sumLoop
		; store result of loop
		mov		[ebx], eax

	; print out the actual sum
	push	eax
	push	OFFSET outString
	call	WriteVal
	call	Crlf

	popad
	pop		ebp
	ret		12
	
CalcSum	ENDP

;---------------------------------------------------------------------------------------------
; Name: Farewell
; Procedure to display the ending message of the program
; Receives: goodbyeMsg
; Returns: the send-off to the user before the program ends
; Preconditions: None
; Registers changed: ebp
;---------------------------------------------------------------------------------------------

Farewell PROC
	
	push	ebp
	mov		ebp, esp

	; print out the farewell message
	call			Crlf
	displayString	[ebp+8]
	call			Crlf

	pop		ebp
	ret		4

Farewell ENDP


END main
