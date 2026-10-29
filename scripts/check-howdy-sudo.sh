#!/bin/sh
if [ -f "/home/edgar/.config/howdy-sudo-disabled" ]; then
    exit 1
fi
exit 0
