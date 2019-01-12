BUTTONS EQU $10
D_PAD   EQU $20
DONE    EQU $30


SECTION "Joypad", ROM0

Joypad::
	put [rJOYP], D_PAD
	REPT 2
	ld a, [rJOYP]
	ENDR

	cpl
	and %1111
	swap a

	ld b, a

	put [rJOYP], BUTTONS
	REPT 6
	ld a, [rJOYP]
	ENDR

	cpl
	and %1111
	or b

	ld b, a

	put [rJOYP], DONE

	ld a, [wJoy]
	ld [wJoyLast], a
	ld e, a
	xor b
	ld d, a

;	ld a, d
	and e
	ld [wJoyReleased], a

	ld a, d
	and b
	ld [wJoyPressed], a

	ld a, b
	ld [wJoy], a

	ret


SECTION "Joypad WRAM", WRAM0

wJoy::         ds 1
wJoyLast::     ds 1
wJoyPressed::  ds 1
wJoyReleased:: ds 1
