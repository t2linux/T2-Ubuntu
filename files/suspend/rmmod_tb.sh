#!/bin/sh
if [ "${1}" = "pre" ]; then
        modprobe -r apple-touchbar
elif [ "${1}" = "post" ]; then
        modprobe apple-touchbar
fi
