#!/bin/bash

# Run this script on startup to reset the encoding state.

# Run on startup in Debian 10: https://linuxconfig.org/how-to-automatically-execute-shell-script-at-startup-boot-on-systemd-linux

path="~/Videos/encode"

rm $path/working/*
mv $path/queue/* $path/source
