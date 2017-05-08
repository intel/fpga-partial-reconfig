#! /bin/bash
CABLE=
function usage()
{
	echo
	echo "Usage:" 
	echo "-c=, --cable="
	echo "cable: non-zero jtag cable index"
	echo "(e.g.  1)"
	echo
	exit 1
}

for i in "$@"
do
case $i in
	-c=*|--cable=*)
	CABLE=${i#*=}
	echo "Cable is $CABLE"
	;;
	*)
	echo "Error in parameters"
	usage
	;;
esac
done


if [ 0 -eq $CABLE ]
then
	echo
	echo "ERROR! No cable or invalid cable specified."
	usage
fi


jtagconfig --setparam $CABLE JtagClock 6MHz;
quartus_pgm -c $CABLE flash.cdf

exit 0