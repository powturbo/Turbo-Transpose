# nmake /f makefile.msc
# or
# nmake "AVX2=1" /f makefile.msc

.SUFFIXES: .c .obj .sobj

CC = cl
LD = link
AR = lib
CFLAGS = /MD /O2 -I.

LIB_LIB = libtp.lib
LIB_DLL = tp.dll
LIB_IMP = tp.lib

OBJS = transpose.obj

!if "$(NSIMD)" == "1"
!else
OBJS = $(OBJS) transpose_sse.obj
CFLAGS = $(CFLAGS) /DUSE_SSE /D__SSE2__

!IF "$(AVX2)" == "1"
CFLAGS = $(CFLAGS) /DUSE_AVX2
OBJS = $(OBJS) transpose_avx2.obj
!endif

!endif

DLL_OBJS = $(OBJS:.obj=.sobj)

all: $(LIB_LIB) $(LIB_DLL) tpbench.exe tpbenchdll.exe 

#$(LIB_DLL): $(LIB_IMP) 

transpose.obj: transpose.c
	$(CC) /O2 $(CFLAGS) /DUSE_SSE -c transpose.c /Fotranspose.obj

transpose_sse.obj: transpose.c
	$(CC) /O2 $(CFLAGS) /DSSE2_ON /D__SSE2__ /arch:SSE2 /c transpose.c /Fotranspose_sse.obj

transpose_avx2.obj: transpose.c
	$(CC) /O2 $(CFLAGS) /DAVX2_ON /D__AVX2__ /arch:avx2 /c transpose.c /Fotranspose_avx2.obj

transpose.sobj: transpose.c
	$(CC) /O2 $(CFLAGS) /DLIB_DLL=1 /DUSE_SSE -c transpose.c /Fotranspose.sobj

transpose_sse.sobj: transpose.c
	$(CC) /O2 $(CFLAGS) /DLIB_DLL=1 /DSSE2_ON /D__SSE2__ /arch:SSE2 /c transpose.c /Fotranspose_sse.sobj

transpose_avx2.sobj: transpose.c
	$(CC) /O2 $(CFLAGS) /DLIB_DLL=1 /DAVX2_ON /D__AVX2__ /arch:avx2 /c transpose.c /Fotranspose_avx2.sobj

tpbench.sobj: tpbench.c
	$(CC) /O2 $(CFLAGS) /DLIB_DLL -c tpbench.c /Fotpbench.sobj

.c.obj:
	$(CC) -c /Fo$@ /O2 $(CFLAGS) $**

.c.sobj:
	$(CC) -c /Fo$@ /O2 $(CFLAGS) /DLIB_DLL $**

$(LIB_LIB): $(OBJS)
	$(AR) $(ARFLAGS) -out:$@ $(OBJS)

$(LIB_DLL): $(DLL_OBJS)
	$(LD) $(LDFLAGS) -out:$@ -dll -implib:$(LIB_IMP) $(DLL_OBJS)

$(LIB_IMP): $(LIB_DLL)

tpbench.exe: tpbench.obj vs/getopt.obj $(LIB_LIB)
	$(LD) $(LDFLAGS) -out:$@ $**

tpbenchdll.exe: tpbench.sobj vs/getopt.obj
	$(LD) $(LDFLAGS) -out:$@ $** tp.lib

clean:
	-del *.dll *.exe *.exp *.lib *.obj *.sobj 2>nul
