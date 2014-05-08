#!/bin/bash
#
cat $1 | tail -n +2 | cut -d':' -f2 | cut -d';' -f1 > $2.img
