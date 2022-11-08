; Template based on https://github.com/irdkwia/eos-move-effects/blob/master/template.asm
.relativeinclude on
.nds
.arm

.definelabel MaxSize, 0xCC4

; Uncomment/comment the following labels depending on your version.

; For US
.include "lib/stdlib_us.asm"
.include "lib/dunlib_us.asm"
.definelabel StartAddress, 0x231BE50
.definelabel JumpAddress, 0x231CB14

.definelabel PlaySoundEffect, 0x201A4FC
.definelabel AdvanceFrame, 0x22E9FE0
.definelabel RandMax, 0x22EAA98
.definelabel PosIsOutOfBounds, 0x2340CAC
.definelabel GetTile, 0x23360FC
.definelabel GetTileTerrain, 0x233AE78
.definelabel EntityIsValid, 0x22E0354
.definelabel IsMonster, 0x22F9720
.definelabel FloorNumberIsEven, 0x22F73B4
.definelabel SpawnMonster, 0x22FD084
.definelabel LoadSprite, 0x22F7654
.definelabel DIRECTIONS_XY, 0x235171C
.definelabel DUNGEON_PTR, 0x2353538
.definelabel SECONDARY_TERRAINS, 0x20A1AE8

; For EU
;.include "lib/stdlib_eu.asm"
;.include "lib/dunlib_eu.asm"
;.definelabel StartAddress, 0x231C8B0
;.definelabel JumpAddress, 0x231D574

;.definelabel PlaySoundEffect, 0x201A598
;.definelabel AdvanceFrame, 0x22EA990
;.definelabel RandMax, 0x22EB448
;.definelabel PosIsOutOfBounds, 0x2341890
;.definelabel GetTile, 0x2336CCC
;.definelabel GetTileTerrain, 0x233BA5C
;.definelabel EntityIsValid, 0x22E0C94
;.definelabel IsMonster, 0x22FA12C
;.definelabel FloorNumberIsEven, 0x22F7D6C
;.definelabel SpawnMonster, 0x22FDA80
;.definelabel LoadSprite, 0x22F800C
;.definelabel DIRECTIONS_XY, 0x2352328
;.definelabel DUNGEON_PTR, 0x2354138
;.definelabel SECONDARY_TERRAINS, 0x20A206C

; File creation
.create "./code_out.bin", 0x231BE50 ; For EU: 0x231C8B0
  .org StartAddress
  .area MaxSize ; Define the size of the area
	push r4,r5,r8,r10

    ; Code here
	
	; Wait 30 frames to let the animation play out
	mov r0, #0
	mov r4, #30
	loop_advance:
	bl AdvanceFrame				; Takes no arguments
	sub r4, r4, #1
	cmp r4, #0
	bne loop_advance
	
	; Load Huntail sprite
	bl FloorNumberIsEven		; Check if the floor number is even (Takes no arguments, returns boolean)
	cmp r0, #0
	ldreq r10, =#399			; Spawn male or female Huntail accordingly
	ldrne r10, =#999
	mov r0, r10
	mov r1, #0
	bl LoadSprite				; Takes r0 = Pokémon species
	
	; Random number of Huntail (1-4)
	mov r0, #4
	bl RandMax					; Takes r0 = Upper bound, returns [0, Upper bound - 1]
	add r8, r0, #1
	push r8
	
	; Get user direction
	ldr r0, [r7, #+0xB4]		; User monster struct
	ldrb r0, [r0, #+0x4C]		; User direction
	; Decrement
	cmp r0, #0
	moveq r4, #7
	subne r4, r0, #1
	mov r5, r4
	
	; Loop
	; r4 = initial direction
	; r5 = current direction
	; r8 = number of Huntail
	loop_create_huntail:
		push r4,r5
		
		; Get position from direction
		mov r0, r5
		ldr r2, =DIRECTIONS_XY		; Array containing a mapping between directions and relative x-y positions
		add r3, r2, #2
		mov r0, r0, lsl 0x2
		ldrsh r2, [r2, r0]			; Relative positions
		ldrsh r3, [r3, r0]
		ldrh r0, [r7, #+0x4]		; User absolute x-y positions
		ldrh r1, [r7, #+0x6]		; Why yes I copied this code from the version where I only spawn one Huntail
									; Hence why I check these at every loop
									; It's fine, I was already running out of registers
		add r0, r0, r2				; Target absolute x-y positions
		add r1, r1, r3
		mov r4, r0
		mov r5, r1
		bl PosIsOutOfBounds			; Out of bounds check (Takes r0 = x position, r1 = y position)
		cmp r0, #1
		beq branch_1_incrloop
		
		; Get tile terrain
		mov r0, r4
		mov r1, r5
		bl GetTile					; Target tile (Takes r0 = x position, r1 = y position, returns Tile pointer)
		mov r10, r0
		bl GetTileTerrain			; Terrain check to see if Huntail can spawn (Takes r0 = Tile pointer, returns terrain type)
		
		; Check if secondary terrain is water
		ldr r2, =DUNGEON_PTR		; Main dungeon pointer
		ldr r2, [r2]
		add r2, r2, 0x4000
		ldrb r2, [r2, #+0xD4]		; Dungeon tileset ID
		ldr r1, =SECONDARY_TERRAINS	; Array containing the secondary terrain type for each dungeon
		ldrb r2, [r1, r2]			; Secondary terrain type for this tileset
									; Again, I am running out of registers here
		
		; Check terrain + if Pokémon is already on it
		cmp r2, #0					; 0 means the secondary terrain is water
		cmpeq r0, #2
		cmpne r0, #1
		bne branch_1_incrloop
		ldr r0, [r10, #+0xC]		; Target monster
		cmp r0, #0					; Check if there is an entity
		bne branch_1_incrloop
		
		; Huntail spawn
		bl FloorNumberIsEven		; Check if the floor number is even (Takes no arguments, returns boolean)
		cmp r0, #0
		ldreq r10, =#399			; Spawn male or female Huntail accordingly
		ldrne r10, =#999			; Wow it's almost as if I was running out of registers or something
		ldr r1, =huntail			; huntail
		strh r10, [r1]
		strh r4, [r1, #+0xA]		; x-y positions
		strh r5, [r1, #+0xC]
		ldr r4, [r7, #+0xB4]		; User moster struct
		ldrb r4, [r4, #+0xA]		; User level
		mov r0, #3
		bl RandMax					; Slight level decrement (Takes r0 = Upper bound, returns [0, Upper bound - 1])
		add r0, r0, #4
		cmp r4, r0
		subgt r4, r4, r0
		movle r4, #1
		ldr r0, =huntail			; huntail
		strh r4, [r0, #+0x8]		; Huntail level
		mov r1, #1
		bl SpawnMonster				; Takes r0 = Pointer to the appropriate struct, r1 = "Cannot be asleep" check
									; Returns pointer to entity
		
		; Change Huntail's direction
		pop r4,r5					; Retrieve current direction
		push r4,r5
		add r1, r5, #4				; Calculations for Huntail's direction
		cmp r1, #7
		subgt r1, #8
		strb r1, [r0, #+0xA4]		; Huntail's sprite's direction
		strb r1, [r0, #+0xB0]
		strb r1, [r0, #+0xB1]
		ldr r0, [r0, #+0xB4]		; Huntail monster struct
		strb r1, [r0, #+0x4C]		; Huntail's actual direction
		
		; After spawning Huntail
		sub r8, r8, #1				; Check if all Huntail have been spawned
		cmp r8, #0
		popeq r4, r5
		beq loop_end
		
		; After ending the loop through other means
		branch_1_incrloop:
		pop r4,r5					; Retrieve current direction
		add r5, r5, #3				; Change direction
		cmp r5, #7
		subgt r5, #8
		cmp r5, r4					; Check if a full turn (three full turns?) have been completed
		bne loop_create_huntail
	
	loop_end:
	mov r0, r8						; Check if no Huntail could be spawned
	pop r8
	cmp r0, r8
	beq branch_0_notwork
	bne branch_0_work
	
	branch_0_notwork:
	; Message
	mov r0, r7
    ldr r1, =fail_message
    mov r2, #1
    bl SendMessageWithString		; Takes r0 = User, r1 = String pointer, r2 = Log check
	b branch_0_end
	
	branch_0_work:
	; Message
	ldr r0, =#783
	ldr r1, =#0x100 				; Default values
	ldr r2, =#0x1F
	bl PlaySoundEffect				; Takes r0 = Sound effect ID, r1 = ?, r2 = ?
	mov r0, r7
    ldr r1, =success_message
    mov r2, #1
    bl SendMessageWithString		; Takes r0 = User, r1 = String pointer, r2 = Log check
	bl AdvanceFrame					; Just a bit of padding (Takes no arguments)
	bl AdvanceFrame
	
	branch_0_end:
	
  end:
	pop r4,r5,r8,r10
    
    b JumpAddress
    .pool

  ; Variables and static arrays
  fail_message:
    .asciiz "No eels could be summoned..."
  success_message:
    .asciiz "...It reeled in the eels!"
  .align
  huntail:	; Huntail spawn struct
	.halfword 399	; Species
	.byte 6			; Behavior (enemy)
	.byte 0			; Undefined fields
	.word 0
	.halfword 1		; Default level
	.word 0			; Default position
	.byte 1			; Cannot be asleep
	.byte 0			; Undefined field
  
  .endarea
.close
