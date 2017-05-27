# nmake /f makefile.msc
# or
# nmake "AVX2=1" /f makefile.msc

.SUFFIXES: .c .obj .dllobj

CC = cl
LD = link
AR = lib
CFLAGS = /MD /O2 -I.

LIB_LIB = libtp.lib
LIB_DLL = tp.dll
LIB_IMP = tp.lib

OBJS = transpose.obj transpose_sse.obj

!IF "$(AVX2)" == "1"
OBJS = $(OBJS) transpose_avx2.obj
!endif

DLL_OBJS = $(OBJS:.obj=.dllobj)

all: $(LIB_LIB) tpbench.exe 

#$(LIB_DLL) $(LIB_IMP) 

transpose.obj: transpose.c
	$(CC) /O2 $(CFLAGS) /DUSE_SSE -c transpose.c /Fotranspose.obj

transpose_sse.obj: transpose.c
	$(CC) /O2 $(CFLAGS) /DSSE2_ON /D__SSE2__ /arch:SSE2 /c transpose.c /Fotranspose_sse.obj

transpose_avx2.obj: transpose.c
	$(CC) /O2 $(CFLAGS) /DAVX2_ON /D__AVX2__ /arch:avx2 /c transpose.c /Fotranspose_avx2.obj

.c.obj:
	$(CC) -c /Fo$@ /O2 $(CFLAGS) $**

.c.dllobj:
	$(CC) -c /Fo$@ /O2 $(CFLAGS) /DLIB_DLL $**

$(LIB_LIB): $(OBJS)
	$(AR) $(ARFLAGS) -out:$@ $(OBJS)

$(LIB_DLL): $(DLL_OBJS)
	$(LD) $(LDFLAGS) -out:$@ -dll -implib:$(LIB_IMP) $(DLL_OBJS)

$(LIB_IMP): $(LIB_DLL)

tpbench.exe: tpbench.obj vs/getopt.obj $(LIB_LIB)
	$(LD) $(LDFLAGS) -out:$@ $**

clean:
	-del *.dll *.exe *.exp *.obj *.dllobj *.lib *.manifest 2>nul
