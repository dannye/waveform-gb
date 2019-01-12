put: MACRO
	ld a, \2
	ld \1, a
ENDM

ldx: MACRO
	REPT _NARG
	ld \1, a
	SHIFT
	ENDR
ENDM

farcall: MACRO
	rst FarCall
	db  bank(\1)
	dw  \1
ENDM

callback: MACRO
	ld a, bank(\1)
	ld hl, \1
	call Callback
ENDM

task: MACRO
	ld a, bank(\1)
	ld de, \1
	call CreateTask
ENDM

fill: MACRO
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


RGB: MACRO
	dw (\1) + (\2) << 5 + (\3) << 10
ENDM


enum_start: MACRO
	IF _NARG
__enum__ = \1
	ELSE
__enum__ = 0
	ENDC
ENDM

enum: MACRO
	REPT _NARG
\1 = __enum__
__enum__ = __enum__ + 1
	SHIFT
	ENDR
ENDM
