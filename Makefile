.POSIX:
.SUFFIXES: .asm

name = waveform
src  = src
obj  = src/main.o src/core.o

all: clean $(name).gb

clean:
	rm -f src/gfx/*.2bpp $(obj) $(name).gb $(name).sym

gfx:
	find src/gfx/ -iname "*.png" -exec sh -c 'rgbgfx -o $${1%.png}.2bpp $$1' _ {} \;

.asm.o:
	rgbasm -E -i $(src)/ -o $@ $<

$(name).gb: gfx $(obj)
	rgblink -n $(name).sym -o $@ $(obj)
	rgbfix -jv -i XXXX -k XX -l 0x33 -m 0x03 -p 0 -r 2 -t WAVEFORM $@
