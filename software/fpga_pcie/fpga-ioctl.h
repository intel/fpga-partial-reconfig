#ifndef QUERY_IOCTL_H
#define QUERY_IOCTL_H
#include <linux/ioctl.h>
 

typedef struct
{
    char rbf_name[1024];
    int config_timeout;
} pr_arg_t;


typedef struct
{
    int offset;
} my_arg_t;

typedef struct
{
    int offset;
    int data;
} rw_arg_t;
 
#define FPGA_DEBUG_PRINT_ROM _IO('q', 1)
#define FPGA_DISABLE_UPSTREAM_AER _IO('q', 2)
#define FPGA_ENABLE_UPSTREAM_AER _IO('q', 3)
#define FPGA_INITIATE_PR _IOW('q', 4, pr_arg_t *)
#define FPGA_PR_REGION_CONTROLLER_FREEZE_ENABLE _IOW('q', 5, int *)
#define FPGA_PR_REGION_CONTROLLER_FREEZE_DISABLE _IOW('q', 6, int *)
#define FPGA_PR_REGION_READ _IOR('q', 7, rw_arg_t *)
#define FPGA_PR_REGION_WRITE _IOW('q', 8, rw_arg_t *)


 
#endif
