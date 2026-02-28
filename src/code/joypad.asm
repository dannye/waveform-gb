SECTION "Joypad", ROM0

Joypad::
	put [rJOYP], JOYP_GET_CTRL_PAD
	REPT 2
	ld a, [rJOYP]
	ENDR

	cpl
	and JOYP_INPUTS
	swap a

	ld b, a

	put [rJOYP], JOYP_GET_BUTTONS
	REPT 6
	ld a, [rJOYP]
	ENDR

	cpl
	and JOYP_INPUTS
	or b

	ld b, a

	put [rJOYP], JOYP_GET_NONE

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
