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
#include <getopt.h>
#include <sys/mman.h>

#define PR_PERSONA_ID 0x00
#define PR_CONTROL_REGISTER 0x10
#define PR_HOST_REGISTER_0 0x20
#define PR_HOST_REGISTER_1 0x30
#define PR_HOST_REGISTER_2 0x40
#define PR_HOST_REGISTER_3 0x50
#define PR_HOST_REGISTER_4 0x60
#define PR_HOST_REGISTER_5 0x70
#define PR_HOST_REGISTER_6 0x80
#define PR_HOST_REGISTER_7 0x90
#define HOST_PR_REGISTER_0 0xa0
#define HOST_PR_REGISTER_1 0xb0
#define HOST_PR_REGISTER_2 0xc0
#define HOST_PR_REGISTER_3 0xd0
#define HOST_PR_REGISTER_4 0xe0
#define HOST_PR_REGISTER_5 0xf0
#define HOST_PR_REGISTER_6 0x100
#define HOST_PR_REGISTER_7 0x110

#define PERSONA_ID_BASIC_ARITHMETIC 0x000000D2
#define PERSONA_ID_BASIC_DSP 		0x0000AEED
#define PERSONA_ID_DDR4_ACCESS		0x000000EF
#define PERSONA_ID_GOL_ACCELERATOR	0x00676F6C
#define PERSONA_ID_HPR_PARENT_ALPHA	0x68707261
#define VERBOSE_MESSAGE(fmt,args...) do{ if(verbose== 1)printf(fmt,##args); }while (0)	

static uint32_t seed;
static uint32_t number_of_runs;
static uint32_t verbose;


struct test_handle {
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

	printf("region size is 0x%x\n", uioh->size);

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

static void print_exe_time(struct timespec begin, struct timespec end )
{
	double exe_time_seconds;
	double exe_time_ms;
	double exe_time_us;

	exe_time_seconds = difftime(end.tv_sec,begin.tv_sec);
	exe_time_ms = ((double)(end.tv_nsec - begin.tv_nsec)/1000000.0);
	exe_time_us = ((double)(end.tv_nsec - begin.tv_nsec)/1000.0);
	if(exe_time_seconds >= 1.0){
		printf("\texecution time: %0.3f s\n",(exe_time_seconds + exe_time_ms/1000.0));
		return;
	}
	if(exe_time_ms >= 1.0){
		printf("\texecution time: %0.3f ms\n", exe_time_ms);
		return;
	}
	if( exe_time_us >= 1.0){
		printf("\texecution time: %0.3f us\n",exe_time_us);
		return;
	}
	
	printf("\texecution time: %jd ns\n",((end.tv_nsec - begin.tv_nsec)));
	return;
}

static void reset_pr_logic(struct test_handle *th, uint32_t verbose, uint32_t region_offset)
{

	VERBOSE_MESSAGE("\tPerforming PR Logic Reset\n");
	(*th->write_u32)(th->arg, (PR_CONTROL_REGISTER + region_offset), 0);
	(*th->write_u32)(th->arg, (PR_CONTROL_REGISTER + region_offset), 1);
	(*th->write_u32)(th->arg, (PR_CONTROL_REGISTER + region_offset), 0);
	VERBOSE_MESSAGE("\tPR Logic Reset complete\n");

}

#define PR_OPERAND HOST_PR_REGISTER_0
#define PR_INCR HOST_PR_REGISTER_1
#define PR_RESULT PR_HOST_REGISTER_0
static void generate_random_number (uint32_t *a, uint32_t *b, uint32_t bit_max)
{
	uint32_t rand_ready = 0;

	while(!rand_ready){
		*a = rand();
		*b = rand();
		if(bit_max == 32)
			rand_ready = 1;
		if((*a < (uint32_t)((1 << bit_max)-1)) && (uint32_t)(*b < ((1 << bit_max)-1)))
			rand_ready = 1;
	}

	return;
}

int check_result_32(uint32_t expected_value, uint32_t returned_value)
{
	if (expected_value != returned_value ){
			printf("Read back of Result value failed: \n");
			printf("\tExpected:(0x%08X)\n",(int) expected_value);
			printf("\tReceived: (0x%08X)\n", (int) returned_value);
			return 1;
		}

	return 0;
}
int check_result_64(uint64_t expected_value, uint64_t returned_value)
{
	if (expected_value != returned_value ){
			printf("Read back of Result value failed: \n");
			printf("\tExpected:(0x%08jX)\n", expected_value);
			printf("\tReceived: (0x%08jX)\n", returned_value);
			return 1;
		}

	return 0;
}

#define ADDER_INPUT_SIZE 32
static int do_basic_math_persona(struct test_handle *th, uint32_t number_of_runs, uint32_t verbose, uint32_t region_offset)
{
	uint32_t data;
	uint32_t i;
	uint32_t operand = 0;
	uint32_t increment = 0;

	printf("\tThis is BasicArithmetic Persona\n\n");
	reset_pr_logic(th, verbose, region_offset);

	for( i = 1; i <= number_of_runs; i++) {

		printf("Beginning test %d of %d\n", i, number_of_runs);
		reset_pr_logic(th, verbose, region_offset);
		generate_random_number(&operand, &increment, ADDER_INPUT_SIZE);
		VERBOSE_MESSAGE("\tWrite to PR_OPERAND value: 0x%08X\n", operand);
		(*th->write_u32)(th->arg, (PR_OPERAND + region_offset), operand);
		VERBOSE_MESSAGE("\tWrite to PR_OPERAND value: 0x%08X\n", increment);
		(*th->write_u32)(th->arg, (PR_INCR + region_offset), increment);
		data = 0x0;
		(*th->read_u32)(th->arg, (PR_RESULT + region_offset), &data);
		VERBOSE_MESSAGE("\tPerformed:\t0x%08X + 0x%08X\n\tResult Read:\t0x%08X\n\tExpected\t0x%08X\n", operand, increment, data, (uint32_t) (operand + increment));
		if(check_result_32(operand + increment, data))
			exit(EXIT_FAILURE);

		printf("Test %d of %d PASS\n", i, number_of_runs);
	}

	printf("BasicArithmetic persona PASS\n");
	return 0;
}
#define DSP_INPUT_SIZE 27
static int do_basic_dsp_persona(struct test_handle *th, uint32_t number_of_runs, uint32_t verbose, uint32_t region_offset)
{
	uint32_t data;
	uint64_t result = 0;
	uint32_t i = 0;
	uint32_t arg_a = 0;
	uint32_t arg_b = 0;

	printf("\tThis is the Multiplication Persona\n\n");
	reset_pr_logic(th, verbose, region_offset);

	for( i = 1; i <= number_of_runs; i++)
	{
		printf("Beginning test %d of %d\n", i, number_of_runs);
		reset_pr_logic(th, verbose, region_offset);
		generate_random_number(&arg_a, &arg_b, DSP_INPUT_SIZE);
		VERBOSE_MESSAGE("\tWrite to PR_OPERAND value: 0x%08X\n", arg_a);
		(*th->write_u32)(th->arg, (PR_OPERAND + region_offset), arg_a);
		VERBOSE_MESSAGE("\tWrite to PR_OPERAND value: 0x%08X\n", arg_b);
		(*th->write_u32)(th->arg, (PR_INCR + region_offset), arg_b);
		data = 0x0;
		(*th->read_u32)(th->arg, (PR_HOST_REGISTER_1 + region_offset), &data);
		result = data;
		result = (result << 32);
		(*th->read_u32)(th->arg, (PR_HOST_REGISTER_0 + region_offset), &data);
		result += data;
		VERBOSE_MESSAGE("\tPerformed:\t0x%08X * 0x%08X \n\tResult Read:\t0x%08jX\n\tExpected:\t0x%08jX\n", arg_a, arg_b, result, (uint64_t)((uint64_t)arg_a * (uint64_t)arg_b));
		if(check_result_64((uint64_t)((uint64_t)arg_a * (uint64_t)arg_b), result))
			exit(EXIT_FAILURE);

		printf("Test %d of %d PASS\n", i, number_of_runs);

	}
	printf("Multiplication persona PASS\n");
	return 0;
}

#define DDR4_MEM_ADDRESS HOST_PR_REGISTER_0
#define DDR4_SEED_ADDRESS HOST_PR_REGISTER_1
#define DDR4_FINAL_OFFSET HOST_PR_REGISTER_2
#define PERFORMANCE_COUNTER PR_HOST_REGISTER_0
#define DDR4_BUSY_REGISTER PR_HOST_REGISTER_1
#define DDR4_START_MASK 2
#define DDR4_LOAD_SEED_MASK 1
#define DDR4_ADDRESS_MAX 1 << 25
#define DDR4_CAL_MASK 3
#define DDR4_CAL_OFFSET 0x10010
static int run_ddr4_address_sweep(struct test_handle *th, uint32_t base_address, uint32_t final_offset, uint32_t calibration, uint32_t verbose, uint32_t region_offset)
{
	uint32_t data = 0;
	uint32_t busy = 0;
	
	data = base_address;
	(*th->write_u32)(th->arg, (DDR4_MEM_ADDRESS + region_offset), data);
	data = final_offset;
	(*th->write_u32)(th->arg, (DDR4_FINAL_OFFSET + region_offset), data);
	data = 0 | (1 << DDR4_START_MASK) | (calibration << DDR4_CAL_MASK);
	(*th->write_u32)(th->arg, (PR_CONTROL_REGISTER + region_offset), data);
	data = 0 | (0 << DDR4_START_MASK) | (calibration << DDR4_CAL_MASK);
	(*th->write_u32)(th->arg, (PR_CONTROL_REGISTER + region_offset), data);	

	do {
		data = 0;
		(*th->read_u32)(th->arg, (DDR4_BUSY_REGISTER + region_offset), &data);
		busy = data;
	} while(busy);

	return 0;	
}
static int do_ddr4_access_persona (struct  test_handle *th, uint32_t seed, uint32_t number_of_runs, uint32_t verbose, uint32_t region_offset)
{
	uint32_t data;
	uint32_t calibration = 0;
	uint32_t base_address = 0;
	uint32_t final_offset = 0;
	uint32_t i = 0;

	printf("This is the DDR4 Access Persona\n");
	reset_pr_logic(th, verbose, region_offset);
	VERBOSE_MESSAGE("\tChecking DDR4 Calibration\n");
	(*th->read_u32)(th->arg, (DDR4_CAL_OFFSET + 0), &data);

	if(data != 2) {
		printf("DDR4 Calibration Failed\n");
		exit(EXIT_FAILURE);
	} else
		calibration = 1;

	VERBOSE_MESSAGE("\tDDR4 Calibration Check Successful\n");
	VERBOSE_MESSAGE("\tDDR4 lfsr Seed 0x%08X Loading\n", seed);
	VERBOSE_MESSAGE("\tDDR4 lfsr Seed 0x%08X Successfully loaded \n", seed);
	VERBOSE_MESSAGE("\tStarting Test cases\n");

	for( i = 1; i <= number_of_runs; i++) {
		reset_pr_logic(th, verbose, region_offset);
		printf("Beginning test %d of %d\n", i, number_of_runs);
		uint32_t rand_ready = 0;
		data = seed;
		(*th->write_u32)(th->arg, (DDR4_SEED_ADDRESS + region_offset), data);
		data = 0 | (1 << DDR4_LOAD_SEED_MASK);
		(*th->write_u32)(th->arg, (PR_CONTROL_REGISTER + region_offset), data);
		data = 0 | (1 << DDR4_LOAD_SEED_MASK);
		(*th->write_u32)(th->arg, (PR_CONTROL_REGISTER + region_offset), data);
		data = 0;
		(*th->read_u32)(th->arg, (DDR4_SEED_ADDRESS + region_offset), &data);

		if(data != seed) {
			printf("ERROR: failed to load seed \n");
			exit(EXIT_FAILURE);
		}

		while(!rand_ready) {
			base_address = rand();
			final_offset = rand();
			if((base_address + final_offset) < DDR4_ADDRESS_MAX)
				rand_ready = 1;
		}

		VERBOSE_MESSAGE("\tTest case %d:\n\tSweeping Addresses 0x%08X to 0x%08X\n",i , base_address, base_address+final_offset);
		run_ddr4_address_sweep(th,base_address,final_offset, calibration, verbose, region_offset);
		VERBOSE_MESSAGE("\tFinished test case %d\n",i);
		VERBOSE_MESSAGE("\tChecking result for test case %d\n", i);
		data = 0;
		(*th->read_u32)(th->arg, (PERFORMANCE_COUNTER + region_offset), &data);
		VERBOSE_MESSAGE("\tPercent of passing writes = %0.2f%% \n", (data/final_offset) * 100.0);

		if(data != final_offset + 1) {
			printf("\tDDR4 Access failed %0d of %0d (%0.2f%%) writes\n", final_offset - data, final_offset, (data/final_offset) * 100.0);
			exit(EXIT_FAILURE);
		}
		printf("Test %d of %d PASS\n", i, number_of_runs);
	}
	
	printf("DDR4 Access persona passed\n");
	return 0;
}
#define GOL_COUNTER_LIMIT_ADDRESS HOST_PR_REGISTER_0
#define GOL_TOP_HALF HOST_PR_REGISTER_1
#define GOL_BOT_HALF HOST_PR_REGISTER_2
#define GOL_BUSY_REG PR_HOST_REGISTER_0
#define GOL_TOP_END PR_HOST_REGISTER_1
#define GOL_BOT_END PR_HOST_REGISTER_2
#define GOL_START_MASK 1
#define GOL_ROWS 8
#define GOL_COLS 8
static uint32_t getbit(uint64_t value, uint32_t position) 
{
	
	uint64_t temp = value;

	temp = (temp >> position) & (1);
	return temp;
}
static void print_board(uint64_t board)
{
	
	int i = 0;
	printf("\t================\n\t");
	for(i=63 ; i >= 0; i--){
		if((i!=0) && ((i%GOL_ROWS) == 0))
			printf("%d\n\t",getbit(board,i));
		 else 
			printf("%d ",getbit(board,i));
	}
	printf("\n\t================\n");

	return;
}

static void run_gol_accelerated(struct  test_handle *th, uint32_t top_half, uint32_t bottom_half, uint32_t number_of_runs, uint32_t verbose, uint32_t region_offset)
{

	struct timespec begin;
	struct timespec end;
	uint32_t data = 0;
	uint32_t busy = 0;
	
	printf("Loading GOL data over PCIe, starting timer\n");
	clock_gettime(CLOCK_PROCESS_CPUTIME_ID, &begin);
	(*th->write_u32)(th->arg, (GOL_TOP_HALF + region_offset), top_half);
	(*th->write_u32)(th->arg, (GOL_BOT_HALF + region_offset), bottom_half);
	(*th->write_u32)(th->arg, (GOL_COUNTER_LIMIT_ADDRESS + region_offset), number_of_runs);
	(*th->write_u32)(th->arg, (PR_CONTROL_REGISTER + region_offset), (0 << GOL_START_MASK));
	(*th->write_u32)(th->arg, (PR_CONTROL_REGISTER + region_offset), (1 << GOL_START_MASK));
	(*th->write_u32)(th->arg, (PR_CONTROL_REGISTER + region_offset), (0 << GOL_START_MASK));
	
	do {
		data = 0;
		(*th->read_u32)(th->arg, (GOL_BUSY_REG + region_offset), &data);
		busy = data;
	} while(busy);
	
	clock_gettime(CLOCK_PROCESS_CPUTIME_ID, &end);
	printf("Accelerated GOL complete\n");
	print_exe_time(begin,end);
	return;

}

static uint32_t calculate_coord(int x, int y)
{
	return (uint32_t)(((x + GOL_ROWS) % GOL_ROWS) + (((y + GOL_COLS) % GOL_COLS) * GOL_ROWS));
}

static void calculate_neighbors(uint64_t current_board, uint32_t *neighbors)
{

	int i = 0;
	int j = 0;

	for(i = 0; i < GOL_ROWS; i++){
		for(j = 0; j < GOL_COLS; j++){
			neighbors[calculate_coord(i,j)] = 0;
			neighbors[calculate_coord(i,j)] += getbit(current_board, calculate_coord(i+1,j+1));
			neighbors[calculate_coord(i,j)] += getbit(current_board, calculate_coord(i+1,j));
			neighbors[calculate_coord(i,j)] += getbit(current_board, calculate_coord(i+1,j-1));
			neighbors[calculate_coord(i,j)] += getbit(current_board, calculate_coord(i,j-1));
			neighbors[calculate_coord(i,j)] += getbit(current_board, calculate_coord(i,j+1));
			neighbors[calculate_coord(i,j)] += getbit(current_board, calculate_coord(i-1,j+1));
			neighbors[calculate_coord(i,j)] += getbit(current_board, calculate_coord(i-1,j));
			neighbors[calculate_coord(i,j)] += getbit(current_board, calculate_coord(i-1,j-1));
		}
	}

}
static uint64_t apply_gol_rules(uint64_t current_board, uint32_t *neighbors)
{

	uint32_t i = 0;
	uint64_t return_board = 0;
	for(i = 0; i < (GOL_ROWS * GOL_COLS); i++){
		if (getbit(current_board,i) == 1){
			if((neighbors[i] == 2) || ( (neighbors[i] == 3)))
				return_board = (return_board) | (uint64_t)((uint64_t)1 << (uint64_t)i);
		}
		else{
			if(neighbors[i] == 3)
				return_board = (return_board) | (uint64_t)((uint64_t)1 << (uint64_t)i);
		}
		neighbors[i]=0;
	}
	return return_board;
}
static uint64_t run_gol_verify(uint64_t board, uint32_t number_of_runs, uint32_t verbose)
{
	uint32_t i = 0;
	uint32_t j = 0;
	uint64_t current_board = 0;
	uint64_t next_board = 0;
	uint32_t *neighbors;
	struct timespec begin;
	struct timespec end;
	printf("Beginning host side GOL for verification, starting timer\n");
	clock_gettime(CLOCK_PROCESS_CPUTIME_ID, &begin);
	neighbors = (uint32_t*) calloc((GOL_ROWS * GOL_COLS),sizeof(uint32_t));

	current_board = board;

	for(i = 0;i < number_of_runs; i++){
		for(j = 0; j < 64; j++){
			if(neighbors[j] != 0)
			{
				exit(EXIT_FAILURE);
			}
		}
		calculate_neighbors(current_board, neighbors);
		next_board = apply_gol_rules(current_board, neighbors);
		current_board = next_board;
	}
	free(neighbors);
	clock_gettime(CLOCK_PROCESS_CPUTIME_ID, &end);

	printf("Host side GOL execution complete\n");
	print_exe_time(begin,end);
	return current_board;
}

static int do_gol_persona (struct  test_handle *th, uint32_t seed, uint32_t number_of_runs, uint32_t verbose, uint32_t region_offset)
{
	
	uint32_t top_half=0;
	uint32_t bottom_half=0;
	uint32_t top_half_final=0;
	uint32_t bottom_half_final=0;
	uint64_t accelerated_result=0;
	uint64_t host_generated_result=0;
	printf("This is the Game of Life Persona\n");

	reset_pr_logic(th, verbose, region_offset);
	generate_random_number(&top_half, &bottom_half, 32);
	VERBOSE_MESSAGE("\tInitial GOL Board:\n");
	VERBOSE_MESSAGE("\t%08X %08X\n", top_half,bottom_half);
	if(verbose == 1)
		print_board(((uint64_t) ((uint64_t)top_half << 32)) | ((uint64_t) bottom_half));
	run_gol_accelerated(th,top_half, bottom_half, number_of_runs, verbose, region_offset);
		reset_pr_logic(th, verbose, region_offset);

	top_half_final = 0;
	bottom_half_final = 0;
	(*th->read_u32)(th->arg, (GOL_TOP_END + region_offset), &top_half_final);
	(*th->read_u32)(th->arg, (GOL_BOT_END + region_offset), &bottom_half_final);
	VERBOSE_MESSAGE("\t%08X %08X\n", top_half_final,bottom_half_final);

	accelerated_result = ((uint64_t) ((uint64_t)(top_half_final) << 32)) | ((uint64_t) bottom_half_final);
	if(verbose == 1)
		print_board(((uint64_t) ((uint64_t)top_half_final << 32)) | ((uint64_t) bottom_half_final));
	host_generated_result = run_gol_verify(((uint64_t) ((uint64_t)top_half << 32)) | ((uint64_t) bottom_half),number_of_runs,verbose);
	if(verbose == 1)
		print_board(host_generated_result);



	VERBOSE_MESSAGE("\t%08jX\n", host_generated_result);
	if(check_result_64(host_generated_result,accelerated_result))
		exit(EXIT_FAILURE);
	printf("GOL persona passed\n");

	return 0;

}

#define HPR_A_CHILD_0 0x4000
#define HPR_A_CHILD_1 0x8000
static int do_hpr_config_a(struct  test_handle *th, uint32_t seed, uint32_t number_of_runs, uint32_t verbose, uint32_t region_offset)
{
	uint32_t id_child_0 = 0;
	uint32_t id_child_1 = 0;
	int ret_0;
	int ret_1;
	printf("This is a HPR Persona with configuration A\n");
	printf("Checking Child regions\n");
	(*th->read_u32)(th->arg, (PR_PERSONA_ID + HPR_A_CHILD_0), &id_child_0);
	(*th->read_u32)(th->arg, (PR_PERSONA_ID + HPR_A_CHILD_1), &id_child_1);
	printf("====Child==== 0\n");
	
	switch (id_child_0) {
	case PERSONA_ID_BASIC_ARITHMETIC:
		ret_0 = do_basic_math_persona(th, number_of_runs, verbose, HPR_A_CHILD_0);
		break;

	case PERSONA_ID_BASIC_DSP:
		ret_0 = do_basic_dsp_persona(th, number_of_runs, verbose,HPR_A_CHILD_0);
		break;

	case PERSONA_ID_DDR4_ACCESS:
		ret_0 = do_ddr4_access_persona(th, seed, number_of_runs, verbose,HPR_A_CHILD_0);
		break;

	case PERSONA_ID_GOL_ACCELERATOR:
		ret_0 = do_gol_persona(th, seed, number_of_runs, verbose, HPR_A_CHILD_0);
		break;

	default:
		printf("unknown PR ID value 0x%x\n", id_child_0);
		ret_0 = -EINVAL;
	}

	printf("====Child 1====\n");
	switch (id_child_1) {
	case PERSONA_ID_BASIC_ARITHMETIC:
		ret_1 = do_basic_math_persona(th, number_of_runs, verbose,HPR_A_CHILD_1);
		break;

	case PERSONA_ID_BASIC_DSP:
		ret_1 = do_basic_dsp_persona(th, number_of_runs, verbose,HPR_A_CHILD_1);
		break;

	case PERSONA_ID_DDR4_ACCESS:
		ret_1 = do_ddr4_access_persona(th, seed, number_of_runs, verbose,HPR_A_CHILD_1);
		break;

	case PERSONA_ID_GOL_ACCELERATOR:
		ret_1 = do_gol_persona(th, seed, number_of_runs, verbose,HPR_A_CHILD_1);
		break;

	default:
		printf("unknown PR ID value 0x%x\n", id_child_0);
		ret_1 = -EINVAL;
	}
	ret_0 = ret_0 & ret_1;
	return ret_0;
}

static void usage(const char *prog_name) 
{

	printf("\nUsage:%s <opts> [val]\n\n",prog_name);
	printf("\t<-d,--device> [val]: PCIe id for card (e.g. -d=0000:03:00.0)\n");
	printf("\t<-s,--seed> [val]:Used for random parameterization\n");
	printf("\t<-n,--iterations> [val]:Number of times to perform a given personas task\n");
	printf("\t<-v, --verbose> :Verbose information is reported.\n\n");
	printf("\tMust declare device, other opts are optional\n\n");
	exit(0);
}

int main(int argc, char **argv) 
{
	uint32_t data;
	int ret;
	int uio_num=-1;
	struct test_handle th;
	int opt;

	verbose = 0;
	number_of_runs = 3;
	seed = 1;

	static struct option long_options[] = {
		{"verbose", no_argument, 0, 'v'},
		{"seed", required_argument, 0, 's'},
		{"iterations", required_argument, 0, 'n'},
		{"help", no_argument, 0, 'h'},
		{"device", required_argument, 0, 'd'},
		{0, 0, 0, 0}
	} ;

	while((opt = getopt_long(argc, argv, "vd:s:n:h", long_options, NULL)) != -1){
		switch(opt){
			case 'v':
				verbose = 1;
				break;
			case 'h':
				usage(argv[0]);
				break;
			case 'n':
				number_of_runs = (uint32_t) strtol(optarg, &optarg,10);
				break;
			case 's':
				seed = (uint32_t) strtol(optarg, &optarg, 10);
				break;
			case 'd':
				uio_num = uio_find_dev_num(optarg);
				break;
			case ':':
			case '?':
			default:
				printf("\nInvalid parameter passed.\n");
				usage(argv[0]);
				break;
		}
	}

	srand(seed);

	if (uio_num < 0) {
		printf("\nError: No PCIe device specified.\n");
		usage(argv[0]);
	}

	struct uio_handle *uioh = uio_open(uio_num);

	if (!uioh){
		printf("\nError: uio failed to open.\n");
		usage(argv[0]);
	}

	if (uio_read_u32(uioh, PR_PERSONA_ID, &data))
		printf("read failed\n");
	else
		printf("Persona ID: 0x%08X\n", data);

	th.arg = uioh;
	th.read_u32 = uio_read_u32;
	th.write_u32 = uio_write_u32;
	switch (data) {
	case PERSONA_ID_BASIC_ARITHMETIC:
		ret = do_basic_math_persona(&th, number_of_runs, verbose, 0);
		break;

	case PERSONA_ID_BASIC_DSP:
		ret = do_basic_dsp_persona(&th, number_of_runs, verbose, 0);
		break;

	case PERSONA_ID_DDR4_ACCESS:
		ret = do_ddr4_access_persona(&th, seed, number_of_runs, verbose, 0);
		break;

	case PERSONA_ID_GOL_ACCELERATOR:
		ret = do_gol_persona(&th, seed, number_of_runs, verbose, 0);
		break;

	case PERSONA_ID_HPR_PARENT_ALPHA:
		ret = do_hpr_config_a(&th, seed, number_of_runs, verbose, 0);
		break;

	default:
		printf("unknown PR ID value 0x%x\n", data);
		ret = -EINVAL;
	}

	uio_close(uioh);
	return ret;
}
