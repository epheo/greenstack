#!/bin/sh

mount="/"
warning=20
critical=10

echo "$( df -h -P -l $mount |grep -v Filesystem |awk '{ print $4 }') "
