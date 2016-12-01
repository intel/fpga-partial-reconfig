#! /bin/bash

jtagconfig --setparam 1 JtagClock 6MHz;
quartus_pgm -c 1 flash.cdf

