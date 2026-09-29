; ==================================================
; SYSTEM INITIALIZATION & BOOT SEQUENCE
; ==================================================
; 1. ENABLE THE TLB FIRST! (Crucial for MMIO Routing)
MOV AX, 0003

MOV CR0, AX

; 2. NOW CLEAR THE IPs (The TLB will route this to the peripherals)
MOV AX, 0008
MOV [8080], AX  ; Clear IP1 Boot Reset
MOV [9080], AX  ; Clear IP2 Boot Reset
MOV [A080], AX  ; Clear IP3 Boot Reset

; 3. CLEAR THE PIC (Wipe any ghost interrupts latched during boot)
MOV AX, 0007

MOV [7004], AX

; 4. ENABLE INTERRUPTS
MOV AX, 0007    ; Unmask IP1, IP2, IP3
MOV [7002], AX

MOV AX, 0001    ; Global PIC Enable
MOV [7006], AX

STI             ; Listen for hardware interrupts

; ==================================================
; SEQUENTIAL HARDWARE BURSTS
; ==================================================
TRIG_IP1        ; Start IP1
HLT             ; <--- THE SOLUTION. CPU goes to sleep.
; It will NOT move to the next line until IP1 sends an interrupt!

TRIG_IP2        ; This line only runs after IP1's ISR finishes.
HLT             ; CPU sleeps until IP2 is finished.

TRIG_IP3

HLT             ; CPU sleeps until IP3 is finished.

HLT             ; Final stop. End of simulation.

; ==================================================
; INTERRUPT SERVICE ROUTINE (ISR)
; ==================================================
; Your script multiplies .ORG by 2.
; .ORG 0200 safely places the ISR at Byte Address 0x0400!
; ==============================================================
; INTELLIGENT INTERRUPT SERVICE ROUTINE (ISR)
; ==============================================================
;.ORG 0200       
;CLI             

; Read PIC Status to see WHICH IP interrupted
;MOV AX, [7000]  
;MOV [7004], AX  ; ACK PIC

; --- CONDITIONAL JUMPS ---
;CMP AX, 0001    ; Did IP1 trigger it?
;JE 0210         ; If yes, jump directly to the IP1 handler at Word 0210;
;CMP AX, 0002    ; Did IP2 trigger it?
;JE 0220         ; If yes, jump directly to the IP2 handler at Word 0220

;CMP AX, 0004    ; Did IP3 trigger it?
;JE 0230         ; If yes, jump directly to the IP3 handler at Word 0230

;IRET            ; Failsafe return

; --- IP1 HANDLER ---
;.ORG 0210
;MOV AX, 000F
;MOV [8080], AX  ; Clear only IP1!
;JMP 0240        ; Jump down to the exit block

; --- IP2 HANDLER ---
;.ORG 0220
;MOV AX, 000F
;MOV [9080], AX  ; Clear only IP2!
;JMP 0240        ; Jump down to the exit block

; --- IP3 HANDLER ---
;.ORG 0230
;MOV AX, 000F
;MOV [A080], AX  ; Clear only IP3!
;JMP 0240        ; Jump down to the exit block

; --- EXIT BLOCK ---
;.ORG 0240
;STI
;IRET

; ==============================================================
; INTELLIGENT ISR (WITH PROPER AX RELOAD)
; ==============================================================
.ORG 0200       
;CLI             

; Read PIC Status to see WHICH IP(s) interrupted
MOV AX, [7000]  
MOV [7004], AX  ; ACK PIC

; --- CONDITIONAL JUMPS ---
CMP AX, 0001    ; Only IP1
JE 0210
CMP AX, 0002    ; Only IP2
JE 0220
CMP AX, 0004    ; Only IP3
JE 0230

IRET            ; Failsafe return

; ==========================================
; HANDLER BLOCKS
; ==========================================
; --- IP1 HANDLER ---
.ORG 0210
MOV AX, 000F    ; Load exactly 4-digit F
MOV [8080], AX  ; Write F to IP1
JMP 0240

; --- IP2 HANDLER ---
.ORG 0220
MOV AX, 000F    ; Load exactly 4-digit F
MOV [9080], AX  ; Write F to IP2
JMP 0240

; --- IP3 HANDLER ---
.ORG 0230
MOV AX, 000F    ; Load exactly 4-digit F
MOV [A080], AX  ; Write F to IP3
JMP 0240

; --- EXIT BLOCK ---
.ORG 0240
STI
IRET

