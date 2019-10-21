# powturbo  (c) Copyright 2015-2019
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

CC ?= gcc
CXX ?= g++
#CC=clang-8
#CXX=clang++-8
#CC = gcc-8
#CXX = g++-8

ifeq ($(OS),Windows_NT)
  UNAME := Windows
CC=gcc
CXX=g++
else
  UNAME := $(shell uname -s)
ifeq ($(UNAME),$(filter $(UNAME),Darwin FreeBSD GNU/kFreeBSD Linux NetBSD SunOS))
LDFLAGS+=-lpthread -lrt 
UNAMEM := $(shell uname -m)
endif
endif

DDEBUG=-DNDEBUG -s
#DDEBUG=-g

COPT=-falign-loops -falign-functions
ifeq ($(UNAMEM),aarch64)
# ARMv8 
ifneq (,$(findstring clang, $(CC)))
MSSE=-march=armv8-a 
COPT= -mcpu=cortex-a72 -fomit-frame-pointer
else
MSSE=-march=armv8-a 
COPT=-mcpu=cortex-a72 -falign-labels -falign-jumps -fomit-frame-pointer
endif
#-floop-optimize 
else
#Minimum SSE = Sandy Bridge,  AVX2 = haswell 
MSSE=-march=corei7-avx -mtune=corei7-avx
# -mno-avx -mno-aes (add for Pentium based Sandy bridge)
MAVX2=-march=haswell
endif

# Minimum CPU architecture 
#MARCH=-march=native
MARCH=$(MSSE)
#MARCH=-march=broadwell 

all: tpbench

transpose.o: transpose.c
	$(CC) -O3 $(CFLAGS) $(COPT) -c -DUSE_SSE -falign-functions -falign-loops transpose.c -o transpose.o

transpose_sse.o: transpose.c
	$(CC) -O3 $(CFLAGS) $(COPT) -DSSE2_ON $(MSSE) -falign-functions -falign-loops -c transpose.c -o transpose_sse.o

transpose_avx2.o: transpose.c
	$(CC) -O3 $(CFLAGS) $(COPT) -DAVX2_ON $(MAVX2) -falign-functions -falign-loops -c transpose.c -o transpose_avx2.o


#-------- BLOSC + BitShuffle -----------------------
ifeq ($(BLOSC),1)
LDFLAGS+=-lpthread

CFLAGS+=-DBLOSC 
#-DPREFER_EXTERNAL_LZ4=ON -DHAVE_LZ4 -DHAVE_LZ4HC -Ibitshuffle/lz4

c-blosc2/blosc/shuffle-sse2.o: c-blosc2/blosc/shuffle-sse2.c
	$(CC) -O3 $(CFLAGS) -msse2 -c c-blosc2/blosc/shuffle-sse2.c -o c-blosc2/blosc/shuffle-sse2.o

c-blosc2/blosc/shuffle-generic.o: c-blosc2/blosc/shuffle-generic.c
	$(CC) -O3 $(CFLAGS) -c c-blosc2/blosc/shuffle-generic.c -o c-blosc2/blosc/shuffle-generic.o

c-blosc2/blosc/shuffle-avx2.o: c-blosc2/blosc/shuffle-avx2.c
	$(CC) -O3 $(CFLAGS) -mavx2 -c c-blosc2/blosc/shuffle-avx2.c -o c-blosc2/blosc/shuffle-avx2.o

c-blosc2/blosc/shuffle-neon.o: c-blosc2/blosc/shuffle-neon.c
	$(CC) -O3 $(CFLAGS) -flax-vector-conversions -c c-blosc2/blosc/shuffle-neon.c -o c-blosc2/blosc/shuffle-neon.o

c-blosc2/blosc/bitshuffle-neon.o: c-blosc2/blosc/bitshuffle-neon.c
	$(CC) -O3 $(CFLAGS) -flax-vector-conversions -c c-blosc2/blosc/bitshuffle-neon.c -o c-blosc2/blosc/bitshuffle-neon.o

OB+=c-blosc2/blosc/blosc2.o c-blosc2/blosc/blosclz.o c-blosc2/blosc/shuffle.o c-blosc2/blosc/shuffle-generic.o \
c-blosc2/blosc/bitshuffle-generic.o c-blosc2/blosc/btune.o c-blosc2/blosc/fastcopy.o c-blosc2/blosc/delta.o c-blosc2/blosc/timestamp.o c-blosc2/blosc/trunc-prec.o

ifeq ($(AVX2),1)
CFLAGS+=-DSHUFFLE_AVX2_ENABLED
OB+=c-blosc2/blosc/shuffle-avx2.o c-blosc2/blosc/bitshuffle-avx2.o
else
ifeq ($(UNAMEM),aarch64)
CFLAGS+=-DSHUFFLE_NEON_ENABLED 
OB+=c-blosc2/blosc/shuffle-neon.o c-blosc2/blosc/bitshuffle-neon.o
else
CFLAGS+=-DSHUFFLE_SSE2_ENABLED 
OB+=c-blosc2/blosc/bitshuffle-sse2.o c-blosc2/blosc/shuffle-sse2.o
endif
endif

else

ifeq ($(BITSHUFFLE),1)
CFLAGS+=-DBITSHUFFLE -Ibitshuffle/lz4 -DLZ4_ON

ifeq ($(UNAMEM),aarch64)
CFLAGS+=-DUSEARMNEON
else
ifeq ($(AVX2),1)
CFLAGS+=-DUSEAVX2
endif
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
