#!/bin/bash
#auto judg dir
#by authors lonewolf 2015
set -e

dir=/tmp/lonewolf
if [ ! -d $dir ]; then
    mkdir -p $dir
    echo -e "\033[32mthis $dir create success!\033[0m"
else
    echo -e "\033[32mthis $dir exist,please exit!\033[0m"
fi
