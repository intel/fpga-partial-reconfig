# Need to use the exact version of gcc that was used to compile the kernel
# It's in /usr/bin, so put it at the front of the path
export PATH=/usr/bin:$PATH
SRC_PATH=/lib/modules/`uname -r`/build
echo "Looking for kernel source files in $SRC_PATH"
if [ ! -d "$SRC_PATH" ]
then
  SRC_PATH=/usr/src/kernels/`uname -r`
  echo "Looking for kernel source files in $SRC_PATH"
fi
echo "Using kernel source files from  $SRC_PATH"

make -C $SRC_PATH M=`pwd` modules
