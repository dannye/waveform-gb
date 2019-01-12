; rst vectors are single-byte calls.

; Here, farcall is used as a pseudoinstruction.
; The other vectors are free to use for any purpose.


SECTION "rst Bankswitch", ROM0[Bankswitch]
	ld [hROMBank], a
	ld [MBC5_ROMBank], a
	ret

SECTION "rst FarCall", ROM0[FarCall]
	jp FarCall_


SECTION "rst $10", ROM0[$10]
SECTION "rst $18", ROM0[$18]
SECTION "rst $20", ROM0[$20]
SECTION "rst $28", ROM0[$28]
SECTION "rst $30", ROM0[$30]
SECTION "rst $38", ROM0[$38]


SECTION "FarCall", ROM0

FarCall_:
	ld  [wFarCallHold + 0], a
	put [wFarCallHold + 1], l
	put [wFarCallHold + 2], h

	pop hl
	put [wFarCallBank],        [hli]
	put [wFarCallTarget],      $C3 ; <jp>
	put [wFarCallAddress + 0], [hli]
	put [wFarCallAddress + 1], [hli]
	push hl

	ld hl, wFarCallHold + 1
	ld a, [hli]
	ld h, [hl]
	ld l, a

	ld a, [hROMBank]
	push af
	ld a, [wFarCallBank]
	rst Bankswitch

	ld a, [wFarCallHold + 0]

	call wFarCallTarget

	push af

	add sp, 2
	pop af ; hROMBank
	add sp, -4
	rst Bankswitch

	pop af
	add sp, 2
	ret


SECTION "FarCall WRAM", WRAM0

wFarCallHold:    ds 3
wFarCallBank:    ds 1
wFarCallTarget:  ds 1 ; jp
wFarCallAddress: ds 2
