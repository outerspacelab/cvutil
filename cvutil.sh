#!/bin/bash
# Usage: bash converter.sh \
#            --mode videos2images \
#            --videos_path /home/young/Data/Projects/Datasets/Exps/datasets \  
#            --images_path /home/young/Data/Projects/Datasets/Exps/datasets_images \
# [Optional] --fps 25 \
# [Optional] --format image_%04d.jpg \
# [Optional] --height 256 \
# [Optional] --width 340 \
# [Optional] --num_workers 8
#
# Usage: bash converter.sh \
#            --mode images2videos \
#            --images_path /home/young/Data/Projects/Datasets/Exps/datasets_images/datasets \
#            --videos_path /home/young/Data/Projects/Datasets/Exps/datasets_merge \  
# [Optional] --fps 25 \
# [Optional] --height 256 \
# [Optional] --width 340 \
# [Optional] --num_workers 8
#
# Usage: bash download.sh \
#            --source_path xxx.csv \
#            --target_path xxx \
#            --exclude xxx \
#            --condition xxx


if [[ $1 == "download"  ]];then
  bash download.sh $*
elif [[ $1 == "converter" ]];then
  bash converter.sh $*
fi
