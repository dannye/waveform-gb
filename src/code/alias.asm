SECTION "hl", ROM0
__hl__::
	jp hl

SECTION "de", ROM0
__de__::
	push de
	ret

SECTION "bc", ROM0
__bc__::
	push bc
	ret
