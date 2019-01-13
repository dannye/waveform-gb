SECTION "Save SRAM", SRAM

sMarker: ds 2
sWave:   ds WAVE_SIZE


SECTION "Save", ROM0

SaveSAV::
	put [MBC3_SRAM], SRAM_ENABLE
	put [MBC3_SRAMBank], 0
	put [sMarker], "W"
	put [sMarker + 1], "F"
	ld hl, wWave
	ld de, sWave
	call CopyWave
	put [MBC3_SRAM], SRAM_DISABLE
	ret

LoadSAV::
	put [MBC3_SRAM], SRAM_ENABLE
	put [MBC3_SRAMBank], 0
	call VerifySave
	jr c, .noSave
	ld hl, sWave
	ld de, wWave
	call CopyWave
.noSave
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
