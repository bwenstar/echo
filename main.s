; main.s
; UART0 (0x4000.C000)
; GIPO Port A Pins PA0:1 (0x4000.4000)
; Baud rate 38400
; 8 bits, odd parity, 2 stop bit
; Prescaler /16
; System clock 50Mhz

	THUMB
	AREA 	DATA, ALIGN=2
M	SPACE	4

	ALIGN
	AREA	main, CODE, READONLY, ALIGN=2
	EXPORT	__main
	
GPIO_PORTA_AFSEL_R 	EQU 	0x40004420
GPIO_PORTA_DEN_R 		EQU 	0x4000451C
GPIO_PORTA_PCTL_R 	EQU 	0x4000452C
UART0_DR_R 					EQU 	0x4000C000
UART0_FR_R 					EQU 	0x4000C018
UART0_IBRD_R 				EQU 	0x4000C024
UART0_FBRD_R 				EQU 	0x4000C028
UART0_LCRH_R 				EQU 	0x4000C02C
UART0_CTL_R 				EQU 	0x4000C030
SYSCTL_RCGCUART_R 	EQU 	0x400FE618
SYSCTL_RCGCGPIO_R 	EQU 	0x400FE608
SYSCTL_PRUART_R 		EQU 	0x400FEA18

; Start
__main
	BL initUART		; initialise UART
	BL echo				; Rx and Tx
	
	BL inChar
	BL outChar
		
Spin						; spin loop
	B Spin

; 1 - activate UART0
initUART
	LDR R0, =SYSCTL_RCGCUART_R
	LDR R1, [R0]
	ORR R1, #0x1			; bit 0 is UART0
	STR R1, [R0]
	
; 2 - activate port A (GPIO port clock)
	LDR R0, =SYSCTL_RCGCGPIO_R
	LDR R1, [R0]
	ORR R1, #0x1			; bit 0 is Port A
	STR R1, [R0]
	
; 3 - wait for UART0 to be ready
; UART 0 is bit 0 = 2_00000001 (0x1)
	LDR R0, = SYSCTL_PRUART_R
U0NR	LDR R1, [R0]
	AND R1, #0x1
	CMP R1, #0
	BEQ U0NR
	
; 4- deactivate UART
	LDR R0, =UART0_CTL_R
	LDR R1, [R0]
	BIC R1, #0x01			; URATE=0
	STR R1, [R0]

; 5 - set baud rates (38400)
; BRD = (sysclck/prescaler)/baudrate
;	  	= (50000000/16) / 38400
; 	  = 81.38020833333333
; IBRD=81
; FBRD=round(64*0.38020833333333) = 24
	LDR R0, =UART0_IBRD_R
	MOV R1, #81
	STR R1, [R0]
	
	LDR R0, =UART0_FBRD_R
	MOV R1, #24
	STR R1, [R0]
	
; 6 - set line control (8 bits, odd parity, 2 stop bits)
; WLEN (word length) = 0x3 (pin 6-5)
; STP2 (two stop bit select) = 1 (pin 3)
; EPS (even parity bit select) = 0 (pin 2)
; PEN (parity bit enable) = 1 (pin 1)
	LDR R0, =UART0_LCRH_R
	MOV R1, #2_01101010
	STR R1, [R0]
	
; 7 - enable UART, Rx, Tx, prescaler = 16
; URATE=1, RXE=1, TXE=1, HSE=0 (high speed enable)
	LDR R0, =UART0_CTL_R
	LDR R1, [R0]
	MOV R2, #0x300 			; 2_0011 0000 0000
	ORR R1, R2
	ORR R1, #0x01				; pin 0 - URATEN, 1 = enable
	STR R1, [R0]
	
; 8 - enable GPIO alternate function
	LDR R0, =GPIO_PORTA_AFSEL_R
	LDR R1, [R0]
	ORR R1, #0x03				; pins 0-1 (not controlled by GPIO)
	STR R1, [R0]

; 10 - enable digital I/O
	LDR R0, =GPIO_PORTA_DEN_R
	LDR R1, [R0]
	ORR R1, #0x03				; pins 0-1 enabled
	STR R1, [R0]

; 9 - configure as UART
	LDR R1, =GPIO_PORTA_PCTL_R
	MOV R0, #0x00000011	; Port Mux Control 1 and 0 
	STR R0, [R1]
	
	BX LR
	
inChar 
	LDR R0, =UART0_FR_R
	LDR R2, =UART0_DR_R
checkInChar	LDR R1, [R0]
	AND R1, #0x10			; check bit 4 = 0 (RXFE - data available)
	LSR R1, #4				; shift - 1 0000 to 0001
	CMP R1, #0x1	
	BEQ checkInChar
	LDR R3, [R2]
	CMP R3, #0x1B			; check for ESC value press
	BEQ Spin					; branch to Spin loop if pressed
	STR R3, [R2]
	PUSH {LR}					; save stack register position
	BL delay					; small delay
	POP {LR}
	; BX LR
	b inChar
	
outChar
	LDR R0, =UART0_FR_R
	LDR R2, =UART0_DR_R
checkOutChar LDR R1, [R0]
	AND R1, #0x20			; check bit 5 = 0 (TXFF - ready for data)
	LSR R1, #5				; shift - 10 0000 to 0001
	CMP R1, #0x1
	BNE checkOutChar
	MOV R2, R3
	STR R3, [R2]
	BL delay
	BX LR
	
echo
	LDR R0, =UART0_DR_R
	LDR R1, [R0]
	MOV R1, #0x3E
	STR R1, [R0]
	BX LR
		
delay
	;PUSH {LR, R0} 		; save current values of R0 & LR
	LDR R0, =0x10000 	; R0=SIZE
cntdn SUB R0, #1 		; R0=R0-1 takes 1 cycle
	CMP R0, #0 				; ans=(R0-0) takes 1 cycle
	BNE cntdn 				; if (ans!=0) branch to cntdn takes 2 cycles
	;POP {LR, R0} 		; restore previous R0 & LR
	BX LR 						; return from subroutine
		
	ALIGN
	END
	