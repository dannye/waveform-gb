SECTION "Math", ROM0

; multiply d x e
; return result in hl
Multiply::
;	push af
	ld hl, 0
	ld a, d
	ld d, 0
	and a
.loop
	jr z, .done
	add hl, de
	dec a
	jr .loop
.done
;	pop af
	ret

; add bc to hl a times
AddATimes::
	and a
.loop
	jr z, .done
	add hl, bc
	dec a
	jr .loop
.done
	ret
