MACRO put
	ld a, \2
	ld \1, a
ENDM

MACRO ldx
	REPT _NARG
	ld \1, a
	SHIFT
	ENDR
ENDM

MACRO farcall
	rst FarCall
	db  bank(\1)
	dw  \1
ENDM

MACRO callback
	ld a, bank(\1)
	ld hl, \1
	call Callback
ENDM

MACRO task
	ld a, bank(\1)
	ld de, \1
	call CreateTask
ENDM

MACRO fill
	ld hl, \1
	ld bc, \2
.loop\@
	ld [hl], \3
	inc hl
	dec bc
	ld a, b
	or c
	jr nz, .loop\@
ENDM


; jp to \2 if a == \1
MACRO je
	IF "\1" === "0"
		and a
	ELSE
		cp \1
	ENDC
	jp z, \2
ENDM

; jp to \2 if a != \1
MACRO jne
	IF "\1" === "0"
		and a
	ELSE
		cp \1
	ENDC
	jp nz, \2
ENDM

; jp to \2 if a < \1
MACRO jl
	cp \1
	jp c, \2
ENDM

; jp to \2 if a > \1
MACRO jg
	cp \1
	jr z, .notGreater\@
	jr c, .notGreater\@
	jp , \2
.notGreater\@
ENDM

; jp to \2 if a <= \1
MACRO jle
	cp \1
	jp z, \2
	jp c, \2
ENDM

; jp to \2 if a >= \1
MACRO jge
	cp \1
	jp nc, \2
ENDM

; jp to \1 if a == 0
MACRO jz
	je 0, \1
ENDM

; jp to \1 if a != 0
MACRO jnz
	jne 0, \1
ENDM

; jp to \3 if bit \1 of register \2 == 1
; or
; jp to \2 if bit \1 of register a == 1
MACRO jb
	IF _NARG > 2
		bit \1, \2
		jp nz, \3
	ELSE
		bit \1, a
		jp nz, \2
	ENDC
ENDM

; jp to \3 if bit \1 of register \2 == 0
; or
; jp to \2 if bit \1 of register a == 0
MACRO jbz
	IF _NARG > 2
		bit \1, \2
		jp z, \3
	ELSE
		bit \1, a
		jp z, \2
	ENDC
ENDM

; ld 8-bit register \2 into 16-bit register \1
MACRO ldr
	IF "\1" === "bc"
		ld c, \2
		ld b, 0
	ENDC
	IF "\1" === "de"
		ld e, \2
		ld d, 0
	ENDC
	IF "\1" === "hl"
		ld l, \2
		ld h, 0
	ENDC
ENDM


MACRO RGB
	dw (\1) + (\2) << 5 + (\3) << 10
ENDM


MACRO enum_start
	IF _NARG
		DEF __enum__ = \1
	ELSE
		DEF __enum__ = 0
	ENDC
ENDM

MACRO enum
	REPT _NARG
		DEF \1 = __enum__
		DEF __enum__ = __enum__ + 1
	SHIFT
	ENDR
ENDM
