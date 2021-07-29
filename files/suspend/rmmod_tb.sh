#!/bin/sh
if [ "${1}" = "pre" ]; then
        modprobe -r apple_ib_tb
elif [ "${1}" = "post" ]; then
        modprobe apple_ib_tb
fi
