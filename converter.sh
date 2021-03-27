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


# Paras parse
parser_para(){
  echo -e "[\033[32mRUNNING\033[0m] Parsing args"

  content=(${*// / })
  count=0

  for iterm in ${content[*]}
  do
    case $iterm in
    "--mode")
      mode=${content[$count+1]}
      echo -e "[\033[32mPARSING\033[0m] Mode: $mode"
    ;;

    "--videos_path")
      videos_path=${content[$count+1]}
      echo -e "[\033[32mPARSING\033[0m] Videos path: $videos_path"
    ;;

    "--images_path")
      images_path=${content[$count+1]}
      echo -e "[\033[32mPARSING\033[0m] Images path: $images_path"
    ;;

    "--fps")
      fps=${content[$count+1]}
      echo -e "[\033[32mPARSING\033[0m] FPS: $fps"
    ;;  

    "--format")
      format=${content[$count+1]}
      echo -e "[\033[32mPARSING\033[0m] Format: $format"
    ;;  

    "--height")
      height=${content[$count+1]}
      echo -e "[\033[32mPARSING\033[0m] Height: $height"
    ;;  

    "--width")
      width=${content[$count+1]}
      echo -e "[\033[32mPARSING\033[0m] Width: $width"
    ;;  

    "--num_workers")
      num_workers=${content[$count+1]}
      echo -e "[\033[32mPARSING\033[0m] Number of workers: $num_workers"
    ;;  
    esac

    let count++
  done

  if [[ $fps == "" ]];then
    fps=25
    echo -e "[\033[32mDEFAULT\033[0m] FPS: $fps"
  fi

  if [[ $format == "" ]] && [[ $mode == "videos2images" ]];then
    format=image_%04d.jpg
    echo -e "[\033[32mDEFAULT\033[0m] Format: $format"
  fi
  
  if [[ $height == "" ]];then
    height=256
    echo -e "[\033[32mDEFAULT\033[0m] Height: $height"
  fi

  if [[ $width == "" ]];then
    width=340
    echo -e "[\033[32mDEFAULT\033[0m] Width: $width"
  fi

  if [[ $num_workers == "" ]];then
    num_workers=8
    echo -e "[\033[32mDEFAULT\033[0m] Number of workers: $num_workers"
  fi  

  if [[ -r thread ]];then 
    rm thread
  fi

  mkfifo thread
  exec 9<>thread

  for i in $(seq 1 $num_workers)
  do
    echo -ne "\n" 1>&9
  done

  if [[ $mode == "videos2images" ]];then
    images_path=$images_path/${videos_path##*/}
  elif [[ $mode == "images2videos" ]];then  
    videos_path=$videos_path/${images_path##*/}
  fi
}

clean(){
  rm thread
}


# Total Number
getVideosNumber(){
  if [[ ! $(ls $1 |grep -v "\." |wc -l) == 0 ]];then
    for dir in $(ls $1 |grep -v "\.")
    do
      getVideosNumber $1/$dir
    done
  fi


  if [[ ! $(ls $1 |grep -E "$video_style" |wc -l) == 0 ]];then
    total_number=$(($total_number+$(ls $1 |grep -E "$video_style" |wc -l)))
  fi
}


# Videos -> Images
videos2images(){
  if [[ ! $(ls $1 |grep -v "\." |wc -l) == 0 ]];then
    for dir in $(ls $1 |grep -v "\.")
    do
      videos2images $1/$dir $2/$dir
    done
  fi


  if [[ ! $(ls $1 |grep -E "$video_style" |wc -l) == 0 ]];then

    for file in $(ls $1 |grep -E "$video_style")
    do 
      if [[ ! -d $2/${file%.*} ]];then
        mkdir -p $2/${file%.*}
      fi

      index_number=$((index_number+1))
      echo -e "[\033[32mCONVERTING\033[0m][$((index_number*100/total_number))%][$index_number/$total_number]" "ffmpeg -loglevel quiet -i $1/$file -r $fps -q:v 2 -vf scale=$width:$height -f image2 $2/${file%.*}/$format &"

      read -u 9
      ffmpeg -loglevel quiet -i $1/$file -r $fps -q:v 2 -vf scale=$width:$height -f image2 $2/${file%.*}/$format &
      echo -ne "\n" 1>&9
    done
  fi
}


# Total Number
getImagesNumber(){
  if [[ ! $(ls $1 |grep -v "\." |wc -l) == 0 ]];then
    for dir in $(ls $1 |grep -v "\.")
    do
      getImagesNumber $1/$dir
    done
  fi

  if [[ ! $(ls $1 |grep -E "$image_style" |wc -l) == 0 ]];then
    let total_number++
  fi
}


# Images -> Videos
images2videos(){
  if [[ ! $(ls $1 |grep -v "\." |wc -l) == 0 ]];then
    for dir in $(ls $1 |grep -v "\.")
    do
      images2videos $1/$dir $2/$dir
    done
  fi


  if [[ ! $(ls $1 |grep -E "$image_style" |wc -l) == 0 ]];then
    index_number=$((index_number+1))

    if [[ ! -d ${2%/*} ]];then
      mkdir -p ${2%/*}
    fi

    images=$(ls $1 |grep -E "$image_style")
    images=(${images// / })
    image=${images[0]}
    suffix=${image##*.}
    prefix=${image%.*}
    prefix0=${prefix%%0*}
    prefix1=%0$((${#prefix}-${#prefix0}))d

    echo -e "[\033[32mCONVERTING\033[0m][$((index_number*100/total_number))%]"[$index_number/$total_number] "ffmpeg -loglevel quiet -f image2 -i $1/$prefix0$prefix1.$suffix  -vcodec libx264  -r $fps -vf scale=$width:$height $2.mp4 -y &"

    read -u 9
    ffmpeg -loglevel quiet -f image2 -i $1/$prefix0$prefix1.$suffix  -vcodec libx264  -r $fps -vf scale=$width:$height $2.mp4 -y &
    echo -ne "\n" 1>&9
  fi  
}


# Main
main(){
  echo -e "[\033[32mCONFIG\033[0m] Convert Videos/Images @$(date)"

  parser_para $*

  if [[ $mode == "videos2images" ]];then
    video_style="\.mp4|\.MP4|\.mov|\.MOV|\.avi|\.AVI|\.wmv|\.WMV"

    total_number=0
    getVideosNumber $videos_path

    echo -e "[\033[32mRUNNING\033[0m] Found videos: $total_number"

    index_number=0
    videos2images $videos_path $images_path

    echo -e "[\033[32mDONE\033[0m] Convert Videos into Images @$(date)"
  elif [[ $mode == "images2videos" ]];then
    image_style="\.jpg|\.JPG|\.png|\.PNG"

    total_number=0
    getImagesNumber $images_path

    echo -e "[\033[32mRUNNING\033[0m] Found set of images: $total_number"

    index_number=0
    images2videos $images_path $videos_path

    echo -e "[\033[32mDONE\033[0m] Convert Images into Videos @$(date)"
  fi

  clean
}

# Run
main $*
