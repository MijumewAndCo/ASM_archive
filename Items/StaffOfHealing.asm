; Template based on https://github.com/irdkwia/eos-move-effects/blob/master/template.asm
.relativeinclude on
.nds
.arm

.definelabel MaxSize, 0xcc4

; Uncomment/comment the following labels depending on your version.

; For US
.include "lib/stdlib_us.asm"
.include "lib/dunlib_us.asm"
.definelabel StartAddress, 0x231be50
.definelabel JumpAddress, 0x231cb14
.definelabel AdvanceFrame, 0x22E9FE0

; For EU
;.include "lib/stdlib_eu.asm"
;.include "lib/dunlib_eu.asm"
;.definelabel StartAddress, 0x231c8b0
;.definelabel JumpAddress, 0x231d574
;.definelabel AdvanceFrame, 0x22EA990

; File creation
.create "./code_out.bin", 0x231be50 ; For EU: 0x231c8b0
  .org StartAddress
  .area MaxSize ; Define the size of the area
	push r4
    sub r13, r13, #0x4  
	
    ; Code here
	
	; Wait 20 frames to let the animation play out
	mov r0, #0
	mov r4, #20
	loop_advance:
	bl AdvanceFrame
	sub r4, r4, #1
	cmp r4, #0
	bne loop_advance
	
	mov r4, #0
	ldr r0, [r8, #+0xB4]
	ldrh r1, [r0, #+0x12]	; Max HP
	ldrh r2, [r0, #+0x16]	; HP boosts to max HP
	ldrh r0, [r0, #+0x10]	; Current HP
	add r1, r1, r2
	cmp r0, r1
	moveq r4, #1
	
    mov r0, #0 ; argument #4 FailMessage
    str r0, [r13, #+0x0]
    mov r0, r8 ; argument #0 User
    mov r1, r7 ; argument #1 Target
    mov r2, #150 ; argument #2 HPHeal
    mov r3, #0 ; argument #3 MaxHpRaise
    bl RaiseHP
	
    mov r0, r8 ; argument #0 User
    ldr r1, =hp_recover_full ; argument #1 String
    mov r2, #1 ; argument #2 Log
	cmp r4, #1
    bleq SendMessageWithString
    
    mov r0, r8 ; argument #0 User
    mov r1, r7 ; argument #1 Target
    mov r2, #5 ; argument #2 PPHeal
    mov r3, #0 ; argument #3 NoMessage
    bl HealAllMovesPP
    
    
  end:
    add r13, r13, #0x4  
    pop r4
	
    b JumpAddress
    .pool

  ; Variables and static arrays
  hp_recover_full:
    .asciiz "[string:0] has full [CS:E]HP[CR] already!"
  
  .endarea
.close
