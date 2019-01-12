SECTION "Save SRAM", SRAM

sMarker:: ds 2
sWave:: ds 16


SECTION "Save", ROM0

Save::
	put [MBC3_SRAM], SRAM_ENABLE
	put [MBC3_SRAMBank], 0
	put [sMarker], "W"
	put [sMarker + 1], "F"
	ld hl, wWave
	ld de, sWave
	REPT 16
	put [de], [hli]
	inc de
	ENDR
	put [MBC3_SRAM], SRAM_DISABLE
	ret

Load::
	put [MBC3_SRAM], SRAM_ENABLE
	put [MBC3_SRAMBank], 0
	call VerifySave
	jr c, .noSave
	ld hl, sWave
	ld de, wWave
	REPT 16
	put [de], [hli]
	inc de
	ENDR
.noSave
	put [MBC3_SRAM], SRAM_DISABLE
	ret

VerifySave::
	ld a, [sMarker]
	cp "W"
	jr nz, .noSave
	ld a, [sMarker + 1]
	cp "F"
	jr nz, .noSave
	and a
	ret
.noSave
	scf
	ret
