DEF TEXTBOX_BASE_TILE EQU 1
DEF TEXTBOX_TL EQU $81 ; top left
DEF TEXTBOX_H  EQU $82 ; horizontal
DEF TEXTBOX_TR EQU $83 ; top right
DEF TEXTBOX_BL EQU $84 ; bottom left
DEF TEXTBOX_V  EQU $85 ; vertical
DEF TEXTBOX_BR EQU $86 ; bottom right

SECTION "Menu WRAM", WRAM0

wMenuCursor:    ds 1
wMenuWidth:     ds 1
wMenuMaxOption: ds 1
wMenuOptions:   ds 2
wMenuMap:       ds SCREEN_WIDTH * SCREEN_HEIGHT


SECTION "Menu", ROM0

; open menu with the options table at hl
; and default menu cursor position in a
; display inactive cursor at initial position if c flag is set
OpenMenu::
	push af
	ld [wMenuCursor], a
	put [wMenuOptions + 0], l
	put [wMenuOptions + 1], h
	call CalcMenuWidth
	call LoadTextBoxTiles
	call ClearMenuMap
	call DrawTextBox
	call LoadOptions
	call RefreshMenu
	put [rWY], 0
	put [rWX], SCREEN_WIDTH_PX + WX_OFS - 2
	call EnableWindow
	call ScrollWindowIn
	call PlaceMenuCursor
	pop af
	call c, PlaceInitialMenuCursor
.menuLoop
	call Joypad
	ld a, [wJoyPressed]
	je PAD_UP,   .pressedUp
	je PAD_DOWN, .pressedDown
	je PAD_A,    .pressedA
	je PAD_B,    .pressedB
	jr .menuLoop

.pressedUp
	ld a, [wMenuCursor]
	jz .isMin
	dec a
	ld [wMenuCursor], a
	call PlaceMenuCursor
.isMin
	jr .menuLoop

.pressedDown
	ld a, [wMenuCursor]
	ld hl, wMenuMaxOption
	je [hl], .isMax
	inc a
	ld [wMenuCursor], a
	call PlaceMenuCursor
.isMax
	jr .menuLoop

.pressedA
	call .closeMenu
	; do the thing
	put l, [wMenuOptions + 0]
	put h, [wMenuOptions + 1]
	inc hl
	inc hl
	ld a, [wMenuCursor]
	sla a
	sla a
	ldr bc, a
	add hl, bc
	ld a, [hli]
	ld h, [hl]
	ld l, a
	ld a, [wMenuCursor]
	call __hl__
	ld a, [wMenuCursor]
	ret

.pressedB
	call .closeMenu
	ld a, -1
	ret

.closeMenu
	call RemoveMenuCursors
	call ScrollWindowOut
	call DisableWindow
	ret

; calculate the inner width of the menu
; based on the longest label in the options at hl
; fix in the range [2, 18]
CalcMenuWidth:
	ld e, 0
.optionsLoop
	put c, [hli]
	put b, [hli]
	or c
	jr z, .done
	call CalcStringLength
	ld a, d
	jle e, .notLonger
	ld e, a
.notLonger
	inc hl
	inc hl
	jr .optionsLoop
.done
	ld a, e
	inc a ; plus one for arrow
	jge 2, .bigEnough
	ld a, 2
.bigEnough
	jle 18, .smallEnough
	ld a, 18
.smallEnough
	ld [wMenuWidth], a
	ret

; return the length of 0-terminated string at bc in d
CalcStringLength:
	ld d, 0
.loop
	ld a, [bc]
	inc bc
	jz .done
	inc d
	jr .loop
.done
	ret

LoadTextBoxTiles:
	ld bc, TextBoxTiles
	ld de, vChars1 + TEXTBOX_BASE_TILE * TILE_SIZE
	ld a, 6
	call QueueGfx
	ret

ClearMenuMap:
	fill wMenuMap, SCREEN_WIDTH * SCREEN_HEIGHT, 0
	ret

RefreshMenu:
	call WaitForCallbacks
	callback RefreshMenu_1
	call WaitForCallbacks
	callback RefreshMenu_2
	call WaitForCallbacks
	callback RefreshMenu_3
	call WaitForCallbacks
	callback RefreshMenu_4
	call WaitForCallbacks
	callback RefreshMenu_5
	call WaitForCallbacks
	callback RefreshMenu_6
	call WaitForCallbacks
	ret

RefreshMenu_1:
	ld de, wMenuMap + SCREEN_WIDTH * 0
	ld hl, TILEMAP1 + TILEMAP_WIDTH * 0
	jr RefreshMenu_

RefreshMenu_2:
	ld de, wMenuMap + SCREEN_WIDTH * 3
	ld hl, TILEMAP1 + TILEMAP_WIDTH * 3
	jr RefreshMenu_

RefreshMenu_3:
	ld de, wMenuMap + SCREEN_WIDTH * 6
	ld hl, TILEMAP1 + TILEMAP_WIDTH * 6
	jr RefreshMenu_

RefreshMenu_4:
	ld de, wMenuMap + SCREEN_WIDTH * 9
	ld hl, TILEMAP1 + TILEMAP_WIDTH * 9
	jr RefreshMenu_

RefreshMenu_5:
	ld de, wMenuMap + SCREEN_WIDTH * 12
	ld hl, TILEMAP1 + TILEMAP_WIDTH * 12
	jr RefreshMenu_

RefreshMenu_6:
	ld de, wMenuMap + SCREEN_WIDTH * 15
	ld hl, TILEMAP1 + TILEMAP_WIDTH * 15
;	jr RefreshMenu_

RefreshMenu_:
	ld b, SCREEN_HEIGHT / 6
.outerLoop
	ld c, SCREEN_WIDTH
.innerLoop
	put [hli], [de]
	inc de
	dec c
	jr nz, .innerLoop
	dec b
	jr z, .done
	push bc
	ld bc, TILEMAP_WIDTH - SCREEN_WIDTH
	add hl, bc
	pop bc
	jr .outerLoop
.done
	ret

DrawTextBox:
	put c, [wMenuWidth]
	ld b, SCREEN_HEIGHT - 2 ; menu height
	ld a, SCREEN_WIDTH - 2
	sub c
	ldr de, a
	ld hl, wMenuMap
	push bc

	; top row
	put [hli], TEXTBOX_TL
	ld a, TEXTBOX_H
.loop1
	ld [hli], a
	dec c
	jr nz, .loop1
	put [hli], TEXTBOX_TR

	; middle rows
	pop bc
	ld a, b
	ld b, 0
	push bc
	add hl, de
.loop2
	push af
	put [hli], TEXTBOX_V
	add hl, bc
	ld [hli], a
	add hl, de
	pop af
	dec a
	jr nz, .loop2

	; bottom row
	pop bc
	put [hli], TEXTBOX_BL
	ld a, TEXTBOX_H
.loop3
	ld [hli], a
	dec c
	jr nz, .loop3
	put [hli], TEXTBOX_BR
.done
	ret

LoadOptions:
	put [wMenuMaxOption], -1
	put e, [wMenuOptions + 0]
	put d, [wMenuOptions + 1]
	ld hl, wMenuMap + SCREEN_WIDTH * 1 + 2
.optionsLoop
	push hl
	put c, [de]
	inc de
	put b, [de]
	inc de
	or c
	jr z, .done
	ld a, [wMenuWidth]
	dec a
	call PutString
	ld hl, wMenuMaxOption
	inc [hl]
	pop hl
	ld bc, SCREEN_WIDTH * 2
	add hl, bc
	inc de
	inc de
	jr .optionsLoop
.done
	pop hl
	ret

; copy the 0-terminated string at bc to hl
; copy no more than 'a' characters
PutString:
	push af
	jz .done
	ld a, [bc]
	inc bc
	jz .done
	ld [hli], a
	pop af
	dec a
	jr PutString
.done
	pop af
	ret

PlaceMenuCursor:
	put d, [wMenuCursor]
	ld e, TILE_WIDTH * 2
	call Multiply
	ld a, TILE_WIDTH * 3
	add l
	ld [wOAM + 4], a
	put b, [wMenuWidth]
	ld a, SCREEN_WIDTH
	sub b
	ld d, a
	ld e, TILE_WIDTH
	call Multiply
	ld a, l
	ld [wOAM + 5], a
	put [wOAM + 6], 1
	put [wOAM + 7], 0
	ret

PlaceInitialMenuCursor:
	put d, [wMenuCursor]
	ld e, TILE_WIDTH * 2
	call Multiply
	ld a, TILE_WIDTH * 3
	add l
	ld [wOAM + 8], a
	put b, [wMenuWidth]
	ld a, SCREEN_WIDTH
	sub b
	ld d, a
	ld e, TILE_WIDTH
	call Multiply
	ld a, l
	ld [wOAM + 9], a
	put [wOAM + 10], 3
	put [wOAM + 11], 0
	ret

RemoveMenuCursors:
	xor a
	ld hl, wOAM + 4
	ld [hli], a
	ld [hli], a
	ld [hli], a
	ld [hli], a
	ld [hli], a
	ld [hli], a
	ld [hli], a
	ld [hli], a
	ret

ScrollWindowIn:
	ld a, [wMenuWidth]
	add 2
	ld d, a
	ld e, TILE_WIDTH
	call Multiply
	ld a, SCREEN_WIDTH_PX + WX_OFS
	sub l
	ld b, a
.scrollLoop
	ld a, [rWX]
	sub 6
	jle b, .done
	ld [rWX], a
	call WaitVBlank
	jr .scrollLoop
.done
	put [rWX], b
	ret

ScrollWindowOut:
	ld a, [rWX]
	add 6
	jge SCREEN_WIDTH_PX + WX_OFS - 2, .done
	ld [rWX], a
	call WaitVBlank
	jr ScrollWindowOut
.done
	put [rWX], SCREEN_WIDTH_PX + WX_OFS - 2
	ret

TextBoxTiles:
	INCBIN "gfx/textbox.2bpp"
