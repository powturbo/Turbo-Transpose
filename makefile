# powturbo  (c) Copyright 2015-2017
CC ?= gcc
CXX ?= g++
#CC=clang
#CXX=clang++

#MARCH=-march=native
#MARCH=-march=broadwell

ifeq ($(OS),Windows_NT)
UNAME := Windows
CC=gcc
CXX=g++
else
UNAME := $(shell uname -s)
ifeq ($(UNAME),$(filter $(UNAME),Linux Darwin FreeBSD GNU/kFreeBSD))
LDFLAGS+=-lrt
endif
endif

CFLAGS+=-w -Wall
OB=transpose.o tpbench.o

ifneq ($(NSIMD),1)
OB+=transpose_sse.o
CFLAGS+=-DUSE_SSE

ifeq ($(AVX2),1)
MARCH+=-mavx2 -mbmi2
CFLAGS+=-DUSE_AVX2
OB+=transpose_avx2.o 
endif

endif

all: tpbench

transpose.o: transpose.c
	$(CC) -O3 $(CFLAGS) -falign-loops=32 -c transpose.c -o transpose.o

transpose_sse.o: transpose.c
	$(CC) -O3 $(CFLAGS) -DSSE2_ON -mssse3 -falign-loops=32 -c transpose.c -o transpose_sse.o

transpose_avx2.o: transpose.c
	$(CC) -O3 $(CFLAGS) -DAVX2_ON -march=haswell -mavx2 -falign-functions=32 -falign-loops=32 -c transpose.c -o transpose_avx2.o

#-------- BLOSC + BitShuffle -----------------------
ifeq ($(BLOSC),1)
LDFLAGS+=-lpthread 
CFLAGS+=-DSHUFFLE_SSE2_ENABLED -DBLOSC 
#-DPREFER_EXTERNAL_LZ4=ON -DHAVE_LZ4 -DHAVE_LZ4HC -Ibitshuffle/lz4

c-blosc/blosc/shuffle-sse2.o: c-blosc/blosc/shuffle-sse2.c
	$(CC) -O3 $(CFLAGS) -msse2 -c c-blosc/blosc/shuffle-sse2.c -o c-blosc/blosc/shuffle-sse2.o

c-blosc/blosc/shuffle-generic.o: c-blosc/blosc/shuffle-generic.c
	$(CC) -O3 $(CFLAGS) -c c-blosc/blosc/shuffle-generic.c -o c-blosc/blosc/shuffle-generic.o

c-blosc/blosc/shuffle-avx2.o: c-blosc/blosc/shuffle-avx2.c
	$(CC) -O3 $(CFLAGS) -mavx2 -c c-blosc/blosc/shuffle-avx2.c -o c-blosc/blosc/shuffle-avx2.o

OB+=c-blosc/blosc/blosc.o c-blosc/blosc/blosclz.o c-blosc/blosc/shuffle.o c-blosc/blosc/shuffle-generic.o c-blosc/blosc/shuffle-sse2.o \
c-blosc/blosc/bitshuffle-generic.o c-blosc/blosc/bitshuffle-sse2.o

ifeq ($(AVX2),1)
CFLAGS+=-DSHUFFLE_AVX2_ENABLED
OB+=c-blosc/blosc/shuffle-avx2.o c-blosc/blosc/bitshuffle-avx2.o
endif

else

ifeq ($(BITSHUFFLE),1)
CFLAGS+=-DBITSHUFFLE -Ibitshuffle/lz4 -DLZ4_ON

ifeq ($(AVX2),1)
CFLAGS+=-DUSEAVX2
endif

OB+=bitshuffle/src/bitshuffle.o bitshuffle/src/iochain.o bitshuffle/src/bitshuffle_core.o
OB+=bitshuffle/lz4/lz4.o
endif

endif
#---------------

tpbench: $(OB)
	$(CC) $^ $(LDFLAGS) -o tpbench
 
.c.o:
	$(CC) -O3 $(MARCH) $(CFLAGS) $< -c -o $@

ifeq ($(OS),Windows_NT)
clean:
	del /S *.o
	del /S *.exe
else
clean:
	@find . -type f -name "*\.o" -delete -or -name "*\~" -delete -or -name "core" -delete
endif
