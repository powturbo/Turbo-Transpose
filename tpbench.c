/**
    Copyright (C) powturbo 2013-2018
    GPL v2 License
  
    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License along
    with this program; if not, write to the Free Software Foundation, Inc.,
    51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

    - homepage : https://sites.google.com/site/powturbo/
    - github   : https://github.com/powturbo
    - twitter  : https://twitter.com/powturbo
    - email    : powturbo [_AT_] gmail [_DOT_] com
**/
#include <stdlib.h>
#include <stdio.h>

  #ifdef __APPLE__
#include <sys/malloc.h>
  #else
#include <malloc.h>
  #endif
  #ifdef _MSC_VER
#include "vs/getopt.h"
  #else
#include <getopt.h> 
  #endif

#include "conf.h"
//#define RDTSC_ON
#include "time_.h"

#include "transpose.h"

  #ifdef BITSHUFFLE
#include "bitshuffle/src/bitshuffle.h"
#include "bitshuffle/lz4/lz4.h"
  #endif
 
  #ifdef BLOSC
#include "c-blosc2/blosc/shuffle.h"
#include "c-blosc2/blosc/blosc2.h"
  #endif

int memcheck(unsigned char *in, unsigned n, unsigned char *cpy) { 
  int i;
  for(i = 0; i < n; i++)
    if(in[i] != cpy[i]) {
      printf("ERROR in[%d]=%x, dec[%d]=%x\n", i, in[i], i, cpy[i]);
	  return i+1; 
	}
  return 0;
}

#ifdef LZ4_ON
  #ifdef USE_SSE
unsigned tp4lz4enc(unsigned char *in, unsigned n, unsigned char *out, unsigned esize, unsigned char *tmp) {
  tp4enc(in, n, tmp, esize); 
  return LZ4_compress(tmp, out, n);
}

unsigned tp4lz4dec(unsigned char *in, unsigned n, unsigned char *out, unsigned esize, unsigned char *tmp) {
  unsigned rc; 
  LZ4_decompress_fast((char *)in, (char *)tmp, n); 
  tp4dec(tmp, n, (unsigned char *)out, esize);
  return rc;
}
  #endif

unsigned tplz4enc(unsigned char *in, unsigned n, unsigned char *out, unsigned esize, unsigned char *tmp) {
  tpenc(in, n, tmp, esize); 
  return LZ4_compress(tmp, out, n);
}

unsigned tplz4dec(unsigned char *in, unsigned n, unsigned char *out, unsigned esize, unsigned char *tmp) {
  unsigned rc; 
  LZ4_decompress_fast((char *)in, (char *)tmp, n); 
  tpdec(tmp, n, (unsigned char *)out, esize);
  return rc;
}
#endif

#ifdef BITSHUFFLE
#define   BITSHUFFLE(in,n,out,esize) bshuf_bitshuffle(  in, out, (n)/esize, esize, 0); memcpy((char *)out+((n)&(~(8*esize-1))),(char *)in+((n)&(~(8*esize-1))),(n)&(8*esize-1))
#define BITUNSHUFFLE(in,n,out,esize) bshuf_bitunshuffle(in, out, (n)/esize, esize, 0); memcpy((char *)out+((n)&(~(8*esize-1))),(char *)in+((n)&(~(8*esize-1))),(n)&(8*esize-1))

unsigned bslz4enc(unsigned char *in, unsigned n, unsigned char *out, unsigned esize, unsigned char *tmp) {
  BITSHUFFLE(in, n, tmp, esize); 
  return LZ4_compress(tmp, out, n);
}

unsigned bslz4dec(unsigned char *in, unsigned n, unsigned char *out, unsigned esize, unsigned char *tmp) {
  unsigned rc; 
  LZ4_decompress_fast((char *)in, (char *)tmp, n); 
  BITUNSHUFFLE(tmp, n, (unsigned char *)out, esize);
  return rc;
}
#endif
  
#define ID_MEMCPY 7
void bench(unsigned char *in, unsigned n, unsigned char *out, unsigned esize, unsigned char *cpy, int id) { 
  memrcpy(cpy,in,n);
  
  switch(id) {
    case 1: { TMBENCH("", tpenc(in, n,out,esize) ,n); 	TMBENCH2("tp_byte       ",tpdec(out,n,cpy,esize) ,n); } break;
	  #ifdef USE_SSE
    case 2: { TMBENCH("", tp4enc(in,n,out,esize) ,n); 	TMBENCH2("tp_nibble     ",tp4dec(out,n,cpy,esize) ,n); } break;      
	  #endif
      #ifdef BLOSC
    case 3: { TMBENCH("",shuffle(esize,n,in,out), n);	    TMBENCH2("blosc shuffle ",unshuffle(esize,n,out,cpy), n); } break;
    case 4: { unsigned char *tmp = malloc(n); TMBENCH("",bitshuffle(esize,n,in,out,tmp), n); TMBENCH2("blosc bitshuffle ",bitunshuffle(esize,n,out,cpy,tmp), n); free(tmp); } break;
      #endif
      #ifdef BITSHUFFLE
    case 5: { TMBENCH("",bshuf_bitshuffle(in,out,(n)/esize,esize,0), n); TMBENCH2("bitshuffle    ",bshuf_bitunshuffle(out,cpy,(n)/esize,esize,0), n); } break;
      #endif
    case 6: TMBENCH("",memcpy(in,out,n) ,n); TMBENCH2("memcpy        ",memcpy(cpy,out,n) ,n); break;
    case 7: 
      switch(esize) {
        case  2: { TMBENCH("", tpenc2( in, n,out) ,n); 	TMBENCH2("tp_byte2 scalar", tpdec2( out,n,cpy) ,n); } break;
        case  4: { TMBENCH("", tpenc4( in, n,out) ,n); 	TMBENCH2("tp_byte4 scalar", tpdec4( out,n,cpy) ,n); } break;
        case  8: { TMBENCH("", tpenc8( in, n,out) ,n); 	TMBENCH2("tp_byte8 scalar", tpdec8( out,n,cpy) ,n); } break;
        case 16: { TMBENCH("", tpenc16(in, n,out) ,n); 	TMBENCH2("tp_byte16 scalar",tpdec16(out,n,cpy) ,n); } break;
      } 
      break;
	default: return;
  }
  printf("\n");
  memcheck(in,n,cpy);
}

void usage(char *pgm) {
  fprintf(stderr, "\nTPBench Copyright (c) 2013-2019 Powturbo %s\n", __DATE__);
  fprintf(stderr, "Usage: %s [options] [file]\n", pgm);
  fprintf(stderr, " -e#      # = function ids separated by ',' or ranges '#-#' (default='1-%d')\n", ID_MEMCPY);
  fprintf(stderr, " -B#s     # = max. benchmark filesize (default 1GB) ex. -B4G\n");
  fprintf(stderr, "          s = modifier s:K,M,G=(1000, 1.000.000, 1.000.000.000) s:k,m,h=(1024,1Mb,1Gb). (default m) ex. 64k or 64K\n");
  fprintf(stderr, "Benchmark:\n");
  fprintf(stderr, " -i#/-j#  # = Minimum  de/compression iterations per run (default=auto)\n");
  fprintf(stderr, " -I#/-J#  # = Number of de/compression runs (default=3)\n");
  fprintf(stderr, " -e#      # = function id\n");
  exit(0);
} 

int main(int argc, char* argv[]) {
  unsigned cmp=1, b = 1 << 30, esize=4, lz=0, fno,id=0;
  unsigned char *scmd = NULL;
  int c, digit_optind = 0, this_option_optind = optind ? optind : 1, option_index = 0;
  static struct option long_options[] = { {"blocsize", 	0, 0, 'b'}, {0, 0, 0}  };
  for(;;) {
    if((c = getopt_long(argc, argv, "B:ce:i:I:j:J:q:s:z", long_options, &option_index)) == -1) break;
    switch(c) {
      case  0 : printf("Option %s", long_options[option_index].name); if(optarg) printf (" with arg %s", optarg);  printf ("\n"); break;								
	  case 'e': scmd   = optarg; break;
      case 's': esize  = atoi(optarg);  break;
      case 'i': if((tm_rep  = atoi(optarg))<=0) tm_rep =tm_Rep=1; break;
      case 'I': if((tm_Rep  = atoi(optarg))<=0) tm_rep =tm_Rep=1; break;
      case 'j': if((tm_rep2 = atoi(optarg))<=0) tm_rep2=tm_Rep2=1; break;
      case 'J': if((tm_Rep2 = atoi(optarg))<=0) tm_rep2=tm_Rep2=1; break;
      case 'B': b = argtoi(optarg,1); 	break;
      case 'z': lz++; 				  	break;
      case 'c': cmp++; 				  	break;
	  case 'q': cpuini(atoi(optarg));  break;
      default: 
        usage(argv[0]);
        exit(0); 
    }
  }
  
  printf("tm_verbose=%d ", tm_verbose);
  if(argc - optind < 1) { fprintf(stderr, "File not specified\n"); exit(-1); }
  {
    unsigned char *in,*out,*cpy;
    uint64_t totlen=0,tot[3]={0};
    for(fno = optind; fno < argc; fno++) {
      uint64_t flen;
      int n,i;	  
      char *inname = argv[fno];  									
      FILE *fi = fopen(inname, "rb"); 							if(!fi ) { perror(inname); continue; } 	
      fseek(fi, 0, SEEK_END); 
      flen = ftell(fi); 
	  fseek(fi, 0, SEEK_SET);
	
      if(flen > b) flen = b;
      n = flen; 
      if(!(in  =        (unsigned char*)malloc(n+1024)))        { fprintf(stderr, "malloc error\n"); exit(-1); } cpy = in;
      if(!(out =        (unsigned char*)malloc(flen*4/3+1024))) { fprintf(stderr, "malloc error\n"); exit(-1); } 
      if(cmp && !(cpy = (unsigned char*)malloc(n+1024)))        { fprintf(stderr, "malloc error\n"); exit(-1); }
      n = fread(in, 1, n, fi);									printf("File='%s' Length=%u\n", inname, n);			
      fclose(fi);
      if(n <= 0) exit(0); 
      if(fno == optind) {
        tm_init(tm_Rep, 2);  
        tpini(0); 
        printf("size=%u, element size=%d. detected simd=%s\n\n", n, esize, cpustr(cpuini(0))); 
      }
      printf("  E MB/s     D MB/s  function (size=%d )\n", esize);  
	  char *p = scmd?scmd:"1-10"; 
	  do { 
        unsigned id = strtoul(p, &p, 10),idx = id, i;    
	    while(isspace(*p)) p++; if(*p == '-') { if((idx = strtoul(p+1, &p, 10)) < id) idx = id; if(idx > ID_MEMCPY) idx = ID_MEMCPY; } 
	    for(i = id; i <= idx; i++) {
          bench(in,n,out,esize,cpy,i);
    
          if(lz) {
            char *tmp; int rc;   
            totlen += n;
            // Test Transpose + lz	
            if(!(tmp = (unsigned char*)malloc(n+1024))) { fprintf(stderr, "malloc error\n"); exit(-1); }
              #ifdef LZ4_ON
            memrcpy(cpy,in,n); TMBENCH("lz4",rc = LZ4_compress(in, out, n) ,n); tot[0]+=rc; TMBENCH("",LZ4_decompress_fast(out,cpy,n) ,n); memcheck(in,n,cpy);
            printf("compressed len=%u ratio=%.2f\n", rc, (double)(rc*100.0)/(double)n); 

            memrcpy(cpy,in,n); TMBENCH("tpbyte+lz4",rc = tplz4enc(in, n,out,esize,tmp) ,n); tot[0]+=rc; TMBENCH("",tplz4dec(out,n,cpy,esize,tmp) ,n); memcheck(in,n,cpy);
            printf("compressed len=%u ratio=%.2f\n", rc, (double)(rc*100.0)/(double)n); 
                #ifdef USE_SSE
            memrcpy(cpy,in,n); TMBENCH("tpnibble+lz4",rc = tp4lz4enc(in, n,out,esize,tmp) ,n); tot[1]+=rc; TMBENCH("",tp4lz4dec(out,n,cpy,esize,tmp) ,n); memcheck(in,n,cpy);
            printf("compressed len=%u ratio=%.2f\n", rc, (double)(rc*100.0)/(double)n);
		        #endif
              #endif

	          #ifdef BITSHUFFLE
            memrcpy(cpy,in,n); TMBENCH("bitshuffle+lz4",rc=bslz4enc(in,n,out,esize,tmp), n); tot[2] += rc; TMBENCH("",bslz4dec(out,n,cpy,esize,tmp), n); memcheck(in,n,cpy);
            printf("compressed len=%u ratio=%.2f\n", rc, (double)(rc*100.0)/(double)n);	
              #endif
            printf("\n");
            free(tmp); 
          }
        }
	  } while(*p++);
      if(lz) {
          #ifdef HAVE_LZ4
        printf("tplz4enc  :         compressed len=%llu ratio=%.2f %%\n", tot[0], (double)(tot[0]*100.0)/(double)totlen); 
            #ifdef USE_SSE2
        printf("tp4lz4enc :         compressed len=%llu ratio=%.2f %%\n", tot[1], (double)(tot[1]*100.0)/(double)totlen); 
            #endif
          #endif
          #ifdef BITSHUFFLE
        printf("bshuf_compress_lz4: compressed len=%llu ratio=%.2f %%\n", tot[2], (double)(tot[2]*100.0)/(double)totlen); 
          #endif
      }
    }
  }
}
