/* mkbootimg/unpackbootimg.c
**
** Liviu Caramida (carliv@xda), Carliv Image Kitchen modified source
*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>
#include <limits.h>
#include <libgen.h>

#include <mincrypt/sha.h>
#include "bootimg.h"

typedef unsigned char byte;

int read_padding(FILE* f, unsigned itemsize, int pagesize)
{
    byte* buf = (byte*)malloc(sizeof(byte) * pagesize);
    unsigned pagemask = pagesize - 1;
    unsigned count;

    if((itemsize & pagemask) == 0) {
        free(buf);
        return 0;
    }

    count = pagesize - (itemsize & pagemask);

    fread(buf, count, 1, f);
    free(buf);
    return count;
}

void write_string_to_file(char* file, char* string)
{
    FILE* f = fopen(file, "w");
    fwrite(string, strlen(string), 1, f);
    fwrite("\n", 1, 1, f);
    fclose(f);
}

int usage() {
    printf("usage: unpackbootimg\n");
    printf("\t-i|--input boot.img\n");
    printf("\t[ -o|--output output_directory]\n");
    printf("\t[ -p|--pagesize <size-in-hexadecimal> ]\n");
    return 0;
}

int main(int argc, char** argv)
{
    char tmp[PATH_MAX];
    char* directory = "./";
    char* filename = NULL;
    int pagesize = 0; 
    int mtkheader;   

    argc--;
    argv++;

    while(argc > 0){
        char *arg = argv[0];
        char *val = argv[1];
        argc -= 2;
        argv += 2;
        if(!strcmp(arg, "--input") || !strcmp(arg, "-i")) {
            filename = val;
        } else if(!strcmp(arg, "--output") || !strcmp(arg, "-o")) {
            directory = val;
        } else if(!strcmp(arg, "--pagesize") || !strcmp(arg, "-p")) {
            pagesize = strtoul(val, 0, 16);
        } else {
            return usage();
        }
    }

    if (filename == NULL) {
        fprintf(stderr,"  Error: no input filename specified\n");
        return usage();
    }

    int total_read = 0;
    FILE* f = fopen(filename, "rb");
	
	int j;
	char mtk_magic[4] = {0x88,0x16,0x88,0x58};
    for (j = 0; j <= 4096; j++) {
        fseek(f, j, SEEK_SET);
        fread(tmp, 4, 1, f);
        if (memcmp(tmp, mtk_magic, 4) == 0)
            break;
    }
    if (j > 4096) {
        mtkheader = 0;
    } else {
		mtkheader = 512;
	}  
    fseek(f, j, SEEK_SET);

    //printf("Reading header...\n");
	boot_img_hdr header;
    int i;
    for (i = 0; i <= 512; i++) {
        fseek(f, i, SEEK_SET);
        fread(tmp, BOOT_MAGIC_SIZE, 1, f);
        if (memcmp(tmp, BOOT_MAGIC, BOOT_MAGIC_SIZE) == 0)
            break;
    }
    total_read = i;
    if (i > 512) {
        printf(" Android boot magic not found.\n");
        return 1;
    }  
    fseek(f, i, SEEK_SET);

    fread(&header, sizeof(header), 1, f);
    
    printf(" Printing information for \"%s\"\n", filename);
    printf(" Unpack image utility by carliv@xda\n\n");
    if(mtkheader != 0) printf(" [!] This image has a MTK header\n\n");
            
    printf(" Header:\n\n");
    printf("  Magic            : %s\n", "ANDROID!");
    printf("  Magic offset     : %d\n\n", i);

    if (pagesize == 0) {
        pagesize = header.page_size;
    }
    
    uint32_t base = header.kernel_addr - 0x00008000;
    
	if(header.page_size != 0) {
		//printf("pagesize...\n");
	    sprintf(tmp, "%s/%s", directory, basename(filename));
	    strcat(tmp, "-pagesize");
	    char pagesizetmp[200];
	    sprintf(pagesizetmp, "%d", header.page_size);
	    write_string_to_file(tmp, pagesizetmp);
        printf("  Page size        : %d  \t  (0x%08x)\n", header.page_size, header.page_size);
    }
    
    if(header.kernel_addr != 0) {
		//printf("base...\n");
	    sprintf(tmp, "%s/%s", directory, basename(filename));
	    strcat(tmp, "-base");
	    char basetmp[200];
	    sprintf(basetmp, "0x%08x", base);
	    write_string_to_file(tmp, basetmp);		
        printf("  Base address     : %s\n\n", basetmp);
        printf("  Kernel address   : 0x%08x\n", header.kernel_addr);        
    } 
    
    if(mtkheader != 0) {
	    sprintf(tmp, "%s/%s", directory, basename(filename));
	    strcat(tmp, "-mtk");
	    char mtktmp[200];
	    sprintf(mtktmp, "%d", mtkheader);
	    write_string_to_file(tmp, mtktmp);
    }      
    
    total_read += sizeof(header);
    total_read += read_padding(f, sizeof(header), pagesize);
    if(mtkheader != 0) {
		//read kernel header
		byte* kernel_head = (byte*)malloc(mtkheader);
		fread(kernel_head, mtkheader,1,f);
		total_read += mtkheader;
	}
    
    if(header.kernel_size != 0) {
        printf("  Kernel size      : %d  \t  (0x%08x)\n", header.kernel_size, header.kernel_size);
        //printf("kernel_offset...\n");
	    sprintf(tmp, "%s/%s", directory, basename(filename));
	    strcat(tmp, "-kernel_offset");
	    char kerneltmp[200];
	    sprintf(kerneltmp, "0x%08x", header.kernel_addr - base);
	    write_string_to_file(tmp, kerneltmp);
        printf("  Kernel offset    : %s\n\n", kerneltmp);
        sprintf(tmp, "%s/%s", directory, basename(filename));
        strcat(tmp, "-kernel");
        FILE *k = fopen(tmp, "wb");
	    byte* kernel = (byte*)malloc(header.kernel_size-mtkheader);
	    //printf("Reading kernel...\n");
	    fread(kernel, header.kernel_size-mtkheader, 1, f);
	    total_read += header.kernel_size-mtkheader;
	    fwrite(kernel, header.kernel_size-mtkheader, 1, k);
	    fclose(k);
        printf(" >>  kernel written to '%s' (%d bytes)\n\n", tmp, header.kernel_size-mtkheader);
    }
    
	if(header.ramdisk_addr != 0) {
        printf("  Ramdisk address  : 0x%08x\n", header.ramdisk_addr);        
    }
    
    total_read += read_padding(f, header.kernel_size, pagesize);
    
    if(mtkheader != 0) {
		//read ramdisk header
		byte* ramdisk_head = (byte*)malloc(mtkheader);
		fread(ramdisk_head, mtkheader,1,f);
		total_read += mtkheader;
	}

    if(header.ramdisk_size != 0) {
		printf("  Ramdisk size     : %d  \t  (0x%08x)\n", header.ramdisk_size, header.ramdisk_size);
		//printf("ramdisk_offset...\n");
	    sprintf(tmp, "%s/%s", directory, basename(filename));
	    strcat(tmp, "-ramdisk_offset");
	    char ramdisktmp[200];
	    sprintf(ramdisktmp, "0x%08x", header.ramdisk_addr - base);
	    write_string_to_file(tmp, ramdisktmp);
        printf("  Ramdisk offset   : %s\n\n", ramdisktmp);
        byte* ramdisk = (byte*)malloc(header.ramdisk_size-mtkheader);
	    //printf("Reading ramdisk...\n");
	    fread(ramdisk, header.ramdisk_size-mtkheader, 1, f);
	    total_read += header.ramdisk_size-mtkheader;
	    sprintf(tmp, "%s/%s", directory, basename(filename));
	    if(ramdisk[0] == 0x42 && ramdisk[1]== 0x5A) {
	        strcat(tmp, "-ramdisk.bz2");
		}
	    else if(ramdisk[0] == 0x5D && ramdisk[1]== 0x00) {
	        strcat(tmp, "-ramdisk.lzma");
		}
	    else if(ramdisk[0] == 0x89 && ramdisk[1]== 0x4C) {
	        strcat(tmp, "-ramdisk.lzo");
		}      
	    else if(ramdisk[0] == 0x02 && ramdisk[1]== 0x21) {
	        strcat(tmp, "-ramdisk.lz4"); 
		}     
	    else if(ramdisk[0] == 0xFD && ramdisk[1]== 0x37) {
	        strcat(tmp, "-ramdisk.xz"); 
		}     
	    else if(ramdisk[0] == 0x1F && ramdisk[1]== 0x8B) {
	        strcat(tmp, "-ramdisk.gz"); 
		}     
	    else
	    {
	        strcat(tmp, "-ramdisk.unknown");
		}
	    FILE *r = fopen(tmp, "wb");
	    fwrite(ramdisk, header.ramdisk_size-mtkheader, 1, r);
	    fclose(r);
        printf(" >>  ramdisk written to '%s' (%d bytes)\n\n", tmp, header.ramdisk_size-mtkheader);
    }
    
	if(header.second_addr != 0) {
        printf("  Second address   : 0x%08x\n", header.second_addr);
    }
    
    total_read += read_padding(f, header.ramdisk_size, pagesize);

    if(header.second_size != 0) {
		printf("  Second size      : %d  \t  (0x%08x)\n", header.second_size, header.second_size);
		//printf("second_offset...\n");
	    sprintf(tmp, "%s/%s", directory, basename(filename));
	    strcat(tmp, "-second_offset");
	    char secondtmp[200];
	    sprintf(secondtmp, "0x%08x", header.second_addr - base);
	    write_string_to_file(tmp, secondtmp);
        printf("  Second offset    : %s\n\n", secondtmp);
        sprintf(tmp, "%s/%s", directory, basename(filename));
	    strcat(tmp, "-second");
	    FILE *s = fopen(tmp, "wb");
	    byte* second = (byte*)malloc(header.second_size);
	    //printf("Reading second...\n");
	    fread(second, header.second_size, 1, f);
	    total_read += header.second_size;
	    fwrite(second, header.second_size, 1, s);
	    fclose(s);
        printf(" >>  second bootloader written to '%s' (%d bytes)\n", tmp, header.second_size);
    }
    
    if(header.tags_addr != 0) {
        printf("  Tags address     : 0x%08x\n", header.tags_addr);
        //printf("tags_offset...\n");
	    sprintf(tmp, "%s/%s", directory, basename(filename));
	    strcat(tmp, "-tags_offset");
	    char tagstmp[200];
	    sprintf(tagstmp, "0x%08x", header.tags_addr - base);
	    write_string_to_file(tmp, tagstmp);
        printf("  Tags offset      : %s\n\n", tagstmp);
    }
    
    if(header.name[0] != 0) {
		//printf("board...\n");
	    sprintf(tmp, "%s/%s", directory, basename(filename));
	    strcat(tmp, "-board");
	    write_string_to_file(tmp, header.name);
        printf("  Board name       : '%s'\n\n", header.name);
    }
    
    if(header.cmdline[0] != 0) {
		//printf("cmdline...\n");
	    sprintf(tmp, "%s/%s", directory, basename(filename));
	    strcat(tmp, "-cmdline");
	    write_string_to_file(tmp, header.cmdline);
        printf("  Cmdline          : '%s'\n\n", header.cmdline);
    }
    
    total_read += read_padding(f, header.second_size, pagesize);
    
    if(header.dt_size != 0) {
		printf("  Dt size          : %d  \t  (0x%08x)\n\n", header.dt_size, header.dt_size);
        sprintf(tmp, "%s/%s", directory, basename(filename));
	    strcat(tmp, "-dt");
	    FILE *d = fopen(tmp, "wb");
	    byte* dt = (byte*)malloc(header.dt_size);
	    //printf("Reading dt...\n");
	    fread(dt, header.dt_size, 1, f);
	    total_read += header.dt_size;
	    fwrite(dt, header.dt_size, 1, d);
	    fclose(d);
        printf(" >>  device_tree written to '%s' (%d bytes)\n\n", tmp, header.dt_size);
    }
    
    fclose(f);

    return 0;
}
