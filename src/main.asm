include "constants.asm"

KNOB_BASE_TILE = 0
KNOB_TRACK_TILE = 1
KNOB_LEFT_TILE = 2
KNOB_RIGHT_TILE = 3
KNOB_BOTH_TILE = 4
KNOB_START_X = 2
KNOB_START_Y = 1
NUM_COLUMNS = 16
NUM_ROWS = 16
KNOB_HEIGHT = 1
KNOB_WIDTH = 5

NUMBER_X = KNOB_START_X + -1
NUMBER_Y = KNOB_START_Y

FONT_BASE_TILE = $20
FONT_HEIGHT = 6
FONT_WIDTH = 16

HEX_BASE_TILE = $10
HEX_X = KNOB_START_X
HEX_Y = KNOB_START_Y + NUM_ROWS
HEX_HEIGHT = 1
HEX_WIDTH = 16

ARROW_TILE = 0
ARROW_X = 8 * KNOB_START_X + 6
ARROW_Y = 8 * (KNOB_START_Y + 1)


section "Main wram", wram0

wWave:: ds NUM_COLUMNS
wCursorPos: ds 1
wKnobColumn: ds NUM_ROWS
wHexTiles: ds $10 * HEX_WIDTH
wNewHexTile: ds $10


section "Main", rom0

Main::
	call InitSound
	call Setup
.loop
	call WaitVBlank
	call Update
	jr .loop

Update:
	call Joypad
	ld c, 0
	ld a, [wCursorPos]
	bit 0, a
	jr z, .even
	ld c, 1
.even
	srl a
	ld d, 0
	ld e, a
	ld hl, wWave
	add hl, de
	ld a, [wJoyPressed]
	bit D_UP_F, a
	jr z, .noUp
	ld a, [hl]
	bit 0, c
	jr nz, .skipOdd1
	swap a ; skip for odd knobs
.skipOdd1
	and $0F
	cp $F
	jr z, .isMax
	inc a
	bit 0, c
	jr nz, .skipOdd2
	swap a ; skip for odd knobs
.skipOdd2
	ld b, a
	ld a, [hl]
	bit 0, c
	jr nz, .skipOdd3
	and $0F ; for even knobs
	jr .skipEven1
.skipOdd3
	and $F0 ; for odd knobs
.skipEven1
	or b
	ld [hl], a
	call UpdateKnobTilemap
	callback CopyKnobTilemap
	call UpdateHexTile
	callback CopyHexTile
	call UpdateWave
.isMax
.noUp
	ld a, [wJoyPressed]
	bit D_DOWN_F, a
	jr z, .noDown
	ld a, [hl]
	bit 0, c
	jr nz, .skipOdd4
	swap a ; skip for odd knobs
.skipOdd4
	and $0F
	cp 0 ; redundant
	jr z, .isMin
	dec a
	bit 0, c
	jr nz, .skipOdd5
	swap a ; skip for odd knobs
.skipOdd5
	ld b, a
	ld a, [hl]
	bit 0, c
	jr nz, .skipOdd6
	and $0F ; for even knobs
	jr .skipEven2
.skipOdd6
	and $F0 ; for odd knobs
.skipEven2
	or b
	ld [hl], a
	call UpdateKnobTilemap
	callback CopyKnobTilemap
	call UpdateHexTile
	callback CopyHexTile
	call UpdateWave
.isMin
.noDown
	ld a, [wJoyPressed]
	bit D_LEFT_F, a
	jr z, .noLeft
	ld a, [wCursorPos]
	dec a
	cp -1
	jr nz, .noUnderflow
	ld a, NUM_COLUMNS * 2 - 1
.noUnderflow
	ld [wCursorPos], a
	ld d, a
	ld e, 4
	call Multiply
	ld bc, ARROW_X
	add hl, bc
	put [wOAM + 1], l
.noLeft
	ld a, [wJoyPressed]
	bit D_RIGHT_F, a
	jr z, .noRight
	ld a, [wCursorPos]
	inc a
	cp NUM_COLUMNS * 2
	jr nz, .noOverflow
	xor a
.noOverflow
	ld [wCursorPos], a
	ld d, a
	ld e, 4
	call Multiply
	ld bc, ARROW_X
	add hl, bc
	put [wOAM + 1], l
.noRight
	ret

UpdateWave:
	put [rNR30], %00000000 ; ch3 off
	ld c, NUM_COLUMNS
	ld hl, wWave
	ld de, $FF30
.copyLoop
	put [de], [hli]
	inc de
	dec c
	jr nz, .copyLoop
	put [rNR30], %10000000 ; ch3 on
	call PlayNote
	ret

Setup:
	call DisableLCD

	ld bc, KnobGraphics
	ld de, vChars2 + KNOB_BASE_TILE * $10
	ld a, KNOB_WIDTH * KNOB_HEIGHT
	call LoadGfx

	ld bc, HexGraphics
	ld de, wHexTiles
	ld a, HEX_WIDTH * HEX_HEIGHT
	call LoadGfx

	ld bc, FontGraphics
	ld de, vChars2 + FONT_BASE_TILE * $10
	ld a, FONT_WIDTH * FONT_HEIGHT
	call LoadGfx

	ld bc, ArrowGraphics
	ld de, vChars0 + ARROW_TILE * $10
	ld a, 1
	call LoadGfx

	put [wCursorPos], 0
	rept NUM_COLUMNS
	call UpdateKnobTilemap
	call CopyKnobTilemap
	call UpdateHexTile
	call CopyHexTile
	ld a, [wCursorPos]
	inc a
	inc a
	ld [wCursorPos], a
	endr
	put [wCursorPos], 0
	call DrawNumberTilemap

	ld hl, vBGMap0 + BG_WIDTH * HEX_Y + HEX_X
	ld a, HEX_BASE_TILE
	rept NUM_COLUMNS
	ld [hli], a
	inc a
	endr

	ld hl, wOAM
	put [hli], ARROW_Y
	put [hli], ARROW_X
	put [hli], ARROW_TILE
	put [hli], $00

	call SetPalette

	call EnableLCD
	ret

UpdateKnobTilemap:
	ld hl, wKnobColumn
	ld a, KNOB_TRACK_TILE
	rept NUM_ROWS
	ld [hli], a
	endr
	ld a, [wCursorPos]
	srl a
	ld b, 0
	ld c, a
	ld hl, wWave
	add hl, bc
	ld a, [hl]
	ld b, a
	and $0F
	push af
	ld a, b
	swap a
	and $0F
	ld b, a
	ld a, $0F
	sub b
	ld d, a ; backup
	ld b, 0
	ld c, a
	ld hl, wKnobColumn
	add hl, bc
	ld [hl], KNOB_LEFT_TILE
	pop af
	ld b, a
	ld a, $0F
	sub b
	ld b, 0
	ld c, a
	ld hl, wKnobColumn
	add hl, bc
	ld [hl], KNOB_RIGHT_TILE
	cp d
	jr nz, .different
	ld [hl], KNOB_BOTH_TILE
.different
	ret

CopyKnobTilemap:
	ld a, [wCursorPos]
	srl a
	ld b, 0
	ld c, a
	ld hl, vBGMap0 + BG_WIDTH * KNOB_START_Y + KNOB_START_X
	add hl, bc
	ld de, wKnobColumn
	ld bc, BG_WIDTH
	rept NUM_ROWS
	put [hl], [de]
	add hl, bc
	inc de
	endr
	ret

UpdateHexTile:
	ld a, [wCursorPos]
	srl a
	ld b, 0
	ld c, a
	ld hl, wWave
	add hl, bc
	ld a, [hl]
	push af
	and $F0
	ld b, a
	pop af
	and $0F
	swap a
	ld hl, wHexTiles
	ld d, 0
	ld e, a
	add hl, de
	push hl
	pop de
	ld a, b
	ld hl, wHexTiles
	ld b, 0
	ld c, a
	add hl, bc
	push hl
	pop bc
	ld hl, wNewHexTile
	ld a, $10
.hexLoop
	push af
	ld a, [bc]
	inc bc
	push bc
	ld b, a
	ld a, [de]
	inc de
	swap a
	or b
	ld [hli], a
	pop bc
	pop af
	dec a
	jr nz, .hexLoop
	ret

CopyHexTile:
	ld a, [wCursorPos]
	srl a
	swap a
	ld b, 0
	ld c, a
	ld hl, vChars2 + HEX_BASE_TILE * $10
	add hl, bc
	ld de, wNewHexTile
	rept $10
	put [hli], [de]
	inc de
	endr
	ret

DrawNumberTilemap:
	ld de, .numberTilemap
	ld hl, vBGMap0 + BG_WIDTH * NUMBER_Y + NUMBER_X
	ld bc, BG_WIDTH
.numberLoop
	ld a, [de]
	inc de
	and a
	jr z, .numbersDone
	ld [hl], a
	add hl, bc
	jr .numberLoop
.numbersDone
	ret

.numberTilemap:
	db "FEDCBA9876543210", 0

SetPalette:
	ld a, %11100100 ; quaternary: 3210
	ld [rOBP0], a
	ld [rOBP1], a
	ld [rBGP], a
	ret

KnobGraphics:
	INCBIN "gfx/knob.2bpp"

HexGraphics:
	INCBIN "gfx/hex.2bpp"

FontGraphics:
	INCBIN "gfx/font.2bpp"

ArrowGraphics:
	INCBIN "gfx/arrow.2bpp"
