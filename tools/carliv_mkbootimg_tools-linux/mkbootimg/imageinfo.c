/* imageinfo/imageinfo.c
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
#include <stdbool.h>

#include <mincrypt/sha.h>
#include "bootimg.h"

typedef unsigned char byte;

int usage(void)
{
    fprintf(stderr,"usage: imageinfo boot.img\n"
            "       \tor\n"
            "       imageinfo recovery.img\n");
    return 1;
}

static char print_hash(const uint8_t *string)
{
    while (*string) printf("%02x", *string++);
}

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

int main(int argc, char** argv)
{
	char tmp[PATH_MAX];
    char* filename = NULL;
    unsigned base;
    int pagesize = 0;
    char id_sha[20];

    argc--;
    if (argc > 0) {
        char *val = argv[1];
        filename = val;
    } else {
		return usage();
	}

    if(filename == NULL) {
        fprintf(stderr," Error: no input filename specified\n");
        return usage();
    }

    int total_read = 0;
    FILE* f = fopen(filename, "rb");
    boot_img_hdr header;

    //printf("Reading header...\n");
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
    
    printf(" Printing information for \"%s\"\n", basename(filename));
    printf(" Android image info utility by carliv@xda\n\n");
    
    printf(" Header:\n\n");
    printf("  Magic            : %s\n", "ANDROID!");
    printf("  Magic offset     : 0x%08x\n\n", i);
    
    if (pagesize == 0) {
        pagesize = header.page_size;
    }
    
    base = header.kernel_addr - 0x00008000;
    	
	if(header.page_size != 0) {
        printf("  Page_size        : %d  \t  (0x%08x)\n", header.page_size, header.page_size);
    }
    
    if(header.kernel_addr != 0) {		
        printf("  Base address     : 0x%08x\n\n", base);
        printf("  Kernel address   : 0x%08x\n", header.kernel_addr);        
    }

    total_read += sizeof(header);
    total_read += read_padding(f, sizeof(header), pagesize);
    
    if(header.kernel_size != 0) {
        printf("  Kernel size      : %d  \t  (0x%08x)\n", header.kernel_size, header.kernel_size);
        printf("  Kernel offset    : 0x%08x\n\n", header.kernel_addr - base);
    }
    
    if(header.ramdisk_addr != 0) {
        printf("  Ramdisk address  : 0x%08x\n", header.ramdisk_addr);        
    }

    total_read += read_padding(f, header.kernel_size, pagesize);
    
    if(header.ramdisk_size != 0) {
		printf("  Ramdisk size     : %d  \t  (0x%08x)\n", header.ramdisk_size, header.ramdisk_size);
        printf("  Ramdisk offset   : 0x%08x\n", header.ramdisk_addr - base);
        byte* ramdisk = (byte*)malloc(header.ramdisk_size);
	    fread(ramdisk, header.ramdisk_size, 1, f);
	    total_read += header.ramdisk_size;
	    if(ramdisk[0] == 0x42 && ramdisk[1]== 0x5A)
	        printf("  Ramdisk compress : bz2\n");
	    else if(ramdisk[0] == 0x5D && ramdisk[1]== 0x00)
	        printf("  Ramdisk compress : lzma\n");
	    else if(ramdisk[0] == 0xFD && ramdisk[1]== 0x37)
	        printf("  Ramdisk compress : xz\n");      
	    else
	        printf("  Ramdisk compress : gz\n\n");
    }
    
    if(header.second_addr != 0) {
        printf("  Second address   : 0x%08x\n", header.second_addr);
    }

    total_read += read_padding(f, header.ramdisk_size, pagesize);
    
    if(header.second_size != 0) {
		printf("  Second size      : %d  \t  (0x%08x)\n", header.second_size, header.second_size);
        printf("  Second offset    : 0x%08x\n\n", header.second_addr - base);
    }
    
    if(header.tags_addr != 0) {
        printf("  Tags address     : 0x%08x\n", header.tags_addr);
        printf("  Tags offset      : 0x%08x\n\n", header.tags_addr - base);
    }

    if(header.name[0] != 0) {
        printf("  Board name       : '%s'\n\n", header.name);
    }
    
    if(header.cmdline[0] != 0) {
        printf("  Cmdline          : '%s'\n\n", header.cmdline);
    }
    
    if(header.id[0] != 0) {
        sprintf(id_sha, "%s", (char*) header.id);
		printf("  Id               : "); print_hash(id_sha); printf("\n\n");
    }
    
    total_read += read_padding(f, header.second_size, pagesize);
    
    if(header.dt_size != 0) {
		printf("  Dt size          : %d  \t  (0x%08x)\n\n", header.dt_size, header.dt_size);
    }
    
    sprintf(tmp, "%s", basename(filename));
    strcat(tmp, "-infos.txt");
    char informations[8192];
    sprintf(informations, " Magic = %s\n magic_offset = 0x%08x\n page_size = %d  \t  (%08x)\n board = '%s'\n base = 0x%08x\n kernel_addr = 0x%08x\n kernel offset = 0x%08x\n kernel_size = %d  \t  (%08x)\n ramdisk_addr = 0x%08x\n ramdisk offset = 0x%08x\n ramdisk_size = %d  \t  (%08x)\n second_addr = 0x%08x\n second offset = 0x%08x\n second_size = %d  \t  (%08x)\n tags_addr = 0x%08x\n tags offset = 0x%08x\n cmdline = '%s'\n dt_size = %d  \t  (%08x)\n", "ANDROID!", i, header.page_size, header.page_size, header.name, base, header.kernel_addr, header.kernel_addr - base, header.kernel_size, header.kernel_size, header.ramdisk_addr, header.ramdisk_addr - base, header.ramdisk_size, header.ramdisk_size, header.second_addr, header.second_addr - base, header.second_size, header.second_size, header.tags_addr, header.tags_addr - base, header.cmdline, header.dt_size, header.dt_size);
    write_string_to_file(tmp, informations);
           
    printf("\nSuccessfully printed all informations for %s\n", basename(filename));
    printf("\nAlso all informations are saved in %s-infos.txt file\n\n", basename(filename));
    
    fclose(f);

    return 0;
}