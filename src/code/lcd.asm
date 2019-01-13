SECTION "LCD", ROM0

DisableLCD::
	xor a
	ld [rIF], a
	ld a, [rIE]
	ld b, a
	res 0, a
	ld [rIE], a
.waitVBlank
	ld a, [rLY]
	cp a, $91
	jr nz, .waitVBlank
	ld a, [rLCDC]
	and a, $7F
	ld [rLCDC], a
	ld a, b
	ld [rIE], a
	ret

EnableLCD::
	ld a, [rLCDC]
	set 7, a
	ld [rLCDC], a
	ret

DisableWindow::
	ld a, [rLCDC]
	res 5, a ; disable window
	ld [rLCDC], a
	ret

EnableWindow::
	ld a, [rLCDC]
	set 5, a ; enable window
	set 6, a ; use bg map 1
	ld [rLCDC], a
	ret
