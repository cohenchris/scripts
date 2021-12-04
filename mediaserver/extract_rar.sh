#!/bin/bash

find /downloads/complete/ -name '*.rar' -execdir unrar e -o- {} \; -exec rm {} \; > ./log.txt 2>&1
