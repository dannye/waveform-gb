DEF NUM_WAVES EQU 8

SECTION "Save SRAM", SRAM

sMarker: ds 2
sWaves:  ds AUD3WAVE_SIZE * NUM_WAVES


SECTION "Save", ROM0

; save current wave into slot a
SaveSAV::
	ld hl, sWaves
	ld bc, AUD3WAVE_SIZE
	call AddATimes
	push hl
	put [rRAMG], RAMG_SRAM_ENABLE
	put [rRAMB], 0
	put [sMarker], 'W'
	put [sMarker + 1], 'F'
	ld hl, wWave
	pop de
	call CopyWave
	put [rRAMG], RAMG_SRAM_DISABLE
	ret

; load current wave with slot a
LoadSAV::
	ld hl, sWaves
	ld bc, AUD3WAVE_SIZE
	call AddATimes
	put [rRAMG], RAMG_SRAM_ENABLE
	put [rRAMB], 0
	call VerifySave
	jr c, .noSave
	ld de, wWave
	call CopyWave
	jr .done
.noSave
	call InitSAV
.done
	put [rRAMG], RAMG_SRAM_DISABLE
	ret

VerifySave:
	ld a, [sMarker]
	jne 'W', .noSave
	ld a, [sMarker + 1]
	jne 'F', .noSave
	and a
	ret
.noSave
	scf
	ret

InitSAV:
	fill sWaves, AUD3WAVE_SIZE * NUM_WAVES, 0
	ret
