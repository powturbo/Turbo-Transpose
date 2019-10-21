Integer + Floating Point Compression Filter[![Build Status](https://travis-ci.org/powturbo/TurboTranspose.svg?branch=master)](https://travis-ci.org/powturbo/TurboTranspose)
======================================
* **Fastest transpose/shuffle**
  * :new: (2019.11) **ALL** TurboTranspose functions now available under **64 bits ARMv8** including **NEON** SIMD.
  * **Byte/Nibble** transpose/shuffle for improving compression of binary data (ex. floating point data)
  * :sparkles: **Scalar/SIMD** Transpose/Shuffle 8,16,32,64,... bits
  * :+1: Dynamic CPU detection and **JIT scalar/sse/avx2** switching
  * 100% C (C++ headers), usage as simple as memcpy
* **Byte Transpose**
  * **Fastest** byte transpose 
  * :new: **2D,3D,4D** transpose 
* **Nibble Transpose** 
  * nearly as fast as byte transpose
  * more efficient, up to **10 times!** faster than [Bitshuffle](#bitshuffle)
  * :new: better compression (w/ lz77) and<br> **10 times!** faster than one of the best floating-point compressors [SPDP](#spdp)
  * can compress/decompress (w/ lz77) better and faster than other domain specific floating point compressors
* Scalar and SIMD **Transform**
  * **Delta** encoding for sorted lists
  * **Zigzag** encoding for unsorted lists
  * **Xor** encoding
  * :new: **lossy** floating point compression with user-defined error
  
### Transpose Benchmark:
- Benchmark Intel CPU: Skylake i7-6700 3.4GHz gcc 9.2 **single** thread
- Benchmark ARM: ARMv8 A73-ODROID-N2 1.8GHz

#### - Speed test 
##### Benchmark w/ 16k buffer

**BOLD** = pareto frontier.<br>
E:Encode, D:Decode<br> 

        ./tpbench -s# file -B16K   (# = 8,4,2)
|E Time cycles/byte|D Time cycles/byte|Transpose 64 bits **AVX2**|
|------:|------:|-----------------------------------|
|.199|**.134**|**tpbyte 8**|
|.326|.201|Blosc_shuffle 8|
|**.394**|**.260**|**tpnibble 8**|
|.848|.478|Bitshuffle 8|

|E Time cycles/byte|D Time cycles/byte|Transpose 32 bits **AVX2**|
|------:|------:|-----------------------------------|
|**.121**|**.102**|**tpbyte 4**|
|.451|.139|Blosc_shuffle 4|
|**.345**|**.229**|**tpnibble 4**|
|.773|.476|Bitshuffle 4|

|E Time cycles/byte|D Time cycles/byte|Transpose 16 bits **AVX2**|
|------:|------:|-----------------------------------|
|**.095**|**.071**|**tpbyte 2**|
|.640|.108|Blosc_shuffle 2|
|**.329**|**.198**|**tpnibble 2**|
|.758|1.177|Bitshuffle 2|
|**.067**|**.067**|memcpy|
---------------------------------------------------

|  E MB/s |    D MB/s| 16 bits ARM 2019.11|
|--------:|---------:|-----------------------------------|
|**8192**|**16384**|**tp_byte**|
|  8192|  8192| blosc shuffle  |
|  **1638**| **2341**|**tp_nibble**|
|   356|   287| blosc bitshuffle|
| 16384| 16384| memcpy     |

|  E MB/s |    D MB/s| 32 bits ARM 2019.11|
|--------:|---------:|-----------------------------------|
|**8192**|**8192**|**tp_byte**|
|  8192|  8192| blosc shuffle|
|**1820**|**2341**|**tp_nibble**|
|   372|   252| blosc bitshuffle|

|  E MB/s |    D MB/s| 64 bits ARM 2019.11|
|--------:|---------:|-----------------------------------|
|  4096|  **8192**|**tp_byte**|
|**5461**|  5461|**blosc shuffle**|
|**1490**|**1490**|**tp_nibble**|
|   372|   260| blosc bitshuffle|
---------------------------------------------------------------------------------

#### Transpose/Shuffle benchmark w/ **large** files (100MB).
MB/s: 1,000,000 bytes/second<br> 

        ./tpbench -s# file  (# = 8,4,2)
E Time MB/s|D Time MB/s|Transpose 64 bits **AVX2**|
|------:|------:|-----------------------------------|
|**8387**|**9408**|**tpbyte 8**|
|8134|8598|Blosc_shuffle 8 |
|**7797**|**9145**|**tpnibble 8**|
|3548|3459|Bitshuffle 8|
|**13366**|**13366**|memcpy|

|E Time MB/s|D Time MB/s|Transpose 32 bits **AVX2**|
|------:|------:|-----------------------------------|
|**8398**|**9533**|**tpbyte 4**|
|8198|9307|**tpnibble 4**|
|8193|8796|Blosc_shuffle 4|
|3679|3666|Bitshuffle 4|

|E Time MB/s|D Time MB/s|Transpose 16 bits **AVX2**|
|------:|------:|-----------------------------------|
|7878|**9542**|**tpbyte 2**|
|**8987**|9412|**tpnibble 2**|
|7739|9404|Blosc_shuffle 2|
|3879|2547|Bitshuffle 2|
----------------------------------------------------------

|  E MB/s |    D MB/s| 16 bits ARM 2019.11|
|--------:|---------:|-----------------------------------|
|**678**|**3802**|**tp_byte**|
|   678|  3771| blosc shuffle|
|**1360**|**2195**|**tp_nibble**|
|   357|   280| blosc bitshuffle|
|  3921|  3913| memcpy|

|  E MB/s |    D MB/s| 32 bits ARM 2019.11|
|--------:|---------:|-----------------------------------|
| 1744 |**3723**|**tp_byte**|
|  1769 | 3713| blosc shuffle|
|**1456**|**2295**|**tp_nibble**|
|   374 |  243| blosc bitshuffle|

|  E MB/s |    D MB/s| 64 bits ARM 2019.11|
|--------:|---------:|-----------------------------------|
|1558|**3300**|**tp_byte**
|**1581**| 3300|**blosc shuffle**
|**1162**|**1267**|**tp_nibble**
|   331 |  203| blosc bitshuffle

#### - Compression test (transpose/shuffle+lz4)
  :new: Download [IcApp](https://sites.google.com/site/powturbo/downloads) a new benchmark for [TurboPFor](https://github.com/powturbo/TurboPFor)+TurboTranspose<br>
  for testing allmost all integer and floating point file types.<br>
  Note: Lossy compression benchmark with icapp only.

- [Scientific IEEE 754 32-Bit Single-Precision Floating-Point Datasets](http://cs.txstate.edu/~burtscher/research/datasets/FPsingle/)

###### - Speed test (file msg_sweep3d)

   C size |ratio %|C MB/s |D MB/s|Name  AVX2|
---------:|------:|------:|-----:|:--------------|
 11,348,554 |18.1|**2276**|**4425**|**tpnibble+lz**|
 22,489,691 |35.8| 1670|3881|tpbyte+lz    |
 43,471,376 |69.2|  348| 402|SPDP         |
 44,626,407 |71.0| 1065|2101|bitshuffle+lz|
 62,865,612 |100.0|13300|13300|memcpy|

        ./tpbench -s4 -z *.sp

|File      |File size|lz %|Tp8lz|Tp4lz|[BS](#bitshuffle)lz|[spdp1](#spdp)||[spdp9](#spdp)|Tp4lzt|eTp4lzt|
|:---------|--------:|----:|------:|--------:|-------:|-----:|-|-------:|-------:|----:|
msg_bt	   |133194716| 94.3|70.4|**66.4**|73.9    | 70.0|` `|67.4|**54.7**|*32.4*|
msg_lu	   | 97059484|100.4|77.1      |**70.4**|75.4      | 76.8|` `|74.0|**61.0**|*42.2*|
msg_sppm   |139497932| 11.7|**11.6**|12.6       |15.4     | 14.4|` `|13.7|**9.0**|*5.6*|
msg_sp	   |145052928|100.3|68.8      |**63.7**|68.1      | 67.9|` `|65.3|**52.6**|*24.9*|
msg_sweep3d| 62865612| 98.7|35.8      |**18.1**|71.0      | 69.6|` `|13.7|**9.8**|*3.8*|
num_brain  | 70920000|100.4|76.5      |**71.1**|77.4      | 79.1|` `|73.9|**63.4**|*32.6*|
num_comet  | 53673984| 92.4|79.0      |**77.6**|82.1      | 84.5|` `|84.6|**70.1**|*41.7*|
num_control| 79752372| 99.4|89.5      |90.7     |**88.1** | 98.3|` `|98.5|**81.4**|*51.2*|
num_plasma | 17544800|100.4| 0.7     |**0.7** |75.5      |  30.7|` `|2.9|**0.3**|*0.2*|
obs_error  | 31080408| 89.2|73.1     |**70.0**|76.9      |  78.3|` `|49.4|**20.5**|*12.2*|
obs_info   |  9465264| 93.6|70.2     |**61.9**|72.9      |  62.4|` `|43.8|**27.3**|*15.1*|
obs_spitzer| 99090432| 98.3|**90.4** |95.6     |93.6      |100.1|` `|100.7|**80.2**|*52.3*|
obs_temp   | 19967136|100.4|**89.5**|92.4     |91.0      |  99.4|` `|100.1|**84.0**|*55.8*|

Tp8=Byte transpose, Tp4=Nibble transpose, lz = lz4<br />
eTp4Lzt = lossy compression with lzturbo and allowed error = 0.0001 (1e-4)<br />
*Slow but best compression:* SPDP9 and [lzt = lzturbo,39](https://github.com/powturbo/TurboBench)

- [Scientific IEEE 754 64-Bit Double-Precision Floating-Point Datasets](http://cs.txstate.edu/~burtscher/research/datasets/FPdouble/)

        ./tpbench -s8 -z *.trace

|File      |File size  |lz %|Tp8lz|Tp4lz|[BS](#bitshuffle)lz|[spdp1](#spdp)||[spdp9](#spdp)|Tp4lzt|eTp4lzt|
|:---------|----------:|----:|------:|--------:|-------:|-----:|-|-------:|-------:|----:|
msg_bt     |266389432|94.5|77.2|**76.5**|81.6| 77.9|` `|75.4|**69.9**|*16.0*|
msg_lu     |194118968|100.4|82.7|**81.0**|83.7|83.3|` `|79.6|**75.5**|*21.0*|
msg_sppm   |278995864|18.9|**14.5**|14.9|19.5| 21.5|` `|19.8|**11.2**|*2.8*|
msg_sp     |290105856|100.4|79.2|**77.5**|80.2|78.8|` `|77.1|**71.3**|*12.4*|
msg_sweep3d|125731224|98.7|50.7|**36.7**|80.4| 76.2|` `|33.2|**27.3**|*1.9*|
num_brain  |141840000|100.4|82.6|**81.1**|84.5|87.8|` `|83.3|**77.0**|*16.3*|
num_comet  |107347968|92.8|83.3|78.8|**76.3**| 86.5|` `|86.0|**69.8**|*21.2*|
num_control|159504744|99.6|92.2|90.9|**89.4**| 97.6|` `|98.9|**85.5**|*25.8*|
num_plasma | 35089600|75.2|0.7|**0.7**|84.5|   77.3|` `|3.0|**0.3**|*0.1*|
obs_error  | 62160816|78.7|81.0|**77.5**|84.4| 87.9|` `|62.3|**23.4**|*6.3*|
obs_info   | 18930528|92.3|75.4|**70.6**|82.4| 81.7|` `|51.2|**33.1**|*7.7*|
obs_spitzer|198180864|95.4|93.2|93.7|**86.4**|100.1|` `|102.4|**78.0**|*26.9*|
obs_temp   | 39934272|100.4|93.1|93.8|**91.7**|98.0|` `|97.4|**88.2**|*28.8*|

eTp4Lzt = lossy compression with allowed error = 0.0001<br />

### Compile:

        git clone git://github.com/powturbo/TurboTranspose.git
        cd TurboTranspose

##### Linux + Windows MingW 
 
  		make
        or
  		make AVX2=1

##### Windows Visual C++

  		nmake /f makefile.vs
        or
  		nmake AVX2=1 /f makefile.vs

		
+ benchmark with other libraries<br />
  download or clone [bitshuffle](https://github.com/kiyo-masui/bitshuffle) or [blosc](https://github.com/Blosc/c-blosc) and type

		make AVX2=1 BLOSC=1
		or
		make AVX2=1 BITSHUFFLE=1

### Testing:
  + benchmark "transpose" functions <br />

        ./tpbench [-s#] [-z] file
		s# = element size #=2,4,8,16,... (default 4) 
		-z = only lz77 compression benchmark (bitshuffle package mandatory)


### Function usage:

  **Byte transpose:** 
  >**void tpenc(      unsigned char *in, unsigned n, unsigned char *out, unsigned esize);<br>
  void tpdec(      unsigned char *in, unsigned n, unsigned char *out, unsigned esize)**<br />
  in     : input buffer<br />
  n      : number of bytes<br />
  out    : output buffer<br />
  esize  : element size in bytes (2,4,8,...)<br />

   
  **Nibble transpose:** 
  >**void tp4enc(   unsigned char *in, unsigned n, unsigned char *out, unsigned esize);<br>
  void tp4dec(      unsigned char *in, unsigned n, unsigned char *out, unsigned esize)**<br />
  in     : input buffer<br />
  n      : number of bytes<br />
  out    : output buffer<br />
  esize  : element size in bytes (2,4,8,...)<br />

### Environment:

###### OS/Compiler (64 bits):
- Linux: GNU GCC (>=4.6)
- Linux: Clang (>=3.2) 
- Windows: MinGW-w64 makefile
- Windows: Visual c++ (>=VS2008) - makefile.vs (for nmake)
- Windows: Visual Studio project file - vs/vs2017 - Thanks to [PavelP](https://github.com/pps83)
- Linux ARM: 64 bits aarch64 ARMv8:  gcc (>=6.3)
- Linux ARM: 64 bits aarch64 ARMv8:  clang

###### Multithreading:
- All TurboTranspose functions are thread safe

### References:
- <a name="bitshuffle"></a>[BS - Bitshuffle: Filter for improving compression of typed binary data.](https://github.com/kiyo-masui/bitshuffle)<br />
           :green_book:[ A compression scheme for radio data in high performance computing](https://arxiv.org/abs/1503.00638)
- <a name="blosc"></a>[Blosc: A blocking, shuffling and loss-less compression](https://github.com/Blosc/c-blosc)
- <a name="spdp"></a>[SPDP is a compression/decompression algorithm for binary IEEE 754 32/64 bits floating-point data](http://cs.txstate.edu/~burtscher/research/SPDPcompressor/)<br />
           :green_book:[ SPDP - An Automatically Synthesized Lossless Compression Algorithm for Floating-Point Data](http://cs.txstate.edu/~mb92/papers/dcc18.pdf) + [DCC 2018](http://www.cs.brandeis.edu//~dcc/Programs/Program2018.pdf)
- <a name="fpc"></a>:green_book:[ FPC: A High-Speed Compressor for Double-Precision Floating-Point Data](http://www.cs.txstate.edu/~burtscher/papers/tc09.pdf)

Last update: 19 Oct 2019
