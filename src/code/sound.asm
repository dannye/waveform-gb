section "sound wram", wram0

wPitch: ds 1
wOctave: ds 1


section "sound", rom0

InitSound::
	put [rNR52], %10000000 ; sound enabled
	put [rNR51], %01000100 ; all output for ch3
	put [rNR50], $77       ; stereo panning
	put [rNR34], %00000000 ; counter mode off
	put [rNR32], %00100000 ; 100% volume

	put [rNR30], %00000000 ; ch3 off

	ld a, 16
	ld hl, DefaultWave
	ld bc, wWave
	ld de, $FF30
.copyLoop
	push af
	put [bc], [hl]
	put [de], [hl]
	inc hl
	inc bc
	inc de
	pop af
	dec a
	jr nz, .copyLoop

	put [rNR30], %10000000 ; ch3 on

	put [wPitch], 0
	put [wOctave], 4
	call PlayNote
	ret

DefaultWave:
	db $01,$23,$45,$67,$89,$AB,$CD,$EF,$FE,$DC,$BA,$98,$76,$54,$32,$10

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
