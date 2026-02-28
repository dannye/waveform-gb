SECTION "LCD", ROM0

DisableLCD::
	xor a
	ld [rIF], a
	ld a, [rIE]
	ld b, a
	res B_IE_VBLANK, a
	ld [rIE], a
.waitVBlank
	ld a, [rLY]
	cp a, LY_VBLANK + 1
	jr nz, .waitVBlank
	ld a, [rLCDC]
	and a, ~LCDC_ON
	ld [rLCDC], a
	ld a, b
	ld [rIE], a
	ret

EnableLCD::
	ld a, [rLCDC]
	set B_LCDC_ENABLE, a
	ld [rLCDC], a
	ret

DisableWindow::
	ld a, [rLCDC]
	res B_LCDC_WINDOW, a ; disable window
	ld [rLCDC], a
	ret

EnableWindow::
	ld a, [rLCDC]
	set B_LCDC_WINDOW, a ; enable window
	set B_LCDC_WIN_MAP, a ; use bg map 1
	ld [rLCDC], a
	ret
