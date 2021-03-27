#!/bin/bash
# Usage: bash download.sh \
#            --source_path xxx.csv \
#            --target_path xxx \
# [Optional] --exclude xxx \
# [Optional] --condition xxx \
# [Optional] --num_workers 8

# Paras parse
parser_para(){
  echo -e "[\033[32mRUNNING\033[0m] Parsing args"

  content=(${*// / })
  count=0

  for iterm in ${content[*]}
  do
    case $iterm in
    "--source_path")
      source_path=${content[$count+1]}
      echo -e "[\033[32mPARSING\033[0m] Source path: $source_path"
    ;;

    "--target_path")
      target_path=${content[$count+1]}
      echo -e "[\033[32mPARSING\033[0m] Target path: $target_path"
    ;;

    "--condition")
      condition=${content[$count+1]}
      echo -e "[\033[32mPARSING\033[0m] Condition: $condition"
    ;;

    "--exclude")
      exclude=${content[$count+1]}
      echo -e "[\033[32mPARSING\033[0m] Exclude: $exclude"
    ;;

    "--num_workers")
      num_workers=${content[$count+1]}
      echo -e "[\033[32mPARSING\033[0m] Number of workers: $num_workers"
    ;;  
    esac

    let count++
  done

  if [[ $condition == "" ]];then
    condition=""
    echo -e "[\033[32mDEFAULT\033[0m] Condition: $condition"
  fi  

  if [[ $exclude == "" ]];then
    exclude=""
    echo -e "[\033[32mDEFAULT\033[0m] Exclude: $exclude"
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


}

clean(){
  rm thread
}

# Download
download(){

  dir=${source_path##*/}
  dir=${dir%.*}
  target_path=$target_path/$dir

  echo -e "[\033[32mRUNNING\033[0m] Download from $source_path into $target_path"

  if [[ ! -d $target_path ]];then
    mkdir -p $target_path
  fi

  iconv -f "gb2312" -t "UTF-8" $source_path -o $source_path.utf8

  sed -i "s///g" $source_path.utf8

  index=1
  num_iterms=$(cat $source_path.utf8 |wc -l)

  while read line
  do
    if [[ $line == *http* ]];then
      line=(${line//,/ })
      url=""

      for col in ${line[*]}
      do
        if [[ $col == http* ]];then
          url=$col
        fi
      done

      if ([[ ! ${line[*]} == *$exclude* ]] || [[ $exclude == "" ]]) && [[ ${line[*]} == *$condition* ]];then 
        if [[ ! -f $target_path/${url##*/} ]];then
          echo -e "[\033[32mDOWNLOADING\033[0m][$((index*100/num_iterms))%][$index/$num_iterms] wget -P $target_path $url &"
          read -u 9
          wget -P $target_path $url -q &
          echo -ne "\n" 1>&9
        else  
          echo -e "[\033[33mEXISTED\033[0m][$((index*100/num_iterms))%][$index/$num_iterms] $url"
        fi  
      else
        echo -e "[\033[31mEXCLUDED\033[0m][$((index*100/num_iterms))%][$index/$num_iterms] $url"
      fi
    fi

    let index++
  done < $source_path.utf8

  rm $source_path.utf8

}

# Main
main(){
  echo -e "[\033[32mCONFIG\033[0m] Download visual data"

  parser_para $*

  download $source_path $target_path

  clean

  echo -e "[\033[32mDONE\033[0m]"
}

# Run
main $*
