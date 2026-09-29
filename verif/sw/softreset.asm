; ======================================================================
; SYSCON SOFT RESET TESTCASE (FULLY CORRECTED)
; ======================================================================

;.ORG 0000           

; --- 1. SYSTEM INIT ---
CLI        
MOV AX, 0002         
MOV CR0, AX      ; Enable TLB

; --- 1.5. CLEAR POWER-ON RESETS (THE MISSING FIX) ---
; We MUST W1C the Wakeup flag from the physical boot sequence,
; otherwise the IPs will completely ignore the TRIG commands!
MOV AX, 0008        ; Load 0008 (Bit 3 is HIGH)
MOV [8080], AX      ; Clear Power-On Flag for IP1
MOV [9080], AX      ; Clear Power-On Flag for IP2
MOV [A080], AX      ; Clear Power-On Flag for IP3

; --- 2. START THE PERIPHERALS ---
TRIG_IP1            ; (These will now successfully fire!)
TRIG_IP2            
TRIG_IP3            

; --- 3. SOFT RESET IP1 ---
; SYSCON is at Virtual 0x5000. Write 0001 to reset IP1.
MOV AX, 0001        
MOV [5000], AX      

; --- 4. GLOBAL SOFT RESET ---
; Write 0007 (0111 binary) to reset all three simultaneously.
MOV AX, 0007        
MOV [5000], AX      

; --- 5. ACKNOWLEDGE THE SOFT RESETS ---
; Because we just soft-reset them, their hardware state machines 
; forced Bit 3 HIGH again. We must clear them to restore functionality.
MOV AX, 0008        
MOV [8080], AX      
MOV [9080], AX      
MOV [A080], AX      

; --- 6. RESTART SAFELY ---
TRIG_IP1            ; IP1 is back online!

HLT

