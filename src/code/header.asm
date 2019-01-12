SECTION "Entry", ROM0[$100]

	; This is the entry point to the program.

	nop
	jp Init


SECTION "Header", ROM0[$104]

	; The header is created by rgbfix.
	; The space here is allocated as a placeholder.

	ds $150 - $104
