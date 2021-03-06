SECTION "Sound WRAM", WRAM0

wPitch:  ds 1
wOctave: ds 1


SECTION "Sound", ROM0

InitSound::
	put [rNR52], %10000000 ; sound enabled
	put [rNR51], %01000100 ; all output for ch3
	put [rNR50], $77       ; stereo panning
	put [rNR34], %00000000 ; counter mode off
	put [rNR32], %00100000 ; 100% volume

	xor a
	call LoadDefaultWave

	put [rNR30], %10000000 ; ch3 on

	put [wPitch], 0
	put [wOctave], 4
	ret

; load default wave with index a
LoadDefaultWave::
	ld hl, DefaultWaves
	ld bc, WAVE_SIZE
	call AddATimes
	ld de, wWave
	call CopyWave
	ld hl, wWave
	call LoadWave
	ret

; load wave at hl to rWave
LoadWave::
	ld a, [rNR30]
	push af
	xor a
	ld [rNR30], a
	ld de, rWave
	call CopyWave
	pop af
	ld [rNR30], a
	ret

; copy wave at hl to de
CopyWave::
	ld c, WAVE_SIZE
.copyLoop
	put [de], [hli]
	inc de
	dec c
	jr nz, .copyLoop
	ret

DefaultWaves:
	db $89, $AB, $CD, $EF, $FE, $DC, $BA, $98, $76, $54, $32, $10, $01, $23, $45, $67
	db $88, $99, $AA, $BB, $CC, $DD, $EE, $FF, $00, $11, $22, $33, $44, $55, $66, $77
	db $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF, $00, $00, $00, $00, $00, $00, $00, $00
	db $8A, $CD, $EE, $FF, $FF, $EE, $DC, $A8, $75, $32, $11, $00, $00, $11, $23, $57
	db $8A, $CD, $EE, $FF, $FF, $EE, $DC, $A8, $01, $23, $45, $67, $89, $AB, $CD, $EF
	db $01, $23, $45, $67, $89, $AB, $CD, $EF, $02, $46, $8A, $CE, $02, $46, $8A, $CE
	db $00, $FF, $11, $EE, $22, $DD, $33, $CC, $44, $BB, $55, $AA, $66, $99, $77, $88
	db $00, $00, $EE, $EE, $22, $22, $CC, $CC, $44, $44, $AA, $AA, $66, $66, $88, $88

PlayNote::
	put b, [wOctave]
	ld a, [wPitch]
	call CalculateFrequency
	ld a, e
	ld [rNR33], a
	ld a, d
	res 6, a
	ld [rNR34], a
	ret

; return the frequency for note a, octave b in de
CalculateFrequency:
	ld h, 0
	ld l, a
	add hl, hl
	ld d, h
	ld e, l
	ld hl, Pitches
	add hl, de
	ld e, [hl]
	inc hl
	ld d, [hl]
	ld a, b
.loop
	cp 7
	jr z, .done
	sra d
	rr e
	inc a
	jr .loop
.done
	ret

Pitches:
	dw $F82C ; C_
	dw $F89D ; C#
	dw $F907 ; D_
	dw $F96B ; D#
	dw $F9CA ; E_
	dw $FA23 ; F_
	dw $FA77 ; F#
	dw $FAC7 ; G_
	dw $FB12 ; G#
	dw $FB58 ; A_
	dw $FB9B ; A#
	dw $FBDA ; B_
