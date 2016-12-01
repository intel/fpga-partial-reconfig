#! /bin/sh
# This script compiles the Linux PCIe driver, load the driver, and setups the 
# necessary files to allow automatically load the driver upon reboot. 
# You need sudo access to load the driver.

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
MODULE_NAME=altr_aclpci_cvp_drv
MODULE_DEST=/lib/modules/`uname -r`/misc
MODPROBE_FILE_DIR=/etc/sysconfig/modules
RULE_FILE_DIR=/etc/udev/rules.d

# Copy the Linux PCIe driver source code to a temporary folder
TEMP_FOLDER=`mktemp -d /tmp/opencl_driver_XXXXXX`
cp -r $SCRIPT_DIR/* $TEMP_FOLDER

# Compile the Linux PCIe driver against your own kernel sources, 
cd $TEMP_FOLDER && sh ./make_all.sh || exit 1

# Copy the kernel module into destination directory and run '/sbin/depmod' 
# so that '/sbin/modprobe' can find it 
sudo mkdir -p $MODULE_DEST
sudo cp ./$MODULE_NAME.ko $MODULE_DEST
sudo /sbin/depmod -a

# Create .modules file which is executed when reboot to load the driver
cat > $TEMP_FOLDER/altr_aclpci_cvp_drv.modules <<EOL
#!/bin/sh
exec /sbin/modprobe $MODULE_NAME >/dev/null 2>&1
EOL
sudo mkdir -p $MODPROBE_FILE_DIR
sudo cp $TEMP_FOLDER/altr_aclpci_cvp_drv.modules $MODPROBE_FILE_DIR
sudo chmod +x $MODPROBE_FILE_DIR/altr_aclpci_cvp_drv.modules

# Write udev rules to change the access permission for the device nodes 
cat > $TEMP_FOLDER/99-altr_aclpci_cvp_drv.rules <<EOL
KERNEL=="acla10_ref*", SUBSYSTEM=="altr_aclpci_cvp_drv", MODE=="0600", MODE="0666"
EOL
sudo mkdir -p $RULE_FILE_DIR
sudo cp $TEMP_FOLDER/99-altr_aclpci_cvp_drv.rules $RULE_FILE_DIR

# Load/reload the driver into kernel after all the setup
if [ "`cat /proc/modules | grep "$MODULE_NAME"`" ]; then
   sudo /sbin/modprobe -r $MODULE_NAME
fi
sudo /sbin/modprobe $MODULE_NAME

# Remove the temporary folder
rm -rf $TEMP_FOLDER
