#!/bin/bash

# Run this script on startup to reset the encoding state.  Parameter 1 is the directory that the encode script and folders are placed.

# Run on startup in Debian 10: https://linuxconfig.org/how-to-automatically-execute-shell-script-at-startup-boot-on-systemd-linux

path="$1/Videos/encode"

rm $path/working/*
mv $path/queue/* $path/source
