NUM_WAVES EQU 8

SECTION "Save SRAM", SRAM

sMarker: ds 2
sWaves:  ds WAVE_SIZE * NUM_WAVES


SECTION "Save", ROM0

; save current wave into slot a
SaveSAV::
	ld hl, sWaves
	ld bc, WAVE_SIZE
	call AddATimes
	push hl
	put [MBC3_SRAM], SRAM_ENABLE
	put [MBC3_SRAMBank], 0
	put [sMarker], "W"
	put [sMarker + 1], "F"
	ld hl, wWave
	pop de
	call CopyWave
	put [MBC3_SRAM], SRAM_DISABLE
	ret

; load current wave with slot a
LoadSAV::
	ld hl, sWaves
	ld bc, WAVE_SIZE
	call AddATimes
	put [MBC3_SRAM], SRAM_ENABLE
	put [MBC3_SRAMBank], 0
	call VerifySave
	jr c, .noSave
	ld de, wWave
	call CopyWave
	jr .done
.noSave
	call InitSAV
.done
	put [MBC3_SRAM], SRAM_DISABLE
	ret

VerifySave:
	ld a, [sMarker]
	jne "W", .noSave
	ld a, [sMarker + 1]
	jne "F", .noSave
	and a
	ret
.noSave
	scf
	ret

InitSAV:
	fill sWaves, WAVE_SIZE * NUM_WAVES, 0
	ret
