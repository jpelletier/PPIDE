;TAB=4
;=============================================================================
;   PPIDE DISK DRIVER
;=============================================================================
; THE CONTROL PORT OF THE 8255 IS PROGRAMMED AS NEEDED TO READ OR WRITE
; DATA ON THE IDE BUS.	PORT C OF THE 8255 IS ALWAYS IN OUTPUT MODE BECAUSE
; IT IS DRIVING THE ADDRESS BUS AND CONTROL SIGNALS.  PORTS A & B WILL BE
; PLACED IN READ OR WRITE MODE DEPENDING ON THE DIRECTION OF THE DATA BUS.
;
PPIDE_DIR_READ	= 92h	; IDE BUS DATA INPUT MODE
PPIDE_DIR_WRITE	= 80h	; IDE BUS DATA OUTPUT MODE
PPIDE_CTL_RESET	= 80h	; DRIVE RESET (ACTIVE LOW,INVERTED)

;CTL_IDLE	= 00h
CTL_BYTE	= 08h
CTL_FEAT	= 09h
CTL_DRHD	= 0Ah
CTL_LBA_LOW	= 0Bh
CTL_LBA_MID	= 0Ch
CTL_LBA_HIG	= 0Dh
CTL_MAS_LBA	= 0Eh
CTL_CMD		= 0Fh

CTL_PRELOAD = 08h
CTL_ERROR   = 09h
CTL_STATUS	= 0Fh

;	+-----------------------------------------------------------------------+
;	| CONTROL BLOCK REGISTERS (CS3FX)										|
;	+-----------------------+-------+-------+-------------------------------+
;	| REGISTER		| PORT	| DIR	| DESCRIPTION							|
;	+-----------------------+-------+-------+-------------------------------+
;	| PPIDE_REG_ALTSTAT	| 0x06	| R	| ALTERNATE STATUS REGISTER				|
;	| PPIDE_REG_CTRL	| 0x06	| W	| DEVICE CONTROL REGISTER				|
;	| PPIDE_REG_DRVADR	| 0x07	| R	| DRIVE ADDRESS REGISTER				|
;	+-----------------------+-------+-------+-------------------------------+
;
;	+-----------------------+-------+-------+-------------------------------+
;	| COMMAND BLOCK REGISTERS (CS1FX)										|
;	+-----------------------+-------+-------+-------------------------------+
;	| REGISTER		| PORT	| DIR	| DESCRIPTION							|
;	+-----------------------+-------+-------+-------------------------------+
;	| PPIDE_REG_DATA		| 0x00	| R/W	| DATA INPUT/OUTPUT				|
;	| PPIDE_REG_ERR			| 0x01	| R		| ERROR REGISTER				|
;	| PPIDE_REG_FEAT		| 0x01	| W		| FEATURES REGISTER				|
;	| PPIDE_REG_COUNT		| 0x02	| R/W	| SECTOR COUNT REGISTER			|
;	| PPIDE_REG_SECT		| 0x03	| R/W	| SECTOR NUMBER REGISTER		|
;	| PPIDE_REG_CYLLO		| 0x04	| R/W	| CYLINDER NUM REGISTER (LSB)	|
;	| PPIDE_REG_CYLHI		| 0x05	| R/W	| CYLINDER NUM REGISTER (MSB)	|
;	| PPIDE_REG_DRVHD		| 0x06	| R/W	| DRIVE/HEAD REGISTER			|
;	| PPIDE_REG_LBA0*		| 0x03	| R/W	| LBA BYTE 0 (BITS 0-7)			|
;	| PPIDE_REG_LBA1*		| 0x04	| R/W	| LBA BYTE 1 (BITS 8-15)		|
;	| PPIDE_REG_LBA2*		| 0x05	| R/W	| LBA BYTE 2 (BITS 16-23)		|
;	| PPIDE_REG_LBA3*		| 0x06	| R/W	| LBA BYTE 3 (BITS 24-27)		|
;	| PPIDE_REG_STAT		| 0x07	| R		| STATUS REGISTER				|
;	| PPIDE_REG_CMD			| 0x07	| W		| COMMAND REGISTER (EXECUTE)	|
;	+-----------------------+-------+-------+-------------------------------+
;	* LBA0-3 ARE ALTERNATE DEFINITIONS OF SECT,CYL,AND DRVHD PORTS
;
;	=== STATUS REGISTER ===
;
;	    7	    6	    5	    4	    3	    2	    1	    0
;	+-------+-------+-------+-------+-------+-------+-------+-------+
;	|  BSY	| DRDY	|  DWF	|  DSC	|  DRQ	| CORR	|  IDX	|  ERR	|
;	+-------+-------+-------+-------+-------+-------+-------+-------+
;
;	BSY:	BUSY
;	DRDY:	DRIVE READY
;	DWF:	DRIVE WRITE FAULT
;	DSC:	DRIVE SEEK COMPLETE
;	DRQ:	DATA REQUEST
;	CORR:	CORRECTED DATA
;	IDX:	INDEX
;	ERR:	ERROR
;
;	=== ERROR REGISTER ===
;
;	    7	    6	    5	    4	    3	    2	    1	    0
;	+-------+-------+-------+-------+-------+-------+-------+-------+
;	| BBK	|  UNC	|  MC	|  IDNF |  MCR	| ABRT	| TK0NF |  AMNF |
;	+-------+-------+-------+-------+-------+-------+-------+-------+
;	(VALID WHEN ERR BIT IS SET IN STATUS REGISTER)
;
;	BBK:	BAD BLOCK DETECTED
;	UNC:	UNCORRECTABLE DATA ERROR
;	MC:	MEDIA CHANGED
;	IDNF:	ID NOT FOUND
;	MCR:	MEDIA CHANGE REQUESTED
;	ABRT:	ABORTED COMMAND
;	TK0NF:	TRACK 0 NOT FOUND
;	AMNF:	ADDRESS MARK NOT FOUND
;
;	=== DRIVE/HEAD / LBA3 REGISTER ===
;
;	    7	    6	    5	    4	    3	    2	    1	    0
;	+-------+-------+-------+-------+-------+-------+-------+-------+
;	|   1	|   L	|   1	|  DRV	|  HS3	|  HS2	|  HS1	|  HS0	|
;	+-------+-------+-------+-------+-------+-------+-------+-------+
;
;	L:	0 = CHS ADDRESSING,1 = LBA ADDRESSING
;	DRV:	0 = DRIVE 0 (PRIMARY) SELECTED,1 = DRIVE 1 (SLAVE) SELECTED
;	HS:	CHS = HEAD ADDRESS (0-15),LBA = BITS 24-27 OF LBA
;
;	=== DEVICE CONTROL REGISTER ===
;
;	    7	    6	    5	    4	    3	    2	    1	    0
;	+-------+-------+-------+-------+-------+-------+-------+-------+
;	|   X	|   X	|   X	|   X	|   1	| SRST	|  ~IEN |   0	|
;	+-------+-------+-------+-------+-------+-------+-------+-------+
;
;	SRST:	SOFTWARE RESET
;	~IEN:	INTERRUPT ENABLE
;
; CONTROL VALUES TO USE WHEN ACCESSING THE VARIOUS IDE DEVICE REGISTERS
;
;PPIDE_REG_DATA		=	PPIDE_CTL_CS1 | 00h	; DATA INPUT/OUTPUT (R/W)
;PPIDE_REG_ERR		=	PPIDE_CTL_CS1 | 01h	; ERROR REGISTER (R)
;PPIDE_REG_FEAT		=	PPIDE_CTL_CS1 | 01h	; FEATURES REGISTER (W)
;PPIDE_REG_COUNT		=	PPIDE_CTL_CS1 | 02h	; SECTOR COUNT REGISTER (R/W)
;PPIDE_REG_SECT		=	PPIDE_CTL_CS1 | 03h	; SECTOR NUMBER REGISTER (R/W)
;PPIDE_REG_CYLLO		=	PPIDE_CTL_CS1 | 04h	; CYLINDER NUM REGISTER (LSB) (R/W)
;PPIDE_REG_CYLHI		=	PPIDE_CTL_CS1 | 05h	; CYLINDER NUM REGISTER (MSB) (R/W)
;PPIDE_REG_DRVHD		=	PPIDE_CTL_CS1 | 06h	; DRIVE/HEAD REGISTER (R/W)
;PPIDE_REG_LBA0		=	PPIDE_CTL_CS1 | 03h	; LBA BYTE 0 (BITS 0-7) (R/W)
;PPIDE_REG_LBA1		=	PPIDE_CTL_CS1 | 04h	; LBA BYTE 1 (BITS 8-15) (R/W)
;PPIDE_REG_LBA2		=	PPIDE_CTL_CS1 | 05h	; LBA BYTE 2 (BITS 16-23) (R/W)
;PPIDE_REG_LBA3		=	PPIDE_CTL_CS1 | 06h	; LBA BYTE 3 (BITS 24-27) (R/W)
;PPIDE_REG_BCL		=	PPIDE_CTL_CS1 | 04h	; PKT BYTE COUNT LOW (BITS 0-7) (R/W)
;PPIDE_REG_BCH		=	PPIDE_CTL_CS1 | 05h	; PKT BYTE COUNT HIGH (BITS 8-15) (R/W)
;PPIDE_REG_STAT		=	PPIDE_CTL_CS1 | 07h	; STATUS REGISTER (R)
;PPIDE_REG_CMD		=	PPIDE_CTL_CS1 | 07h	; COMMAND REGISTER (EXECUTE) (W)
;PPIDE_REG_ALTSTAT	=	PPIDE_CTL_CS3 | 06h	; ALTERNATE STATUS REGISTER (R)
;PPIDE_REG_CTRL		=	PPIDE_CTL_CS3 | 06h	; DEVICE CONTROL REGISTER (W)
;PPIDE_REG_DRVADR	=	PPIDE_CTL_CS3 | 07h	; DRIVE ADDRESS REGISTER (R)
;
; COMMAND BYTES
;
PPIDE_CMD_NOP		=	000h
PPIDE_CMD_DEVRES	=	008h
PPIDE_CMD_RECAL		=	010h
PPIDE_CMD_READ		=	020h
PPIDE_CMD_WRITE		=	030h
PPIDE_CMD_DEVDIAG	=	090h
PPIDE_CMD_PACKET	=	0A0h
PPIDE_CMD_IDPKTDEV	=	0A1h
PPIDE_CMD_IDDEV		=	0ECh
PPIDE_CMD_SETFEAT	=	0EFh
;
; FEATURE BYTES
;
PPIDE_FEAT_ENABLE8BIT	=	001h
PPIDE_FEAT_DISABLE8BIT	=	081h
;
; PPIDE DEVICE TYPES
;
PPIDE_TYPEUNK	=	0
PPIDE_TYPEATA	=	1
PPIDE_TYPEATAPI	=	2
;
; PPIDE DEVICE STATUS CODES
;
PPIDE_STOK	=	0
PPIDE_STINVUNIT	=	-1
PPIDE_STNOMEDIA	=	-2
PPIDE_STCMDERR	=	-3
PPIDE_STIOERR	=	-4
PPIDE_STRDYTO	=	-5
PPIDE_STDRQTO	=	-6
PPIDE_STBSYTO	=	-7
PPIDE_STNOTSUP	=	-8
PPIDE_STNOTRDY	=	-9
;
; DRIVE SELECTION BYTES (FOR USE IN DRIVE/HEAD REGISTER)
;
;PPIDE_DRVSEL:
PPIDE_DRVMASTER	= 0E0h	; LBA,MASTER DEVICE
PPIDE_DRVSLAVE	= 0F0h	; LBA,SLAVE DEVICE

; =====================================================================
; PPIDE Port Mapping (Base 0244h)
; =====================================================================
PPIDE_DATALO = 0244h    ; IDE Data Bus (D0-D7)
PPIDE_DATAHI = 0245h    ; IDE Data Bus (D8-D15)
PPIDE_CTL    = 0246h    ; IDE Control Signals
PPIDE_PPI    = 0247h    ; 82C55 Control Register

; =====================================================================
; Port C Control Bitmask Calculations (Inverted Logic)
; Reset=0,IOR=0,IOW=0,CS1=0,CS0=0 mean pins are 5V (Inactive)
; =====================================================================
MSK_CS0 = 08h      ; Pulls /CS0 Active Low (Target Command Block)
MSK_IOW = 20h      ; Pulls /IOW Active Low (Write Strobe)
MSK_IOR = 40h      ; Pulls /IOR Active Low (Read Strobe)

;------------------------------
;## Part 1: Selecting an LBA Sector
;To select a sector,we must write a 28-bit sector address across four 
;internal IDE registers: LBA Low,LBA Mid,LBA High,and Device/Head.
;This routine expects you to pass the 28-bit LBA address via the Z80 
;registers:

;* DE = Lower 16 bits of LBA
;* H = Upper 12 bits of LBA (Bits 0–7)
;* L = Upper 12 bits of LBA (Bits 8–11) — Note: Only bits 0-3 are used
;here,mixed with the Master selection bit 0E0.

; =====================================================================
; ATA Command Set Definitions
; =====================================================================
CMD_SET_FEAT = 0EFh  ; ATA Set Features Command
FEAT_8BIT_ON = 01h   ; Sub-command feature code to enable 8-bit PIO

MDELAYN	MACRO data
		MOV		CX,data
		CALL	delayn
		ENDM

OUT_DX	MACRO port,data
		MOV		AL,data
		MOV		DX,port
		OUT		(DX),AL
		ENDM

IN_DX	MACRO port
		MOV		DX,port
		IN		AL,(DX)
		ENDM

LD_BX	MACRO reg,data
		MOV		BH,reg
		MOV		BL,data
		ENDM

		.MODEL  SMALL, C
		.CODE
;CODE	SEGMENT _TEXT PUBLIC CLASS=CODE USE16 ALIGN=16  #DOESN'T WORK
;CODE    SEGMENT BYTE PUBLIC
;        ASSUME CS:CODE

; 4.77MHz = 4772726 cycles for 1s, 4772 cycles for 1ms
; call			23
; push cx		15
; mov	cx,#n	4
; loop:
; nop			3
; loop			5/17	nj/j
; pop	ax		12
; ret			20

; 23 + 15 + 4 + 12 + 20 + (n-1)(3+17) + 5
; 23 + 15 + 4 + 12 + 20 -20 + 5 + 20n
; 59 + 20n
; 4772 = 59 + 20n
; 4713 = 20n
; n = 235.65
delay1ms:
		PUSH	CX
		MOV  	CX,236
delay_loop:
		NOP
		LOOP	delay_loop
		POP		CX
		RET

PUBLIC	SELMST
SELMST	PROC	NEAR
		LD_BX	CTL_MAS_LBA,PPIDE_DRVMASTER
		; 7. Select Master Drive and Force LBA Mode (Crucial step)
		JMP		writeReg
SELMST	ENDP

PUBLIC	SELPIO8
SELPIO8	PROC	NEAR
		;Force Drive into 8-Bit PIO Transfer Mode via Features Register
		; This ensures the drive doesn't expect data transitions on Port B (D8-D15).
		; Write Feature Code (01h) -> Register 1 (Features)
		LD_BX	CTL_FEAT,FEAT_8BIT_ON
		call    writeReg

		; Issue Set Features Command (EFh) -> Register 7 (Command)
		LD_BX	CTL_CMD,CMD_SET_FEAT
		JMP		writeReg
SELPIO8	ENDP

; 4772.726 = 1ms
; 4.772726 = 1µs
; 238.6363 = 50µs
; 239 = 59 + 20n

initDelay:
		; Hold Reset Active for a short loop (~25-50 microseconds)
		PUSH	CX
		MOV		CX,10
initDelayLoop:
		NOP
		LOOP	initDelayLoop
		POP		CX
		RET

;CMD	AL
;return AL
readPulse:
		MOV		DX,PPIDE_CTL
		OUT		(DX),AL
		OR		AL,MSK_IOR
		OUT		(DX),AL
		MOV		DX,PPIDE_DATALO
		IN      AL,(DX)
		MOV		AH,AL
		XOR		AL,AL
		MOV		DX,PPIDE_CTL
		OUT		(DX),AL
		MOV		AL,AH
		RET

readStatus:
		MOV     AL,CTL_STATUS
		call	readPulse
		MOV     AH,AL
		JP		BUS_IDLE

readData:
		MOV		AL,AL
		CALL	readPulse
		MOV     [DI],AL
		INC     DI
		JP		BUS_IDLE

;DI		*BUFFER
;AH		CMD
readWordData:
		MOV		AL,AH
		MOV		DX,PPIDE_CTL
		OUT		(DX),AL
		OR		AL,MSK_IOR
		OUT		(DX),AL
		MOV		DX,PPIDE_DATALO
		IN      AL,(DX)
		MOV     [DI],AL                	; Save to Z80 RAM
		INC     DI                 		; Point to next RAM location
		MOV		DX,PPIDE_DATAHI
		IN      AL,(DX)
		MOV     [DI],AL                	; Save to Z80 RAM
		INC     DI                 		; Point to next RAM location
BUS_IDLE:
		XOR		AL,AL
		MOV		DX,PPIDE_CTL
		OUT		(DX),AL
		RET

;BH		REG
;BL		DATA
writeReg:
		; 1. Ensure Port A is in Output Mode to transmit the command
		OUT_DX	PPIDE_PPI,PPIDE_DIR_WRITE

		MOV		AL,BL			;DATA
		MOV		DX,PPIDE_DATALO
		OUT		(DX),AL
		MOV     AL,BH
writePulse:
		MOV		DX,PPIDE_CTL
		OUT		(DX),AL			; Assert /CS0
		OR		AL,MSK_IOW
		OUT		(DX),AL			; Assert /IOW Low
		XOR		AL,AL
		OUT		(DX),AL
		RET

writeData:
		MOV		AL,[DI]
		MOV		DX,PPIDE_DATALO
		OUT		DX,AL
		MOV     AL,CTL_BYTE
		CALL	writePulse
		INC     DI
		RET

writeWordData:
		OUT_DX	PPIDE_PPI,PPIDE_DIR_WRITE

		MOV		AL,[DI]
		INC		DI
		MOV		DX,PPIDE_DATALO
		OUT		DX,AL
		MOV		AL,[DI]
		INC     DI
		MOV		DX,PPIDE_DATAHI
		OUT		DX,AL
		MOV     AL,CTL_BYTE
		JP		writePulse

PUBLIC	IDERST
IDERST	PROC	NEAR
		; Configure 82C55: Mode 0,All Ports as Outputs (Control Word = 80h)
		; This ensures we have firm control over the lines during reset.
		OUT_DX	PPIDE_PPI,PPIDE_DIR_WRITE

		; Assert Hardware Reset
		; Bit 7 is inverted. Writing 1 drops physical Pin 1 to 0V (Active).
		OUT_DX	PPIDE_CTL,PPIDE_CTL_RESET

		CALL	initDelay

		; Release Hardware Reset
		; Writing 0 drives physical Pin 1 to 5V (Inactive).
		XOR		AL,AL
		OUT		(DX),AL

		RET
IDERST	ENDP

; =====================================================================
; Delay in ms
; =====================================================================
PUBLIC	DELAYN
DELAYN	PROC	NEAR
		PUSH	CX
		MOV		CX,AX
delaynLoop:
		CALL	delay1ms
		LOOP	delaynLoop
		POP		CX
		RET
DELAYN	ENDP

; =====================================================================
; SUBROUTINE: IDE_INIT
; Purpose: Resets,configures,and prepares the PATA Drive for 8-bit I/O
; Outputs: Carry Flag set on Error (Timeout/Fault),cleared on Success
; Destroys: A,BX
; =====================================================================
PUBLIC	IDE_INIT
IDE_INIT PROC NEAR
		call	IDERST
		call	WRDY
		call	selMst
		call	WRDY
		call	selPio8
		call	WRDY
IDE_INIT ENDP


		;Status Poll Loop (fallthrough)
PUBLIC	WRDY
WRDY	PROC	NEAR
		OUT_DX	PPIDE_PPI,PPIDE_DIR_READ	; Ports A/B input,Port C output
WRDYLoop:
		CALL	readStatus
		; Check Status Flags
		MOV     AL,AH
		AND		AL,0C0h
		CMP		AL,040h
		JNZ		WRDYLoop
		RET
WRDY	ENDP

waitDrq:
		OUT_DX	PPIDE_PPI,PPIDE_DIR_READ	; Ports A/B input,Port C output
waitDrqLoop:
		CALL	readStatus

		; Check Status Flags
		MOV     AL,AH
		AND		AL,008h
		JZ		waitDrqLoop
		RET

readSect:
		MOV     BL,0

		MOV		AH,CTL_PRELOAD
readSectLoop:
		CALL	readWordData
		DEC		BL
		JNZ		readSectLoop
		RET

writeSect:
		; The drive buffer is open. Send 512 bytes from Z80 RAM.
		MOV     BL,0
writeSectLoop:
		call	writeWordData
		DEC		BL
		JNZ		writeSectLoop
		ret

; =====================================================================
; SUBROUTINE: IDE_GET_ERROR
; output: AL = ERROR
; =====================================================================
PUBLIC	IDE_GET_ERROR
IDE_GET_ERROR PROC NEAR
		OUT_DX	PPIDE_PPI,PPIDE_DIR_READ
		CALL	readStatus
		; Check Error Flag
		MOV     AL,AH
		MOV		AH,0
		TEST	AL,001h
		JZ		getErrorRet

		;Flip 82C55 Port A to INPUT Mode to prepare for reading data
		OUT_DX	PPIDE_PPI,PPIDE_DIR_READ
		MOV     AL,CTL_ERROR
		CALL    readPulse
		MOV     AH,AL
		CALL	BUS_IDLE
		MOV		AL,AH
		MOV		AH,0FFh
getErrorRet:
		RET
IDE_GET_ERROR ENDP

; =====================================================================
; SUBROUTINE: IDE_GET_LBA
; Outputs: AX = LBA Bits 0-15,DX = LBA Bits 16-27
; =====================================================================
PUBLIC	IDE_GET_LBA
IDE_GET_LBA PROC NEAR
		PUSH	BX
		OUT_DX	PPIDE_PPI,PPIDE_DIR_READ

		MOV     AL,CTL_MAS_LBA
		call	readPulse
		MOV     BH,AL

		MOV     AL,CTL_LBA_HIG
		call	readPulse
		MOV		BL,AL
		PUSH	BX		;save LBA 16-27

		MOV     AL,CTL_LBA_MID
		call	readPulse
		MOV     BH,AL	;save LBA 8-15

		MOV     AL,CTL_LBA_LOW
		call	readPulse
		MOV		BL,AL	;save LBA 0-7

		XOR		AL,AL
		MOV		DX,PPIDE_CTL
		OUT		(DX),AL

		MOV		AX,BX	;get LBA  0-15 into AX
		POP		DX		;get LBA 16-27 into DX
		POP		BX
		RET
IDE_GET_LBA	ENDP

; =====================================================================
; SUBROUTINE: IDE_SET_LBA
; Inputs: BXCX = LBA Bits 0-27
; =====================================================================
PUBLIC	IDE_SET_LBA
IDE_SET_LBA	PROC NEAR
		PUSH	BP
		MOV		BP,SP
		MOV		CX,WORD PTR [BP+4] 	;low  LBA
		MOV		BX,WORD PTR [BP+6]	;high LBA+2

		; Ensure 82C55 Port A is set to OUTPUT mode (Control Word 80h)
		OUT_DX	PPIDE_PPI,PPIDE_DIR_WRITE

		; 4. Write Device/Head Register -> IDE Register 6 (A2-A0 = 110b)
		; Mixes LBA bits 24-27 with the mandatory LBA mode flag (0E0)
		PUSH	BX
		MOV     AL,BH
		AND     AL,00Fh               ; Mask out everything but lowest 4 bits
		OR      AL,0E0h               ; 0E0h sets Master Drive + LBA mode select

		LD_BX	CTL_MAS_LBA,AL
		call	writeReg

		; 3. Write LBA High (Bits 16-23) -> IDE Register 5 (A2-A0 = 101b)
		POP		BX
		MOV     BH,CTL_LBA_HIG
		call	writeReg
		
		; 2. Write LBA Mid (Bits 8-15) -> IDE Register 4 (A2-A0 = 100b)
		LD_BX	CTL_LBA_MID,CH
		call	writeReg

		; 1. Write LBA Low (Bits 0-7) -> IDE Register 3 (A2-A0 = 011b)
		LD_BX	CTL_LBA_LOW,CL
		call	writeReg

		; 5. Set Sector Count to 1 -> IDE Register 2 (A2-A0 = 010b)
		LD_BX	CTL_DRHD,1
		call	writeReg
		POP		BP
		RET
IDE_SET_LBA ENDP

; =====================================================================
; SUBROUTINE: IDE_GET_DISK_INFO
; Inputs: DI = RAM Destination Address for the 512 bytes
; Outputs: Carry Flag set on Error,cleared on Success
; Destroys: A,BX,DI
; =====================================================================
;Word Offset	Byte Offset     Field Description	Format
;Words 10–19	014h – 027h	Serial Number			20-character ASCII string
;Words 27–46	036h – 05Dh	Model Number/Name		40-character ASCII string
;Words 60–61	078h – 07Bh	Total LBA Sectors       32-bit Integer (Capacity)
;
;Z80 Byte-Swap Warning: ATA stores strings with the bytes swapped inside
;each word (e.g.,characters 214365... instead of 123456...). When parsing 
;this text with a Z80,you must swap adjacent bytes before printing them.
;
; ON RETURN,ZF SET INDICATES HARDWARE FOUND
PUBLIC	IDE_GET_DISK_INFO
IDE_GET_DISK_INFO PROC NEAR
		PUSH	BP
		MOV		BP,SP
		MOV		DI,WORD PTR [BP+4] 	;buffer address

		LD_BX	CTL_CMD,PPIDE_CMD_IDDEV
		call	writeReg

		JP		IDE_READ_DATA
IDE_GET_DISK_INFO ENDP

;------------------------------
;## Part 2: Reading a 512-Byte Sector
;Once the LBA target is specified,we issue the Read Sectors Command (020)
;to the Command Register. The drive will pull its Busy flag high,seek the
;data internally,and then lower Busy while raising the DRQ (Data Request)
;flag to inform the Z80 that the 512-byte buffer is ready to be transferred.
;This routine expects DI to point to the destination memory buffer in your
;Z80's RAM.

; =====================================================================
; SUBROUTINE: IDE_READ_SECTOR
; Inputs: DI = RAM Destination Address for the 512 bytes
; Outputs: Carry Flag set on Error,cleared on Success
; Destroys: A,BX,DI
; =====================================================================
PUBLIC	IDE_READ_SECTOR
IDE_READ_SECTOR PROC NEAR
		PUSH	BP
		MOV		BP,SP
		MOV		DI,WORD PTR [BP+4] 	;buffer address

		call	WRDY
		; 2. Issue READ SECTOR Command (20h) -> IDE Register 7 (A2-A0 = 111b)
		LD_BX	CTL_CMD,PPIDE_CMD_READ
		call	writeReg

IDE_READ_DATA:
		; 3. Flip 82C55 Port A to INPUT Mode to prepare for reading data
		OUT_DX	PPIDE_PPI,PPIDE_DIR_READ
		call	waitDrq
		call	readSect
		OR      AL,AL    ; Clear Carry flag (Signals Success)
		POP		BP
		RET
IDE_READ_SECTOR ENDP

; =====================================================================
; SUBROUTINE: IDE_WRITE_SECTOR
; Inputs: DI = RAM Source Address for the 512 bytes to write
; Outputs: Carry Flag set on Error,cleared on Success
; Destroys: A,BX,DI
; =====================================================================
PUBLIC	IDE_WRITE_SECTOR
IDE_WRITE_SECTOR PROC NEAR
		PUSH	BP
		MOV		BP,SP
		MOV		DI,WORD PTR [BP+4] 	;buffer address

		; 2. Issue WRITE SECTOR Command (30h) -> IDE Register 7 (A2-A0 = 111b)
		LD_BX	CTL_CMD,PPIDE_CMD_WRITE
		call	writeReg
		call	waitDrq

IDE_WRITE_READY:
		; Restore Port A to Output Mode for the impending data transfer
		OUT_DX	PPIDE_PPI,PPIDE_DIR_WRITE

		call	writeSect
		call	WRDY
		OR      AL,AL    ; Clear Carry flag (Signals Success)
		POP		BP
		RET
IDE_WRITE_SECTOR ENDP

;----------------------------------------------------------------------
; PROBE FOR PPI HARDWARE
;----------------------------------------------------------------------
;
; ON RETURN,0xFF INDICATES HARDWARE FOUND
PUBLIC	IDE_DETECT
IDE_DETECT PROC NEAR
		; TEST FOR PPI EXISTENCE
		; WE SETUP THE PPI TO WRITE,THEN WRITE A VALUE OF $A5
		; TO PORT A (DATALO),THEN READ IT BACK.  IF THE PPI IS THERE
		; THEN THE BUS HOLD CIRCUITRY WILL READ BACK THE $A5. SINCE
		; WE ARE IN WRITE MODE,AN IDE CONTROLLER WILL NOT BE ABLE TO
		; INTERFERE WITH THE VALUE BEING READ.
		OUT_DX	PPIDE_PPI,PPIDE_DIR_WRITE

		OUT_DX	PPIDE_DATALO,0A5h	; TEST VALUE
		IN		AL,(DX)				; GET PORT VALUE
		XOR		AL,0A5h				; CHECK FOR TEST VALUE
		NOT		AL
		RET							; AND RETURN
IDE_DETECT ENDP

END_AS_PPIDE:
;CODE     ENDS
         END
;end
