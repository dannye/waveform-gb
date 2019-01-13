INCLUDE "constants.asm"

KNOB_BASE_TILE  EQU 0
KNOB_TRACK_TILE EQU 1
KNOB_LEFT_TILE  EQU 2
KNOB_RIGHT_TILE EQU 3
KNOB_BOTH_TILE  EQU 4
KNOB_START_X    EQU 2
KNOB_START_Y    EQU 1
NUM_COLUMNS     EQU WAVE_SIZE
NUM_ROWS        EQU 1 << BITS_PER_WAVE_SAMPLE
KNOB_HEIGHT     EQU 1
KNOB_WIDTH      EQU 5

NUMBER_X EQU (KNOB_START_X) - 1
NUMBER_Y EQU KNOB_START_Y

FONT_BASE_TILE EQU $20
FONT_HEIGHT    EQU 6
FONT_WIDTH     EQU 16

HEX_BASE_TILE EQU $10
HEX_X         EQU KNOB_START_X
HEX_Y         EQU KNOB_START_Y + NUM_ROWS
HEX_HEIGHT    EQU 1
HEX_WIDTH     EQU 16

ARROW_TILE   EQU 0
ARROW_X      EQU 8 * KNOB_START_X + 6
ARROW_Y      EQU 8 * (KNOB_START_Y + 1)
ARROW_HEIGHT EQU 1
ARROW_WIDTH  EQU 4

MIN_ARROW_POS EQU 0
MAX_ARROW_POS EQU (NUM_WAVE_SAMPLES) - 1


SECTION "Main WRAM", WRAM0

wWave::      ds WAVE_SIZE
wCursorPos:  ds 1
wKnobColumn: ds NUM_ROWS
wHexTiles:   ds BYTES_PER_TILE * HEX_WIDTH
wNewHexTile: ds BYTES_PER_TILE


SECTION "Main", ROM0

Main::
	call Setup
.loop
	call WaitVBlank
	call Update
	jr .loop

Update:
	call Joypad
	ld c, 0
	ld a, [wCursorPos]
	jbz 0, .even
	ld c, 1
.even
	srl a
	ldr de, a
	ld hl, wWave
	add hl, de
	ld a, [wJoyPressed]
	je D_UP,    .pressedUp
	je D_DOWN,  .pressedDown
	je D_LEFT,  .pressedLeft
	je D_RIGHT, .pressedRight
	je START,   .pressedStart
	ret

.pressedUp
	ld a, [hl]
	jb 0, c, .skipOdd1
	swap a ; skip for odd knobs
.skipOdd1
	and $0F
	je $F, .isMax
	inc a
	jb 0, c, .skipOdd2
	swap a ; skip for odd knobs
.skipOdd2
	ld b, a
	ld a, [hl]
	jb 0, c, .skipOdd3
	and $0F ; for even knobs
	jr .skipEven1
.skipOdd3
	and $F0 ; for odd knobs
.skipEven1
	or b
	ld [hl], a
	jr .afterWaveChange
.isMax
	ret

.pressedDown
	ld a, [hl]
	jb 0, c, .skipOdd4
	swap a ; skip for odd knobs
.skipOdd4
	and $0F
	jz .isMin
	dec a
	jb 0, c, .skipOdd5
	swap a ; skip for odd knobs
.skipOdd5
	ld b, a
	ld a, [hl]
	jb 0, c, .skipOdd6
	and $0F ; for even knobs
	jr .skipEven2
.skipOdd6
	and $F0 ; for odd knobs
.skipEven2
	or b
	ld [hl], a
	jr .afterWaveChange
.isMin
	ret

.afterWaveChange
	call UpdateKnobTilemap_Defer
	call UpdateHexTile_Defer
	call UpdateWave
	call PlayNote
	ret

.pressedLeft
	ld a, [wCursorPos]
	dec a
	jne (MIN_ARROW_POS) - 1, .noUnderflow
	ld a, MAX_ARROW_POS
.noUnderflow
	ld [wCursorPos], a
	ld d, a
	ld e, 4
	call Multiply
	ld bc, ARROW_X
	add hl, bc
	put [wOAM + 1], l
	ret

.pressedRight
	ld a, [wCursorPos]
	inc a
	jne MAX_ARROW_POS + 1, .noOverflow
	ld a, MIN_ARROW_POS
.noOverflow
	ld [wCursorPos], a
	ld d, a
	ld e, 4
	call Multiply
	ld bc, ARROW_X
	add hl, bc
	put [wOAM + 1], l
	ret

.pressedStart
	ld a, [wCursorPos]
	jle 17, .noHide
	; push arrow oam data
	ld a, [wOAM + 0]
	push af
	ld a, [wOAM + 1]
	push af
	put [wOAM + 0], 0
	put [wOAM + 1], 0
.noHide
	put [wOAM + 2], 2
	ld a, 7
	ld hl, StartMenuOptions
	call OpenMenu
	ld a, [wCursorPos]
	jle 17, .noShow
	; pop arrow oam data
	pop af
	ld [wOAM + 1], a
	pop af
	ld [wOAM + 0], a
.noShow
	put [wOAM + 2], 0
	ret

StartMenuOptions:
	dw SaveLabel,   SaveAction
	dw ResetLabel,  ResetAction
	dw CancelLabel, CancelAction
	dw 0

SaveLabel:
	db "Save", 0

SaveAction:
	call SaveSAV
	ret

ResetLabel:
	db "Reset", 0

ResetAction:
	call LoadDefaultWave
	call RefreshWave
	call PlayNote
	ret

RefreshWave:
	call WaitForCallbacks
	ld a, [wCursorPos]
	push af
	put [wCursorPos], 0
	ld c, NUM_COLUMNS
.refreshLoop
	push bc
	call UpdateKnobTilemap_Defer
	call UpdateHexTile_Defer
	call WaitForCallbacks
	ld a, [wCursorPos]
	add 2
	ld [wCursorPos], a
	pop bc
	dec c
	jr nz, .refreshLoop
	pop af
	ld [wCursorPos], a
	ret

CancelLabel:
	db "Cancel", 0

CancelAction:
	ret

UpdateWave:
	ld hl, wWave
	call LoadWave
	ret

Setup:
	call InitSound
	call LoadSAV
	call UpdateWave

	call DisableLCD

	ld bc, KnobGraphics
	ld de, vChars2 + KNOB_BASE_TILE * BYTES_PER_TILE
	ld a, KNOB_WIDTH * KNOB_HEIGHT
	call LoadGfx

	ld bc, HexGraphics
	ld de, wHexTiles
	ld a, HEX_WIDTH * HEX_HEIGHT
	call LoadGfx

	ld bc, FontGraphics
	ld de, vChars2 + FONT_BASE_TILE * BYTES_PER_TILE
	ld a, FONT_WIDTH * FONT_HEIGHT
	call LoadGfx

	ld bc, ArrowsGraphics
	ld de, vChars0 + ARROW_TILE * BYTES_PER_TILE
	ld a, ARROW_WIDTH * ARROW_HEIGHT
	call LoadGfx

	put [wCursorPos], 0
	REPT NUM_COLUMNS
	call UpdateKnobTilemap
	call UpdateHexTile
	ld a, [wCursorPos]
	add 2
	ld [wCursorPos], a
	ENDR
	put [wCursorPos], MIN_ARROW_POS
	call DrawNumberTilemap

	ld hl, vBGMap0 + BG_WIDTH * HEX_Y + HEX_X
	ld a, HEX_BASE_TILE
	REPT NUM_COLUMNS
	ld [hli], a
	inc a
	ENDR

	ld hl, wOAM
	put [hli], ARROW_Y
	put [hli], ARROW_X + MIN_ARROW_POS * 4
	put [hli], ARROW_TILE
	put [hli], $00

	call SetPalette

	call EnableLCD

	call PlayNote
	ret

; update knob tilemap and copy to vram immediately
UpdateKnobTilemap:
	call UpdateKnobTilemap_
	call CopyKnobTilemap
	ret

; update knob tilemap and copy to vram on vblank
UpdateKnobTilemap_Defer:
	call UpdateKnobTilemap_
	callback CopyKnobTilemap
	ret

; update knob tilemap by updating the current column
; clear the column, then place the left and right knob
; use KNOB_BOTH_TILE if both knobs have same value
UpdateKnobTilemap_:
	ld hl, wKnobColumn
	ld a, KNOB_TRACK_TILE
	REPT NUM_ROWS
	ld [hli], a
	ENDR
	ld a, [wCursorPos]
	srl a
	ldr bc, a
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
	ldr bc, a
	ld hl, wKnobColumn
	add hl, bc
	ld [hl], KNOB_LEFT_TILE
	pop af
	ld b, a
	ld a, $0F
	sub b
	ldr bc, a
	ld hl, wKnobColumn
	add hl, bc
	ld [hl], KNOB_RIGHT_TILE
	jne d, .different
	ld [hl], KNOB_BOTH_TILE
.different
	ret

; copy the updated knob column to vram
CopyKnobTilemap:
	ld a, [wCursorPos]
	srl a
	ldr bc, a
	ld hl, vBGMap0 + BG_WIDTH * KNOB_START_Y + KNOB_START_X
	add hl, bc
	ld de, wKnobColumn
	ld bc, BG_WIDTH
	REPT NUM_ROWS
	put [hl], [de]
	add hl, bc
	inc de
	ENDR
	ret

; update hex digit tile and copy to vram immediately
UpdateHexTile:
	call UpdateHexTile_
	call CopyHexTile
	ret

; update hex digit tile and copy to vram on vblank
UpdateHexTile_Defer:
	call UpdateHexTile_
	callback CopyHexTile
	ret

; update hex digit tile by using the values of the left
; and right knob of the current column
UpdateHexTile_:
	ld a, [wCursorPos]
	srl a
	ldr bc, a
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
	ldr de, a
	add hl, de
	push hl
	pop de
	ld a, b
	ld hl, wHexTiles
	ldr bc, a
	add hl, bc
	push hl
	pop bc

	; combine tiles at bc and de
	; left half of tile at bc gets placed in left half of tile at hl
	; left half of tile at de gets placed in right half of tile at hl
	ld hl, wNewHexTile
	ld a, BYTES_PER_TILE
.hexLoop
	push af
	ld a, [bc]
	inc bc
	push bc
	and $F0
	ld b, a
	ld a, [de]
	inc de
	and $F0
	swap a
	or b
	ld [hli], a
	pop bc
	pop af
	dec a
	jr nz, .hexLoop
	ret

; copy the updated hex digit tile to vram
CopyHexTile:
	ld a, [wCursorPos]
	srl a
	swap a
	ldr bc, a
	ld hl, vChars2 + HEX_BASE_TILE * BYTES_PER_TILE
	add hl, bc
	ld de, wNewHexTile
	REPT BYTES_PER_TILE
	put [hli], [de]
	inc de
	ENDR
	ret

; draw the knob values to the left of the knob columns
DrawNumberTilemap:
	ld de, .numberTilemap
	ld hl, vBGMap0 + BG_WIDTH * NUMBER_Y + NUMBER_X
	ld bc, BG_WIDTH
.numberLoop
	ld a, [de]
	inc de
	jz .numbersDone
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

ArrowsGraphics:
	INCBIN "gfx/arrows.2bpp"
