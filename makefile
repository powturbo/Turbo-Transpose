# powturbo (c) Copyright 2013-2019
# ----------- Downloading + Compiling ----------------------
# Download or clone TurboTranspose:
# git clone git://github.com/powturbo/TurboTranspose.git 
# make

# Linux: "export CC=clang" "export CXX=clang". windows mingw: "set CC=gcc" "set CXX=g++" or uncomment the CC,CXX lines
CC ?= gcc
CXX ?= g++
#CC=clang-8
#CXX=clang++-8

#CC = gcc-8
#CXX = g++-8

#CC=powerpc64le-linux-gnu-gcc
#CXX=powerpc64le-linux-gnu-g++

DDEBUG=-DNDEBUG -s
#DDEBUG=-g

ifneq (,$(filter Windows%,$(OS)))
  OS := Windows
CFLAGS+=-D__int64_t=int64_t
else
  OS := $(shell uname -s)
  ARCH := $(shell uname -m)
ifneq (,$(findstring powerpc64le,$(CC)))
  ARCH = ppc64le
endif
ifneq (,$(findstring aarch64,$(CC)))
  ARCH = aarch64
endif
endif

#------ ARMv8 
ifeq ($(ARCH),aarch64)
CFLAGS+=-march=armv8-a
ifneq (,$(findstring clang, $(CC)))
MSSE=-O3 -mcpu=cortex-a72 -falign-loops -fomit-frame-pointer
else
MSSE=-O3 -mcpu=cortex-a72 -falign-loops -falign-labels -falign-functions -falign-jumps -fomit-frame-pointer
endif

else
# ----- Power9
ifeq ($(ARCH),ppc64le)
MSSE=-D__SSE__ -D__SSE2__ -D__SSE3__ -D__SSSE3__
MARCH=-march=power9 -mtune=power9
CFLAGS+=-DNO_WARN_X86_INTRINSICS
CXXFLAGS+=-DNO_WARN_X86_INTRINSICS
#------ x86_64 : minimum SSE = Sandy Bridge,  AVX2 = haswell 
else
MSSE=-march=corei7-avx -mtune=corei7-avx
# -mno-avx -mno-aes (add for Pentium based Sandy bridge)
CFLAGS+=-mssse3
MAVX2=-march=haswell
endif
endif

ifeq ($(OS),$(filter $(OS),Linux Darwin GNU/kFreeBSD GNU OpenBSD FreeBSD DragonFly NetBSD MSYS_NT Haiku))
#LDFLAGS+=-lpthread -lm
ifneq ($(OS),Darwin)
LDFLAGS+=-lrt
endif
endif

# Minimum CPU architecture 
#MARCH=-march=native
MARCH=$(MSSE)

ifeq ($(AVX2),1)
MARCH+=-mbmi2 -mavx2
CFLAGS+=-DUSE_AVX2
CXXFLAGS+=-DUSE_AVX2
else
AVX2=0
endif

#----------------------------------------------
ifeq ($(STATIC),1)
LDFLAGS+=-static
endif

#---------------------- make args --------------------------
ifeq ($(BLOSC),1)
DEFS+=-DBLOSC
endif

ifeq ($(LZ4),1)
CFLAGS+=-DLZ4 -Ilz4/lib 
endif

ifeq ($(BITSHUFFLE),1)
CFLAGS+=-DBITSHUFFLE -Iext/bitshuffle/lz4
endif

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

CFLAGS+=$(DDEBUG) -w -Wall -std=gnu99 -DUSE_THREADS  -fstrict-aliasing -Iext $(DEFS)
CXXFLAGS+=$(DDEBUG) -w -fpermissive -Wall -fno-rtti -Iext/FastPFor/headers $(DEFS)


all: tpbench

transpose.o: transpose.c
	$(CC) -O3 $(CFLAGS) $(COPT) -c -DUSE_SSE -falign-loops transpose.c -o transpose.o

transpose_sse.o: transpose.c
	$(CC) -O3 $(CFLAGS) $(COPT) -DSSE2_ON $(MSSE) -falign-loops -c transpose.c -o transpose_sse.o

transpose_avx2.o: transpose.c
	$(CC) -O3 $(CFLAGS) $(COPT) -DAVX2_ON $(MAVX2) -falign-loops -c transpose.c -o transpose_avx2.o


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
endif
ifeq ($(ARCH),aarch64)
CFLAGS+=-DSHUFFLE_NEON_ENABLED 
OB+=c-blosc2/blosc/shuffle-neon.o c-blosc2/blosc/bitshuffle-neon.o
else
CFLAGS+=-DSHUFFLE_SSE2_ENABLED 
OB+=c-blosc2/blosc/bitshuffle-sse2.o c-blosc2/blosc/shuffle-sse2.o
endif

else

ifeq ($(BITSHUFFLE),1)
CFLAGS+=-DBITSHUFFLE -Ibitshuffle/lz4 -DLZ4_ON

ifeq ($(ARCH),aarch64)
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

tpbench: $(OB) tpbench.o transpose.o
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

