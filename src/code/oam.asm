OAM_SPRITES = 40


section "OAM", wram0[$c300]

wOAM::
	ds 4 * OAM_SPRITES


section "OAM DMA Transfer", rom0

; copy DMA routine to HRAM
WriteDMATransferToHRAM:
	ld c, LOW(hDMA)
	ld b, DMATransferEnd - DMATransfer
	ld hl, DMATransfer
.copyLoop
	ld a, [hli]
	ld [$ff00+c], a
	inc c
	dec b
	jr nz, .copyLoop
	ret

; this routine is copied to HRAM and executed there every vblank
DMATransfer:
	ld a, wOAM >> 8
	ld [rDMA], a
	ld a, OAM_SPRITES
.waitLoop
	dec a
	jr nz, .waitLoop
	ret
DMATransferEnd:
