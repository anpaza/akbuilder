/* mkbootimg/mkbootimg.c
**
** Copyright 2007, The Android Open Source Project
**
** Licensed under the Apache License, Version 2.0 (the "License");
** you may not use this file except in compliance with the License.
** You may obtain a copy of the License at
**
**     http://www.apache.org/licenses/LICENSE-2.0
**
** Unless required by applicable law or agreed to in writing, software
** distributed under the License is distributed on an "AS IS" BASIS,
** WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
** See the License for the specific language governing permissions and
** limitations under the License.
**
** Liviu Caramida (carliv@xda), Carliv Image Kitchen modified source
*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>
#include <libgen.h>
#include <stdbool.h>

#include <mincrypt/sha.h>
#include "bootimg.h"

static void *load_file(const char *fn, unsigned *_sz)
{
    char *data;
    int sz;
    FILE *fd;

    data = 0;
    fd = fopen(fn, "rb");
    if(fd == 0) return 0;

    if(fseek(fd, 0, SEEK_END) != 0) goto oops;
    sz = ftell(fd);
    if(sz < 0) goto oops;

    if(fseek(fd, 0, SEEK_SET) != 0) goto oops;

    data = (char*) malloc(sz);
    if(data == 0) goto oops;

    if(fread(data, 1, sz, fd) != (size_t) sz) goto oops;
    fclose(fd);

    if(_sz) *_sz = sz;
    return data;

oops:
    fclose(fd);
    if(data != 0) free(data);
    return 0;
}

static void *load_mtk_file(const char *fn, unsigned *_sz, enum  mtk_type type)
{
    char *data;
    int sz;
    int datasz;
    FILE *fd;
    int offset = 0;
    int needs_mtkheader = 0;

    data = 0;
    fd = fopen(fn, "rb");
    if(fd == 0) return 0;

    if(fseek(fd, 0, SEEK_END) != 0) goto oops;
    sz = datasz = ftell(fd);
    if(sz < 0) goto oops;

    if(fseek(fd, 0, SEEK_SET) != 0) goto oops;
    if(type != MTK_NONE)
    {
        printf(" > Type is %s\n", mtk_names[type]);
        unsigned int magic;
        if(fread(&magic, 1, 4, fd) == 4 && magic != MTK_MAGIC)
        {
           printf(" > No MTK Header, making one...\n");
           needs_mtkheader = 1;
           sz += sizeof(mtk_header);
           offset = sizeof(mtk_header);
           printf(" > old sz=%d, new sz=%d, offset=%d\n", datasz, sz, offset);
        }
        if(fseek(fd, 0, SEEK_SET) != 0) goto oops;
    }

    data = (char*) malloc(sz);
    if(data == 0) goto oops;

    if(fread(&data[offset], 1, datasz, fd) != datasz) goto oops;
    fclose(fd);
    
    if(needs_mtkheader)
    {
        printf(" > Generating mtk header\n");
        mtk_header* hdr = (mtk_header*)data;
        memset(hdr->padding, 0xFF, sizeof(mtk_header));
        hdr->info.magic = MTK_MAGIC;
        hdr->info.size = datasz;
        memset(hdr->info.name, 0, sizeof(hdr->info.name));
        strcpy(hdr->info.name, mtk_names[type]);
    }

    if(_sz) *_sz = sz;
    return data;

oops:
    fclose(fd);
    if(data != 0) free(data);
    return 0;
}

int usage(void)
{
    fprintf(stderr,"usage: mkbootimg\n"
            "       --kernel <filename>\n"
            "       [ --ramdisk <filename> ]\n"
            "       [ --second <2ndbootloader-filename> ]\n"
            "       [ --cmdline <kernel-commandline> ]\n"
            "       [ --board <boardname> ]\n"
            "       [ --base <address> ]\n"
            "       [ --pagesize <pagesize> ]\n"
            "       [ --dt <filename> ]\n"
            "       [ --kernel_offset <address> ]\n"
            "       [ --ramdisk_offset <address> ]\n"
            "       [ --second_offset <address> ]\n"
            "       [ --tags_offset <address> ]\n"
            "       [ --id ]\n"
            "       [ --mtk 1 ]\n"
            "       -o|--output <filename>\n"
            );
    return 1;
}



static unsigned char padding[131072] = { 0, };

static void print_id(const uint8_t *id, size_t id_len) {
    printf("0x");
    unsigned i = 0;
    for (i = 0; i < id_len; i++) {
        printf("%02x", id[i]);
    }
    printf("\n");
}

int write_padding(FILE *fd, unsigned pagesize, unsigned itemsize)
{
    unsigned pagemask = pagesize - 1;
    ssize_t count;

    if((itemsize & pagemask) == 0) {
        return 0;
    }

    count = pagesize - (itemsize & pagemask);

    if(fwrite(padding, 1, count, fd) != (size_t) count) {
        return -1;
    } else {
        return 0;
    }
}

int main(int argc, char **argv)
{
    boot_img_hdr hdr;

    char *add_mtk = NULL;
    char *kernel_fn = NULL;
    void *kernel_data = NULL;
    char *ramdisk_fn = NULL;
    void *ramdisk_data = NULL;
    char *second_fn = NULL;
    void *second_data = NULL;
    char *cmdline = "";
    char *bootimg = NULL;
    char *board = "";
    char *dt_fn = 0;
    void *dt_data = 0;
    uint32_t pagesize = 2048;
    FILE *fd;
    SHA_CTX ctx;
    const uint8_t* sha;
    uint32_t base           = 0x10000000U;
    uint32_t kernel_offset  = 0x00008000U;
    uint32_t ramdisk_offset = 0x01000000U;
    uint32_t second_offset  = 0x00f00000U;
    uint32_t tags_offset    = 0x00000100U;
    size_t cmdlen;

    argc--;
    argv++;

    memset(&hdr, 0, sizeof(hdr));

    bool get_id = false;
    while(argc > 0){
        char *arg = argv[0];
        if (!strcmp(arg, "--id")) {
            get_id = true;
            argc -= 1;
            argv += 1;
        } else if(argc >= 2) {
            char *val = argv[1];
            argc -= 2;
            argv += 2;
            if(!strcmp(arg, "--output") || !strcmp(arg, "-o")) {
                bootimg = val;
            } else if(!strcmp(arg, "--mtk")) {
                add_mtk = val;
            } else if(!strcmp(arg, "--kernel")) {
                kernel_fn = val;
            } else if(!strcmp(arg, "--ramdisk")) {
                ramdisk_fn = val;
            } else if(!strcmp(arg, "--second")) {
                second_fn = val;
            } else if(!strcmp(arg, "--cmdline")) {
                cmdline = val;
            } else if(!strcmp(arg, "--base")) {
                base = strtoul(val, 0, 16);
            } else if(!strcmp(arg, "--kernel_offset")) {
                kernel_offset = strtoul(val, 0, 16);
            } else if(!strcmp(arg, "--ramdisk_offset")) {
                ramdisk_offset = strtoul(val, 0, 16);
            } else if(!strcmp(arg, "--second_offset")) {
                second_offset = strtoul(val, 0, 16);
            } else if(!strcmp(arg, "--tags_offset")) {
                tags_offset = strtoul(val, 0, 16);
            } else if(!strcmp(arg, "--board")) {
                board = val;
            } else if(!strcmp(arg,"--pagesize")) {
                pagesize = strtoul(val, 0, 10);
                if ((pagesize != 2048) && (pagesize != 4096)
                    && (pagesize != 8192) && (pagesize != 16384)
                    && (pagesize != 32768) && (pagesize != 65536)
                    && (pagesize != 131072)) {
                    fprintf(stderr," Error: unsupported page size %d\n", pagesize);
                    return -1;
                }
            } else if(!strcmp(arg, "--dt")) {
                dt_fn = val;
            } else {
                return usage();
            }
        } else {
            return usage();
        }
    }
    hdr.page_size = pagesize;

    hdr.kernel_addr =  base + kernel_offset;
    hdr.ramdisk_addr = base + ramdisk_offset;
    hdr.second_addr =  base + second_offset;
    hdr.tags_addr =    base + tags_offset;

    if(bootimg == 0) {
        fprintf(stderr," Error: no output filename specified\n");
        return usage();
    }

    if(kernel_fn == 0) {
        fprintf(stderr," Error: no kernel image specified\n");
        return usage();
    }

    if(ramdisk_fn == 0) {
        fprintf(stderr," Error: no ramdisk image specified\n");
        return usage();
    }

    if(strlen(board) >= BOOT_NAME_SIZE) {
        fprintf(stderr," Error: board name too large\n");
        return usage();
    }

    strcpy((char *) hdr.name, board);

    memcpy(hdr.magic, BOOT_MAGIC, BOOT_MAGIC_SIZE);

    cmdlen = strlen(cmdline);
    if(cmdlen > (BOOT_ARGS_SIZE + BOOT_EXTRA_ARGS_SIZE - 2)) {
        fprintf(stderr," Error: kernel commandline too large\n");
        return 1;
    }
    /* Even if we need to use the supplemental field, ensure we
     * are still NULL-terminated */
    strncpy((char *)hdr.cmdline, cmdline, BOOT_ARGS_SIZE - 1);
    hdr.cmdline[BOOT_ARGS_SIZE - 1] = '\0';
    if (cmdlen >= (BOOT_ARGS_SIZE - 1)) {
        cmdline += (BOOT_ARGS_SIZE - 1);
        strncpy((char *)hdr.extra_cmdline, cmdline, BOOT_EXTRA_ARGS_SIZE);
    }
    
    printf("Repack image utility by carliv@xda\n\n");
    
    if(add_mtk != 0) {
		printf("Check and add the MTK kernel \n");
		kernel_data = load_mtk_file(kernel_fn, &hdr.kernel_size, MTK_KERNEL);
		if(kernel_data == 0) {
			fprintf(stderr,"  Error: could not load kernel '%s'\n", kernel_fn);
			return 1;
		}
		printf("Check and add the MTK ramdisk \n");
		if(ramdisk_fn == 0) {
			ramdisk_data = 0;
			hdr.ramdisk_size = 0;
		} else if(strstr(basename(bootimg), "boot")) {
			ramdisk_data = load_mtk_file(ramdisk_fn, &hdr.ramdisk_size, MTK_ROOTFS);
			if(ramdisk_data == 0) {
				fprintf(stderr," Error: could not load ramdisk '%s'\n", ramdisk_fn);
				return 1;
			}
		} else if(strstr(basename(bootimg), "recovery")) {
			ramdisk_data = load_mtk_file(ramdisk_fn, &hdr.ramdisk_size, MTK_RECOVERY);
			if(ramdisk_data == 0) {
				fprintf(stderr," Error: could not load ramdisk '%s'\n", ramdisk_fn);
				return 1;
			}
		}
    } else {
		printf("Check and add the kernel \n");
        kernel_data = load_file(kernel_fn, &hdr.kernel_size);
		if(kernel_data == 0) {
			fprintf(stderr," Error: could not load kernel '%s'\n", kernel_fn);
			return 1;
		}
		printf("Check and add the ramdisk \n");
		if(ramdisk_fn == 0) {
			ramdisk_data = 0;
			hdr.ramdisk_size = 0;
		} else {
			ramdisk_data = load_file(ramdisk_fn, &hdr.ramdisk_size);
			if(ramdisk_data == 0) {
				fprintf(stderr," Error: could not load ramdisk '%s'\n", ramdisk_fn);
				return 1;
			}
		}
    }

    if(second_fn) {
		printf("Check and add the second bootloader \n");
        second_data = load_file(second_fn, &hdr.second_size);
        if(second_data == 0) {
            fprintf(stderr," Error: could not load secondstage '%s'\n", second_fn);
            return 1;
        }
    }

    if(dt_fn) {
		printf("Check and add the device tree image \n");
        dt_data = load_file(dt_fn, &hdr.dt_size);
        if (dt_data == 0) {
            fprintf(stderr," Error: could not load device tree image '%s'\n", dt_fn);
            return 1;
        }
    }

    /* put a hash of the contents in the header so boot images can be
     * differentiated based on their first 2k.
     */
    SHA_init(&ctx);
    SHA_update(&ctx, kernel_data, hdr.kernel_size);
    SHA_update(&ctx, &hdr.kernel_size, sizeof(hdr.kernel_size));
    SHA_update(&ctx, ramdisk_data, hdr.ramdisk_size);
    SHA_update(&ctx, &hdr.ramdisk_size, sizeof(hdr.ramdisk_size));
    SHA_update(&ctx, second_data, hdr.second_size);
    SHA_update(&ctx, &hdr.second_size, sizeof(hdr.second_size));
    if(dt_data) {
        SHA_update(&ctx, dt_data, hdr.dt_size);
        SHA_update(&ctx, &hdr.dt_size, sizeof(hdr.dt_size));
    }
    sha = SHA_final(&ctx);
    memcpy(hdr.id, sha,
           SHA_DIGEST_SIZE > sizeof(hdr.id) ? sizeof(hdr.id) : SHA_DIGEST_SIZE);

    fd = fopen(bootimg, "wb");
    if(fd == 0) {
        fprintf(stderr," Error: could not create '%s'\n", basename(bootimg));
        return 1;
    }
    
    printf("Build the new image \n");

    if(fwrite(&hdr, 1, sizeof(hdr), fd) != sizeof(hdr)) goto fail;
    if(write_padding(fd, pagesize, sizeof(hdr))) goto fail;

    if(fwrite(kernel_data, 1, hdr.kernel_size, fd) != (ssize_t) hdr.kernel_size) goto fail;
    if(write_padding(fd, pagesize, hdr.kernel_size)) goto fail;

    if(fwrite(ramdisk_data, 1, hdr.ramdisk_size, fd) != (ssize_t) hdr.ramdisk_size) goto fail;
    if(write_padding(fd, pagesize, hdr.ramdisk_size)) goto fail;

    if(second_data) {
        if(fwrite(second_data, 1, hdr.second_size, fd) != (ssize_t) hdr.second_size) goto fail;
        if(write_padding(fd, pagesize, hdr.second_size)) goto fail;
    }

    if (get_id) {
        print_id((uint8_t *) hdr.id, sizeof(hdr.id));
    }

    if(dt_data) {
        if(fwrite(dt_data, 1, hdr.dt_size, fd) != (ssize_t) hdr.dt_size) goto fail;
        if(write_padding(fd, pagesize, hdr.dt_size)) goto fail;
    }
    printf("\n'%s' successfully repacked\n", basename(bootimg));
    return 0;

fail:
    unlink(bootimg);
    fclose(fd);
    fprintf(stderr," Error: failed writing '%s': %s\n", basename(bootimg),
            strerror(errno));
    return 1;
}
