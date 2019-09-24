#!/bin/bash

# Run this script on startup to reset the encoding state.  Parameter 1 is the directory that the encode script and folders are placed.  For example, /home/<current user>/Videos/encode

# Run on startup in Debian 10: https://linuxconfig.org/how-to-automatically-execute-shell-script-at-startup-boot-on-systemd-linux

rm $1/working/*
mv $1/queue/* $1/source
