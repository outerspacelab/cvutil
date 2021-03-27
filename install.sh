#!/bin/bash
# Usage: install


mkdir -p bin

root_path=`pwd`/bin

echo "cd $root_path" > $root_path/cvutil

cat cvutil.sh >> $root_path/cvutil

chmod 744 $root_path/cvutil

cp converter.sh $root_path
cp download.sh $root_path

sudo ln -s $root_path/cvutil /usr/bin/cvutil
