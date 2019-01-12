SECTION "Math", ROM0

; multiply d x e
; return result in hl
Multiply::
	ld hl, 0
	ld a, d
	ld d, 0
.loop
	cp 0
	jr z, .done
	add hl, de
	dec a
	jr .loop
.done
	ret
