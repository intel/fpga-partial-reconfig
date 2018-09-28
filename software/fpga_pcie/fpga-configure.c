#include <stdio.h>
#include <sys/types.h>
#include <fcntl.h>
#include <unistd.h>
#include <string.h>
#include <sys/ioctl.h>
#include <stdlib.h>
 
#include "fpga-ioctl.h"


/*
 * Called to perform partial reconfiguration. Takes a file-path to an RBF as an argument,
 * as well as the address of the region controller that controlls the freeze bridge for intended PR region.
 * Returns 0 on siccess, -1 on failure
 */
int partial_reconfig(int fd, char *rbf_path, int region_controller_addr) {

	pr_arg_t pr_args;
	 // time in milliseconds to wait for PR complete signal to be asserted after RBF has been written to PR IP
	int config_timeout = 10;


	memset(pr_args.rbf_name, 0, sizeof(pr_args.rbf_name));
	strcpy(pr_args.rbf_name, rbf_path);
	pr_args.config_timeout = config_timeout;

	printf("Enabling freeze at address 0x%08X\n", region_controller_addr);


	//First, enable freeze at the region controller at the specified address
	if (ioctl(fd, FPGA_PR_REGION_CONTROLLER_FREEZE_ENABLE, &region_controller_addr) == -1)
	{
		printf("Error enabling freeze at specified address. Please look at /var/log/messages for more information.\n");
		return -1;
	}

	printf("Initiating PR with RBF %s\n", rbf_path);

	//Second, do PR
	if (ioctl(fd, FPGA_INITIATE_PR, &pr_args) == -1)
	{
		printf("Error during PR. Please look at /var/log/messages for more information.\n");
		return -1;
	}

	printf("Disabling freeze at address 0x%08X\n", region_controller_addr);

	//Third, disable freeze at the region controller at the specified address.
	//This will also reset the PR region.
	if (ioctl(fd, FPGA_PR_REGION_CONTROLLER_FREEZE_DISABLE, &region_controller_addr) == -1)
	{
		printf("Error disabling freeze at specified address. Please look at /var/log/messages for more information.\n");
		return -1;
	}

	printf("PR complete\n");
	return 0;
}

/*
 * Called to disable Advanced Error Reporting on the PCIe card. Needs to be called before full chip reconfig.
 * Returns 0 on siccess, -1 on failure
 */
int disable_aer(int fd) {

	if (ioctl(fd, FPGA_DISABLE_UPSTREAM_AER) == -1)
	{
		printf("Error disabling AER. Look at /var/log/messages for more information\n");
		return -1;
	}

	printf("Upstream AER disabled\n");
	return 0;

}

/*
 * Called to enable Advanced Error Reporting on the PCIe card. Needs to be called after full chip reconfig.
 * Returns 0 on siccess, -1 on failure
 */
int enable_aer(int fd) {

	if (ioctl(fd, FPGA_ENABLE_UPSTREAM_AER) == -1)
	{
		printf("Error enabling AER. Look at /var/log/messages for more information\n");
		return -1;
	}

	printf("Upstream AER enabled\n");
	return 0;

}

/*
 * Prints the onboard ROM of the reference design.
 * Returns 0 on siccess, -1 on failure
 */
int print_rom(int fd) {

	if (ioctl(fd, FPGA_DEBUG_PRINT_ROM) == -1)
	{
		printf("Error printing rom. Look at /var/log/messages for more information\n");
		return -1;
	}

	printf("Rom print complete. Please look at /var/log/messages\n");
	return 0;
}


int main(int argc, char *argv[])
{
	//Specify the file name for the driver character device
	char *file_name = "/dev/fpga_pcie";
	char *rbf_path;
	int fd, region_controller_addr;

	enum
	{
		e_partial_reconfig,
		e_disable_aer,
		e_enable_aer,
		e_print_rom
	} option;

	if (strcmp(argv[1], "-p") == 0)
	{
		option = e_partial_reconfig;
		rbf_path = argv[2];
		region_controller_addr = strtoul(argv[3],NULL,16);
	}
	else if (strcmp(argv[1], "-d") == 0)
	{
		option = e_disable_aer;
	}
	else if (strcmp(argv[1], "-e") == 0)
	{
		option = e_enable_aer;
	}
	else if (strcmp(argv[1], "-r") == 0)
	{
		option = e_print_rom;
	}	
	else
	{
		fprintf(stderr, "Usage: %s [-p | -d | -e | -r]\n", argv[0]);
		return 1;
	}


	fd = open(file_name, O_RDWR); //open driver char file and get file descriptor
	if (fd == -1)
	{
		perror("fpga_pcie open");
		return 2;
	}
 
	switch (option)
	{
		case e_partial_reconfig:
			return partial_reconfig(fd, rbf_path, region_controller_addr);
			break;
		case e_disable_aer:
			return disable_aer(fd);
			break;
		case e_enable_aer:
			return enable_aer(fd);
			break;
		case e_print_rom:
			return print_rom(fd);
			break;
		default:
			printf("Invalid option\n");
			break;
	}
 
	close (fd);
	return 0;
}
