Turbo Transpose compressor filter for binary data [![Build Status](https://travis-ci.org/powturbo/TurboTranspose.svg?branch=master)](https://travis-ci.org/powturbo/TurboTranspose)
======================================
* **Fastest transpose/shuffle**
  * **Byte/Nibble** transpose/shuffle for improving compression of binary data (ex. floating point data)
  * :sparkles: **Scalar/SIMD** Transpose/Shuffle 8,16,32,64,... bits
  * :+1: Dynamic CPU detection and **JIT scalar/sse/avx2** switching
  * 100% C (C++ headers), usage as simple as memcpy
* **Byte Transpose**
  * **Fastest** byte transpose 
* **Nibble Transpose** 
  * nearly as fast as byte transpose 
  * more efficient in most binary data files, up to **6 times!** faster than [Bitshuffle](https://github.com/kiyo-masui/bitshuffle)
  * more robust worst case scenario than bitshuffle
  * :new: compress (w/ lz77) better compression and **10 times** faster than one of the best floting-point compressors [SPDP](http://cs.txstate.edu/~burtscher/research/SPDPcompressor/)
* Scalar and SIMD **Transform**
  * **Delta** encoding for sorted lists
  * **Zigzag** encoding for unsorted lists
  * **Xor** encoding
  
### Transpose Benchmark:
- CPU: Skylake i7-6700 3.4GHz gcc 7.2 single thread 

#### - Speed test 
##### Benchmark w/ 16k buffer

**BOLD** = pareto frontier.<br>
c/t: cycles per 1000 bytes. E:Encode, D:Decode<br> 

        ./tpbench -s# file -B16K   (# = 8,4,2)
|Size |E Time c/t|D Time c/t|Transpose 64 bits **AVX2**|
|----------:|------:|------:|-----------------------------------|
|16.000|199|**134**|**tpbyte 8**|
|16.000|326|201|Blosc_shuffle 8|
|16.000|**394**|**260**|**tpnibble 8**|
|16.000|848|478|Bitshuffle 8|

|Size |E Time c/t|D Time c/t|Transpose 32 bits **AVX2**|
|----------:|------:|------:|-----------------------------------|
|16.000|**121**|**102**|**tpbyte 4**|
|16.000|451|139|Blosc_shuffle 4|
|16.000|**345**|**229**|**tpnibble 4**|
|16.000|773|476|Bitshuffle 4|

|Size |E Time c/t|D Time c/t|Transpose 16 bits **AVX2**|
|----------:|------:|------:|-----------------------------------|
|16.000|**95**|**71**|**tpbyte 2**|
|16.000|640|108|Blosc_shuffle 2|
|16.000|**329**|**198**|**tpnibble 2**|
|16.000|758|1177|Bitshuffle 2|
|16.000|**67**|**67**|memcpy|


##### Transpose/Shuffle benchmark w/ **large** files.
MB/s: 1.000.000 bytes/second<br> 

        ./tpbench -s# file  (# = 8,4,2)
|Size |E Time MB/s|D Time MB/s|Transpose 64 bits **AVX2**|
|----------:|------:|------:|-----------------------------------|
|100.000.000|**8387**|**9408**|**tpbyte 8**|
|100.000.000|8134|8598|Blosc_shuffle 8 |
|100.000.000|**7797**|**9145**|**tpnibble 8**|
|100.000.000|3548|3459|Bitshuffle 8|
|100.000.000|**13366**|**13366**|memcpy|

|Size |E Time MB/s|D Time MB/s|Transpose 32 bits **AVX2**|
|----------:|------:|------:|-----------------------------------|
|100.000.000|**8398**|**9533**|**tpbyte 4**|
|100.000.000|8198|9307|**tpnibble 4**|
|100.000.000|8193|8796|Blosc_shuffle 4|
|100.000.000|3679|3666|Bitshuffle 4|

|Size |E Time MB/s|D Time MB/s|Transpose 16 bits **AVX2**|
|----------:|------:|------:|-----------------------------------|
|100.000.000|7878|**9542**|**tpbyte 2**|
|100.000.000|**8987**|9412|**tpnibble 2**|
|100.000.000|7739|9404|Blosc_shuffle 2|
|100.000.000|3879|2547|Bitshuffle 2|

#### - Compression test (transpose/shuffle+lz)
- [Scientific IEEE 754 32-Bit Single-Precision Floating-Point Datasets](http://cs.txstate.edu/~burtscher/research/datasets/FPsingle/)

        ./tpbench -s4 -z *.sp

|File       |File size  |lz4 %|TpByte+lz4|TpNibble+lz4|[Bitshuffle+lz4](#bitshuffle)|[SPDP](#spdp)|
|:----------|----------:|----:|---------:|-----------:|-------------:|-----:|
msg_bt		|133.194.716| 94.3|70.4      |__**66.4**__|73.9      |  70.0|
msg_lu		|97.059.484|100.4|77.1      |__**70.4**__|75.4      |  76.8|
msg_sppm	|139.497.932|11.7|__**11.6**__|12.6       |15.4      |  14.4|
msg_sp		|145.052.928|100.3|68.8      |__**63.7**__|68.1      |  67.9|
msg_sweep3d	|62.865.612| 98.7|35.8      |__**18.1**__|71.0      |  69.6|
num_brain	|70.920.000|100.4|76.5      |__**71.1**__|77.4      |  79.1|
num_comet	|53.673.984| 92.4|79.0      |__**77.6**__|82.1      |  84.5|
num_control	|79.752.372| 99.4|89.5      |90.7     |__**88.1**__ |  98.3|
num_plasma	| 17.544.800| 100.4| 0.7     |__**0.7**__ |75.5      |  30.7|
obs_error	| 31.080.408|  89.2|73.1     |__**70.0**__|76.9      |  78.3|
obs_info	| 9.465.264|  93.6|70.2     |__**61.9**__|72.9      |  62.4|
obs_spitzer	|99.090.432| 98.3|__**90.4**__ |95.6     |93.6      |100.1|
obs_temp	| 19.967.136| 100.4|__**89.5**__|92.4     |91.0      |  99.4|

- Speed test (msg_sweep3d.sp)

File size |ratio %|C MB/s |D MB/s|Name|
---------:|------:|------:|-----:|:--------------|
 11348554 |18.1|**2276**|**4425**|**tpnibble+lz**|
 22489691 |35.8| 1670|3881|tpbyte+lz    |
 43471376 |69.2|  348| 402|SPDP         |
 44626407 |71.0| 1065|2101|bitshuffle+lz|

- [Scientific IEEE 754 64-Bit Double-Precision Floating-Point Datasets](http://cs.txstate.edu/~burtscher/research/datasets/FPdouble/)

        ./tpbench -s8 -z *.trace

|File       |File size  |lz4 |TpByte+lz4|TpNibble+lz4|Bitshuffle+lz4|SPDP|
|:----------|----------:|---:|---------:|-----------:|-------------:|------:|
msg_bt      |266.389.432|94.5|77.2|__**76.5**__|81.6| 77.9|
msg_lu      |194.118.968|100.4|82.7|__**81.0**__|83.7|83.3|
msg_sppm    |278.995.864|18.9|__**14.5**__|14.9|19.5| 21.5|
msg_sp      |290.105.856|100.4|79.2|__**77.5**__|80.2|78.8|
msg_sweep3d |125.731.224|98.7|50.7|__**36.7**__|80.4| 76.2|
num_brain   |141.840.000|100.4|82.6|__**81.1**__|84.5|87.8|
num_comet   |107.347.968|92.8|83.3|78.8|__**76.3**__| 86.5|
num_control |159.504.744|99.6|92.2|90.9|__**89.4**__| 97.6|
num_plasma  | 35.089.600|75.2|0.7|__**0.7**__|84.5|   77.3|
obs_error   | 62.160.816|78.7|81.0|__**77.5**__|84.4| 87.9|
obs_info    | 18.930.528|92.3|75.4|__**70.6**__|82.4| 81.7|
obs_spitzer |198.180.864|95.4|93.2|93.7|__**86.4**__|100.1|
obs_temp    | 39.934.272|100.4|93.1|93.8|__**91.7**__|98.0|


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
- clang (>=3.2)
- Windows: MinGW-w64
- Windows: Visual C++ (>=VS2008) 

###### Multithreading:
- All TurboTranspose functions are thread safe

### References:
- <a name="bitshuffle"></a>[Bitshuffle: Filter for improving compression of typed binary data.](https://github.com/kiyo-masui/bitshuffle)<br />
           :green_book:[ A compression scheme for radio data in high performance computing](https://arxiv.org/abs/1503.00638)
- <a name="blosc"></a>[Blosc: A blocking, shuffling and loss-less compression](https://github.com/Blosc/c-blosc)
- <a name="spdp"></a>[SPDP is a compression/decompression algorithm for binary IEEE 754 32/64 bits floating-point data](http://cs.txstate.edu/~burtscher/research/SPDPcompressor/)<br />
           :green_book:[ SPDP - An Automatically Synthesized Lossless Compression Algorithm for Floating-Point Data](http://cs.txstate.edu/~mb92/papers/dcc18.pdf) + [DCC 2018](http://www.cs.brandeis.edu//~dcc/Programs/Program2018.pdf)
- <a name="fpc"></a>:green_book:[ FPC: A High-Speed Compressor for Double-Precision Floating-Point Data](http://www.cs.txstate.edu/~burtscher/papers/tc09.pdf)

Last update:  2 MAR 2018
