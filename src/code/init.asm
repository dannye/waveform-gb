SECTION "Stack", WRAM0[$C080]

	ds $80 - 1
wStack::


SECTION "Init", ROM0

Init:
	di

	cp BOOTUP_A_CGB
	ld a, 1
	jr z, .cgb
	xor a
.cgb
	ld [hGBC], a

	xor a
	ldx [rIF],  [rIE]
	ldx [rRP]
	ldx [rSCX], [rSCY]
	ldx [rSB],  [rSC]
	ldx [rWX],  [rWY]
	ldx [rBGP], [rOBP0], [rOBP1]
	ldx [rTMA], [rTAC]

	put [rTAC], TAC_4KHZ

.wait
	ld a, [rLY]
	cp LY_VBLANK
	jr c, .wait

	xor a
	ld [rLCDC], a


	ld sp, wStack

	fill $C000, $2000, 0

	ld a, [hGBC]
	and a
	jr z, .cleared_wram

	ld a, 7
.wram_bank
	push af
	ld [rWBK], a
	fill $D000, $1000, 0
	pop af
	dec a
	cp 1
	jr nc, .wram_bank
.cleared_wram

	ld a, [hGBC]
	push af
	fill $FF80, $7F, 0
	pop af
	ld [hGBC], a

	fill $8000, $2000, 0

	fill $FE00, $A0, 0


	put [rJOYP], 0
	put [rSTAT], STAT_MODE_0 ; hblank enable
	put [rWY], $90
	put [rWX], WX_OFS

	put [rLCDC], LCDC_ON | LCDC_WIN_9C00 | LCDC_WIN_ON | LCDC_BLOCK21 | LCDC_BG_9800 | LCDC_OBJ_8 | LCDC_OBJ_ON | LCDC_BG_ON

IF def(NormalSpeed) ; not implemented yet
	ld a, [hGBC]
	and a
	call nz, NormalSpeed
ENDC

	put [rIF], 0
	put [rIE], IE_SERIAL | IE_TIMER | IE_STAT | IE_VBLANK

	ei

	halt

	call WriteDMATransferToHRAM
	call Main

	; if Main returns, restart the program
	jp Init
