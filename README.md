Turbo Transpose compressor filter for binary data [![Build Status](https://travis-ci.org/powturbo/TurboTranspose.svg?branch=master)](https://travis-ci.org/powturbo/TurboTranspose)
======================================
* **TurboTranspose: Fastest byte/Nibble transpose/shuffle**
  * **Byte/Nibble** transpose/shuffle for improving compression of binary data (ex. floating point data)
  * :sparkles: **Scalar/SIMD** Transpose/Shuffle 8,16,32,64,... bits
  * :+1: Dynamic CPU detection and **JIT scalar/sse/avx2** switching
  * 100% C (C++ headers), usage as simple as memcpy
<p>
* **Byte Transpose**
  * **Fastest** byte transpose 
<p>
* **Nibble Transpose** 
  * nearly as fast as byte transpose 
  * more efficient in most binary data files, up to 6 times faster than [Bitshuffle](https://github.com/kiyo-masui/bitshuffle)
  * more robust worst case scenario than bitshuffle
  
### Transpose Benchmark:
- CPU: Skylake i7-6700 3.4GHz gcc 6.2 single thread 

###### Speed test 
- Benchmark w/ 16k buffer

c/t: cycles per 1000 bytes. E:Encode, D:Decode<br> 

        ./tpbench -s8 file -B16K
|Size |E Time c/t|D Time c/t|Transpose 16 bits **AVX2**|
|----------:|------:|------:|-----------------------------------|
|16.000|199|**134**|**tpbyte 8**|
|16.000|326|201|Blosc_shuffle 8|
|16.000|**394**|**260**|**tpnibble 8**|
|16.000|848|478|Bitshuffle 8|

        ./tpbench -s4 file -B16k
|Size |E Time c/t|D Time c/t|Transpose 32 bits **AVX2**|
|----------:|------:|------:|-----------------------------------|
|16.000|**121**|**102**|**tpbyte 4**|
|16.000|451|139|Blosc_shuffle 4|
|16.000|**345**|**229**|**tpnibble 4**|
|16.000|773|476|Bitshuffle 4|

        ./tpbench -s2 file -B16k
|Size |E Time c/t|D Time c/t|Transpose 64 bits **AVX2**|
|----------:|------:|------:|-----------------------------------|
|16.000|**95**|**71**|**tpbyte 2**|
|16.000|640|108|Blosc_shuffle 2|
|16.000|**329**|**198**|**tpnibble 2**|
|16.000|758|1177|Bitshuffle 2|
|16.000|**67**|**67**|memcpy|


- Transpose/Shuffle (No **PURE** cache) benchmark w/ **large** files.

MB/s: 1.000.000 bytes/second<br> 
**BOLD** = pareto frontier.<br>

        ./tpbench -s8 file
|Size |C Time MB/s|D Time MB/s|Transpose 64 bits **AVX2**|
|----------:|------:|------:|-----------------------------------|
|100.000.000|**8387**|**9408**|**tpbyte 8**|
|100.000.000|8134|8598|Blosc_shuffle 8 |
|100.000.000|**7797**|**9145**|**tpnibble 8**|
|100.000.000|3548|3459|Bitshuffle 8|
|100.000.000|**13366**|**13366**|memcpy|

        ./tpbench -s4 file
|Size |C Time MB/s|D Time MB/s|Transpose 32 bits **AVX2**|
|----------:|------:|------:|-----------------------------------|
|100.000.000|**8398**|**9533**|**tpbyte 4**|
|100.000.000|8198|9307|**tpnibble 4**|
|100.000.000|8193|8796|Blosc_shuffle 4|
|100.000.000|3679|3666|Bitshuffle 4|

        ./tpbench -s2 file
|Size |C Time MB/s|D Time MB/s|Transpose 16 bits **AVX2**|
|----------:|------:|------:|-----------------------------------|
|100.000.000|7878|**9542**|**tpbyte 2**|
|100.000.000|**8987**|9412|**tpnibble 2**|
|100.000.000|7739|9404|Blosc_shuffle 2|
|100.000.000|3879|2547|Bitshuffle 2|

###### Compression test (transpose/shuffle+lz4)
- [Scientific IEEE 754 64-Bit Double-Precision Floating-Point Datasets](http://cs.txstate.edu/~burtscher/research/datasets/FPdouble/)

        ./tpbench -s8 -z *.trace
|File|File size|lz4 only|TpByte %|TpNibble %|Bitshuffle %|
|:-------------|---------:|------:|------:|-----:|-----:|
msg_bt|266.389.432|94.5|77.2|__**76.5**__|81.6|
msg_lu|194.118.968|100.4|82.7|__**81.0**__|83.7|
msg_sp|290.105.856|100.4|79.2|__**77.5**__|80.2|
msg_sppm|278.995.864|18.9|__**14.5**__|14.9|19.5|
msg_sweep3d|125.731.224|98.7|50.7|__**36.7**__|80.4|
num_brain|141.840.000|100.4|82.6|__**81.1**__|84.5|
num_comet|107.347.968|92.8|83.3|78.8|__**76.3**__|
num_control|159.504.744|99.6|92.2|90.9|__**89.4**__|
num_plasma|35.089.600|75.2|0.7|__**0.7**__|84.5|
obs_error|62.160.816|78.7|81.0|__**77.5**__|84.4|
obs_info|18.930.528|92.3|75.4|__**70.6**__|82.4|
obs_spitzer|198.180.864|95.4|93.2|93.7|__**86.4**__|
obs_temp|39.934.272|100.4|93.1|93.8|__**91.7**__|


### Compile:

  		git clone git://github.com/powturbo/TurboTranspose.git
        cd TurboTranspose
  		make
        or
  		make AVX2=1
		
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
  >**void tp4enc(      unsigned char *in, unsigned n, unsigned char *out, unsigned esize);<br>
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

###### Multithreading:
- All TurboTranspose functions are thread safe

### References:
- [Bitshuffle](https://github.com/kiyo-masui/bitshuffle)
- [Blosc](https://github.com/Blosc/c-blosc)

Last update:  16 MAR 2017

