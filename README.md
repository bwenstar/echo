
## echo
------------------------------------------------------------------

**Microprocessor**: TIVA TM4C123GXL
**System clock**: 50mhz
**Baud rate**: 38400
8 bits, odd parity, 2 stop bit (8, 0, 1)
Prescaler ÷16

------------------------------------------------------------------
**Function**: 
Recieve input (Rx) from serial connection and transmit back (Tx).  

**Info**:
Basic assembly code written for Keil (IDE-Version: µVision V5.15).
Initialises UART0.  

------------------------------------------------------------------
**Notes**:

Baud Rate Divisor:

BRD = (System Clock / Prescaler) / Baud Rate
	  = (50000000/16) / 38400
 	  = 81.38020833333333
 	  
Integer Baud Rate Divider:
IBRD = 81
 
Fractional Baud Rate Register:
FBRD = Round(64*0.38020833333333) 
     = 24

-------------------------------------------------------------------     
