; Hardware interrupts

SECTION "VBlank int", ROM0[$40]
	jp VBlank

SECTION "HBlank int", ROM0[$48]
	reti

SECTION "Timer int",  ROM0[$50]
	reti

SECTION "Serial int", ROM0[$58]
	reti

SECTION "Joypad int", ROM0[$60]
	reti



SECTION "VBlank", ROM0

VBlank:
	push af
	push bc
	push de
	push hl
	call hDMA

	call CheckGfxQueue
	call nc, RunCallbacks

	call RunTasks

	put [wVBlank], 1

	pop hl
	pop de
	pop bc
	pop af
	reti


SECTION "VBlank Wait", ROM0

WaitVBlank::
	xor a
	ld [wVBlank], a
.wait
	halt
	ld a, [wVBlank]
	and a
	jr z, .wait
	ret


SECTION "VBlank WRAM", WRAM0

wVBlank:: ds 1


INCLUDE "code/video/queue.asm"
INCLUDE "code/video/callback.asm"
