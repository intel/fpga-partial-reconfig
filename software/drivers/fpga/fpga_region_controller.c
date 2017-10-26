/*
 *     Copyright (C) 2017 Intel Corporation
 *
 *     Redistribution and use in source and binary forms, with or
 *     without modification, are permitted provided that the following
 *     conditions are met:
 *
 *     1. Redistributions of source code must retain the above
 *        copyright notice, this list of conditions and the following
 *        disclaimer.
 *     2. Redistributions in binary form must reproduce the above
 *        copyright notice, this list of conditions and the following
 *        disclaimer in the documentation and/or other materials
 *        provided with the distribution.
 *
 *     THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND
 *     CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
 *     INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 *     MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 *     DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
 *     CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 *     SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
 *     NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 *     LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 *     HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 *     CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
 *     OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
 *     EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include <dirent.h>
#include <string.h>
#include <stdlib.h>
#include <stdint.h>
#include <stdio.h>
#include <fcntl.h>
#include <unistd.h>
#include <errno.h>
#include <time.h>
#include <sys/mman.h>

#define BIT(n) (1 << n)


#define FREEZE_CTRL_OFFSET					4
#define FREEZE_VERSION_OFFSET				12

#define FREEZE_STATUS_OFFSET 				0x00
#define FREEZE_BRIDGE_SUPPORTED_VERSION  	0xad000003
#define FREEZE_REQ_DONE						BIT(0)
#define UNFREEZE_REQ_DONE					BIT(1)

#define FREEZE_REQ							BIT(0)
#define RESET_REQ							BIT(1)
#define UNFREEZE_REQ						BIT(2)


struct device_handle {
	void *arg;
	int (*read_u32)(void *, uint32_t, uint32_t *);
	int (*write_u32)(void *, uint32_t, uint32_t);
};

struct uio_handle {
	int fd;
	int size;
	void *iomem;
};

int uio_find_dev_num(const char *uio_name) 
{
	int i, ret, name_len;
	FILE *fh;
	char *retp;
	char buf[80];

	if (uio_name == NULL) {
		printf("no name provided\n");
		return -EINVAL;
	}

	name_len = strnlen(uio_name, sizeof(buf));

	if (name_len >= sizeof(buf)) {
		printf("uio_name is too big\n");
		return -EINVAL;
	}

	for (i = 0; 1; i++) {
		ret = snprintf(buf, sizeof(buf),
			"/sys/class/uio/uio%d/name", i);	

		if (ret >= sizeof(buf)) {
			printf("filename is too long for %d\n", i);
			i = -EINVAL;
			break;
		}

		fh = fopen(buf, "r");
		
		if (fh == NULL) {
			printf("failed to find uio number for %s\n", uio_name);
			i = -ENOENT;
			break;
		}

		retp = fgets(buf, sizeof(buf), fh);

		fclose(fh);

		if (!retp) {
			printf("failed to read name for uid%d\n", i);
			i = -ENOENT;
			break;
		}

		if (!strncmp(buf, uio_name, name_len)) {
			break;
		}
	}

	return i;
}

struct uio_handle *uio_open(int uio_num) 
{
	struct uio_handle *uioh = NULL;
	int ret;
	char fname[64];

	uioh = malloc(sizeof(*uioh));
	if (!uioh) {
		printf("failed to malloc uio_handle\n");
		return NULL;
	}

	ret = snprintf(fname, sizeof(fname),
			"/sys/class/uio/uio%d/maps/map0/size",
			uio_num);

	if (ret >= sizeof(fname)) {
		printf("path to size is too long\n");
		goto error;
	}

	FILE *fh = fopen(fname, "r");
	if (!fh) {
		printf("failed to open %s\n", fname);
		goto error;
	}

	ret = fscanf(fh, "0x%x", &uioh->size);
	fclose(fh);

	if (ret < 0) {
		printf("fscanf of size failed: %d\n", ret);
		goto error;
	}

	if (uioh->size <= 0) {
		printf("bad size read: %d\n", uioh->size);
		goto error;
	}


	ret = snprintf(fname, sizeof(fname), "/dev/uio%d", uio_num);

	if (ret >= sizeof(fname)) {
		printf("path to dev is too long\n");
		goto error;
	}

	uioh->fd = open(fname, O_RDWR);

	if (uioh->fd < 0) {
		printf("failed to open %s\n", fname);
		goto error;
	}

	uioh->iomem = mmap(NULL, uioh->size, PROT_READ|PROT_WRITE, MAP_SHARED, uioh->fd, 0*getpagesize());

	if (uioh->iomem == MAP_FAILED) {
		printf("mmap failed\n");
		close(uioh->fd);
		goto error;
	}

	return uioh;

error:
	if (uioh)
		free(uioh);
	return NULL;
}

void uio_close(struct uio_handle *uioh)
{

	munmap(uioh->iomem, uioh->size);
	close(uioh->fd);
	free(uioh);
}

int uio_read_u32(void *h, uint32_t offset, uint32_t *pdata)
{
	struct uio_handle *uioh = h;
	uint32_t *p;
	if (!uioh) {
		printf("%s bad uioh\n", __func__);
		return EINVAL;
	}

	if (offset >= uioh->size) {
		printf("%s bad offset %u >= %u \n", __func__, offset, uioh->size);
		return EINVAL;
	}

	p = uioh->iomem + offset;
	*pdata = *p;
	return 0;
}

int uio_write_u32(void *h, uint32_t offset, uint32_t data)
{

	struct uio_handle *uioh = h;
	uint32_t *p;
	if (!uioh) {
		printf("%s bad uioh\n", __func__);
		return EINVAL;
	}

	if (offset >= uioh->size) {
		printf("%s bad offset %u >= %u \n", __func__, offset, uioh->size);
		return EINVAL;
	}

	p = uioh->iomem + offset;
	*p = data;
	return 0;
}

static void usage(const char *prog_name) 
{

	printf("\nUsage: %s [card id] [seed] [number of runs] [verbose] \n\n",prog_name);
	printf("\tCard Id: PCIe id for card to load (e.g. 0000:03:00.0)\n");
	printf("\tOffset: Offset for the region controller for the target region\n");
	exit(0);
}
static int freeze_bridge_read_version(struct device_handle *dh, uint32_t ctlr_offset)
{

	uint32_t version = 0;
	printf("Verifying region controller version register\n");
	printf("Accessing region controller at offset 0x%08X\n",ctlr_offset + FREEZE_VERSION_OFFSET);
	(*dh->read_u32)(dh->arg, (ctlr_offset + FREEZE_VERSION_OFFSET), &version);
	if(version != FREEZE_BRIDGE_SUPPORTED_VERSION ){
		printf("\n ERROR, unsupported PR Region Controller version detected 0x%08X\nSupported Version: 0x%08X exiting.\n", version, FREEZE_BRIDGE_SUPPORTED_VERSION);
		return 0;

	} else {
		printf("\tVersion Register:0x%08X\n", version);
		return 1;
	}
	return 0;
}
static int freeze_bridge_req_ack ( struct device_handle *dh, uint32_t ctlr_offset, uint32_t req_ack)
{
	uint32_t ack = 0;
	uint32_t status = 0;
	do{
		status = 0;
		(*dh->read_u32)(dh->arg, (ctlr_offset + FREEZE_STATUS_OFFSET), &status);
		ack = status & req_ack;
	}while(!ack);

	return 0;
}

static int freeze_bridge_enable (struct  device_handle *dh, uint32_t ctlr_offset)
{

	uint32_t status = 0;

	printf("Attempting to enable freeze bridges\n");
	if(!freeze_bridge_read_version(dh, ctlr_offset))
		return -EINVAL;

	(*dh->read_u32)(dh->arg, (ctlr_offset + FREEZE_STATUS_OFFSET), &status);
	
	if (status & FREEZE_REQ_DONE) {
		printf("\t%s bridge already frozen %d\n", __func__, status);
		return 0;
	} else if (!(status & UNFREEZE_REQ_DONE)) {
		printf("\t%s bridge is still unfrozen %d\n", __func__, status);
		return -EINVAL;
	}
	
	printf("Asserting region freeze\n");
	(*dh->write_u32)(dh->arg, (ctlr_offset + FREEZE_CTRL_OFFSET), FREEZE_REQ);
	freeze_bridge_req_ack(dh, ctlr_offset, FREEZE_REQ_DONE);
	printf("Asserting region reset\n");
	(*dh->write_u32)(dh->arg, (ctlr_offset + FREEZE_CTRL_OFFSET), RESET_REQ);
	printf("PR Beginning\n");
	return 0;
}

static int freeze_bridge_disable (struct  device_handle *dh, uint32_t ctlr_offset)
{

	uint32_t status=0;
	printf("PR complete\nAttempting to disable freeze bridges\n");

	if(!freeze_bridge_read_version(dh, ctlr_offset))
		return -EINVAL;

	(*dh->read_u32)(dh->arg, (ctlr_offset + FREEZE_STATUS_OFFSET), &status);
	if (status & UNFREEZE_REQ_DONE) {
		printf("\t%s bridge already unfrozen %d\n", __func__, status);
		return 0;
	} else if (!(status & FREEZE_REQ_DONE)) {
		printf("\t%s bridge is still frozen %d\n", __func__, status);
		return -EINVAL;
	}

	printf("Removing region reset\n");
	(*dh->read_u32)(dh->arg, (ctlr_offset + FREEZE_CTRL_OFFSET), &status);
        status = status ^ RESET_REQ;
        (*dh->write_u32)(dh->arg, (ctlr_offset + FREEZE_CTRL_OFFSET), status);
	(*dh->write_u32)(dh->arg, (ctlr_offset + FREEZE_CTRL_OFFSET), UNFREEZE_REQ);
	freeze_bridge_req_ack(dh, ctlr_offset, UNFREEZE_REQ_DONE);
	printf("Removing region freeze\n");
	(*dh->write_u32)(dh->arg, (ctlr_offset + FREEZE_CTRL_OFFSET), 0);
	printf("Device Ready\n");
	return 0;
}


int main(int argc, char **argv) 
{
	int ret, uio_num;
	struct device_handle dh;
	unsigned long offset = -1;
	char* mode;
	if ((argc < 3) || ((!strcmp(argv[1], "-h")) || (!strcmp(argv[1], "--help"))))
		usage(argv[0]);
	

	uio_num = uio_find_dev_num(argv[1]);
	mode = argv[2];
	offset = strtoul(argv[3],NULL,16);

	if (uio_num < 0) {
		printf("Error invalid device number\n");
		exit(2);
	}
	if (offset < 0){
		printf("Error invalid controller offset\n");
		exit (3);
	}

	struct uio_handle *uioh = uio_open(uio_num);

	if (!uioh)
		exit(1);

	dh.arg = uioh;
	dh.read_u32 = uio_read_u32;
	dh.write_u32 = uio_write_u32;

	if(!strcmp("enable",mode)){
		ret = freeze_bridge_enable(&dh, (uint32_t)offset);

	} else if(!strcmp("disable",mode)){
		ret = freeze_bridge_disable(&dh, (uint32_t)offset);
	}
	else{
		printf("Error command passed\n");
		ret = -EINVAL;

	}

	uio_close(uioh);
	return ret;
}
