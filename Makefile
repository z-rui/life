CC=gcc
CFLAGS=-Wall -ggdb3
CFLAGS+=-DNDEBUG -O3 -fwhole-program
LIBS=-lcurses

TEX=tex
CHANGE=-

all: life life.pdf

life: life.o
	$(CC) -o $@ $(LDFLAGS) $^ $(LIBS)

%.o: %.c
	$(CC) -c -o $@ $(CFLAGS) $<

%.c: %.w $(CHANGE)
	ctangle $< $(CHANGE) $@

%.tex: %.w $(CHANGE)
	cweave $< $(CHANGE) $@

%.dvi: %.tex
	$(TEX) "\let\pdf+\input $<"

%.pdf: %.dvi
	dvipdfm $<

clean:
	rm -f life.{o,c,tex,dvi,idx,scn,toc,log}

.PHONY: all clean
