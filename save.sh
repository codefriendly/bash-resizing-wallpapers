#!/bin/bash

## This is a script to save multiple sizes for a wallpaper from a number of source files
## Run it with arguments, see help() function for the list of all possible arguments
## 
## Requires:
## - imagemagick
## - python
## - nice ( To not use "nice", find 'nice -n 19 convert' and replace it with simply 'convert' )
## 
## Usage: bash save.sh -123m -f 'filename'
## or
## bash save.sh -a -f 'filename'
## or
## bash save.sh -?


function help()
{
cat << EOF
OPTIONS:
   -?      Show this message
   -1      Save 1 monitor wallpaper from src-8000x5000 (or src-4000x2500).jpg
   -2      Save 2 monitor wallpaper from src-8000x3000.jpg
   -3      Save 3 monitor wallpaper from src-8000x2000.jpg
   -m      Save mobile wallpaper from src-2048x2048.jpg
   -a      Include all above options
   -o      Overwrite existing files (by default, exising JPG files are skipped)
   -f      filename, f.e. life_is_good
EOF
}

## shortcut function for python; used for math calculations
## example: $(math $dst_w/$src_w);
## example: $(math "max(2,3)");

function math(){
  #echo `echo "$@" | bc -l`
  echo $(python -c "from __future__ import division; print $@")
}



## resizr: generate a string with parameters for "convert" function
## usage: $(resizr src_w src_h dst_w dst_h)
## example: $(resizr 2560 1600 320 480)

function resizr(){
  local src_w=${1}
  local src_h=${2}
  local dst_w=${3}
  local dst_h=${4}
  local ratio1=$(math $dst_w/$src_w);
  local ratio2=$(math $dst_h/$src_h);
  local ratio=$(math "max($ratio1,$ratio2)")
  local inter_w=$(math "int($src_w*$ratio)")
  local inter_h=$(math "int($src_h*$ratio)")
  local sharp=$(math "round((1/$ratio)/4, 2)")
  echo "-interpolate bicubic -filter Lagrange -resize ${inter_w}x${inter_h} -gravity center -crop ${dst_w}x${dst_h}+0+0 +repage -unsharp 0x${sharp} +repage -density 72x72 +repage"
}



## cropr: generate a string with parameters for "convert" function
## usage: $(cropr dst_w dst_h gravity)
## example: $(cropr 480 480 center)

function cropr(){
  echo "-gravity ${3} -crop ${1}x${2}+0+0 +repage"
}



## save: shortcut function to resize an image and save 2 copies (with/without signature)
## parameters:
## ${1}: source image
## ${2}: dst width
## ${3}: dst height
## ${4}: signature size; example: 96x30 (keep empty to skip saving signed file)
## ${5}: signature offset; example: +4+4 (keep empty to skip saving signed file)
## ${6}: output filename suffix (example: x2_1) (optional)

function save(){
  local src=${1}
  local dst_w=${2}
  local dst_h=${3}
  local sig=${4}
  local sig_offset=${5}
  local suffix=${6}
	echo -n "${dst_w}x${dst_h}${suffix} "
  
  # read width and height of source file
  local src_w=$(identify -format "%w" "${src}")
  local src_h=$(identify -format "%h" "${src}")
  local dst_filename=${dst_folder}vladstudio_${filename}_${dst_w}x${dst_h}${suffix}

  # save file if it does not exist, or overwrite is true
  if [ ! -f ${dst_filename}.jpg -o ${do_overwrite} ]; then
    $convert ${src} $(resizr ${src_w} ${src_h} ${dst_w} ${dst_h}) ${temp}temp.psd
    
    # save jpg without signature
    $convert ${temp}temp.psd -quality 100 ${dst_filename}.jpg
    
    #save jpg with signature, if provided
    if [ ! -z ${sig} ]; then $convert ${temp}temp.psd ${temp}sig-${sig}.png -gravity southeast -geometry ${sig}${sig_offset} -composite -quality 100 ${dst_filename}_signed.jpg; fi
  fi

}



## shortcut variable for "convert" command, for minimum CPU usage

convert='nice -n 19 convert'

## empty default values for variables and actions

do_1_monitor=false
do_2_monitor=false
do_3_monitor=false
do_mobile=false
do_overwrite=false
filename=


## read actions and variables from command line arguments

while getopts “?123maof:” OPTION
do
     case $OPTION in
         1)
            do_1_monitor=true
            ;;
         2)
            do_2_monitor=true
            ;;
         3)
            do_3_monitor=true
            ;;
         m)
            do_mobile=true
            ;;
         a)
            do_1_monitor=true
  			do_2_monitor=true
  			do_3_monitor=true
  			do_mobile=true
            ;;
         o)
             do_overwrite=true
             ;;
         f)
            filename=$OPTARG
            ;;
         ?)
            help
            exit 1
            ;;
     esac
done


## set paths to folders and source files

# folder with source images - you can use ${filename} and provide filename through command line argument
src_folder=ENTER_YOUR_VALUE/${filename}/

# folder for destination images
dst_folder=ENTER_YOUR_VALUE/${filename}/

# folder for temporary images
temp="ENTER_YOUR_VALUE/"

# source files
src_1_monitor="${src_folder}src-8000x5000.jpg"
src_2_monitors="${src_folder}src-8000x3000.jpg"
src_3_monitors="${src_folder}src-8000x2000.jpg"
src_mobile="${src_folder}src-2048x2048.jpg"
src_signature="${src_folder}sig.png"

# disable actions if source files are missing
if [ ! -f ${src_1_monitor} ]; then
   do_1_monitor=false
fi
if [ ! -f ${src_2_monitors} ]; then
   do_2_monitor=false
fi
if [ ! -f ${src_3_monitors} ]; then
   do_3_monitor=false
fi
if [ ! -f ${src_mobile} ]; then
   do_mobile=false
fi



## let's start!

echo ${filename}
mkdir -p ${dst_folder}
mkdir -p ${temp}

## prepare signature in different sizes

$convert ${src_signature} $(resizr 256 80 74 23)  ${temp}sig-74x23.png
$convert ${src_signature} $(resizr 256 80 96 30)  ${temp}sig-96x30.png
$convert ${src_signature} $(resizr 256 80 102 32) ${temp}sig-102x32.png
$convert ${src_signature} $(resizr 256 80 130 41) ${temp}sig-130x41.png
$convert ${src_signature} $(resizr 256 80 140 44) ${temp}sig-140x44.png
$convert ${src_signature} $(resizr 256 80 170 53) ${temp}sig-170x53.png
$convert ${src_signature} $(resizr 256 80 186 58) ${temp}sig-186x58.png


## saving wallpapers for 4:3 screens

if $do_1_monitor; then

## prepare temporary ('intermediary') images, for faster resizing
$convert ${src_1_monitor} $(resizr 8000 5000 3200 2000) ${temp}3200x2000.psd

#4:3
save ${temp}3200x2000.psd   800 600		130x41	+12+28
save ${temp}3200x2000.psd   1024 768	130x41	+12+28
save ${temp}3200x2000.psd   1152 864	130x41	+12+28
save ${temp}3200x2000.psd   1280 960	140x44	+12+40
save ${temp}3200x2000.psd	1280 1024	140x44	+12+40
save ${temp}3200x2000.psd	1400 1050	140x44	+12+40
save ${temp}3200x2000.psd	1440 960	140x44	+12+40
save ${temp}3200x2000.psd	1600 1200	140x44	+12+40
save ${temp}3200x2000.psd	1920 1440	170x53	+12+40

#thumbs
save ${temp}3200x2000.psd   640 400
save ${temp}3200x2000.psd   500 375
save ${temp}3200x2000.psd	300 225
save ${temp}3200x2000.psd	320 200
save ${temp}3200x2000.psd	200 150
save ${temp}3200x2000.psd	240 150
save ${temp}3200x2000.psd	100 75
save ${temp}3200x2000.psd	120 75
save ${src_mobile}	160 240
fi

#wide
if $do_1_monitor; then
save ${temp}3200x2000.psd		 800 480		102x32		+12+28
save ${temp}3200x2000.psd		1024 600		102x32		+12+28
save ${temp}3200x2000.psd		1280 800		102x32		+12+28
save ${temp}3200x2000.psd		1366 768		130x41		+12+40
save ${temp}3200x2000.psd		1440 900		140x44		+12+40
save ${temp}3200x2000.psd		1600 900		140x44		+12+40
save ${temp}3200x2000.psd		1680 1050		170x53		+12+40
save ${temp}3200x2000.psd		1920 1080		186x58		+12+40
save ${temp}3200x2000.psd		1920 1200		186x58		+12+40
save ${temp}3200x2000.psd		2560 1280		186x58		+12+40
save ${temp}3200x2000.psd		2560 1440		186x58		+12+40
save ${temp}3200x2000.psd		2560 1600		186x58		+12+40
save ${temp}3200x2000.psd		2880 1800		186x58		+12+40
fi

#mobile
if $do_mobile; then
save ${src_mobile}		120 160		74x23	+4+4
save ${src_mobile}		128 97		74x23	+4+4
save ${src_mobile}		128 128		74x23	+4+4
save ${src_mobile}		128 160		74x23	+4+4
save ${src_mobile}		132 176		74x23	+4+4
save ${src_mobile}		160 128		74x23	+4+4
save ${src_mobile}		174 136		74x23	+4+4
save ${src_mobile}		176 176		74x23	+4+4
save ${src_mobile}		176 192		74x23	+4+4
save ${src_mobile}		176 208		74x23	+4+4
save ${src_mobile}		176 220		74x23	+4+4
save ${src_mobile}		208 144		74x23	+4+4
save ${src_mobile}		208 208		74x23	+4+4
save ${src_mobile}		220 176		74x23	+4+4
save ${src_mobile}		240 160		74x23	+4+4
save ${src_mobile}		240 240		74x23	+4+4
save ${src_mobile}		240 260		74x23	+4+4
save ${src_mobile}		240 300		74x23	+4+4
save ${src_mobile}		240 320		74x23	+4+4
save ${src_mobile}		320 200		74x23	+4+4
save ${src_mobile}		320 240		96x30	+4+4
save ${src_mobile}		320 480		96x30	+4+4
save ${src_mobile}		352 416		96x30	+4+4
save ${src_mobile}		360 480		96x30	+4+4
save ${src_mobile}		360 640		96x30	+4+4
save ${src_mobile}		480 272		96x30	+4+4
save ${src_mobile}		480 320		96x30	+4+4
save ${src_mobile}		480 360		96x30	+4+4
save ${src_mobile}		480 640		96x30	+4+4
save ${src_mobile}		480 800		96x30	+4+4
save ${src_mobile}		640 360		102x32	+4+4
save ${src_mobile}		640 480		102x32	+4+4
save ${src_mobile}		854 960		102x32	+4+4
save ${src_mobile}		960 540		140x44	+4+4
save ${src_mobile}		960 640		140x44	+4+4
save ${src_mobile}		960 854		102x32	+4+4
save ${src_mobile}		640 960		140x44	+4+4
save ${src_mobile}		854 440		140x44	+4+4
save ${src_mobile}		854 480		140x44	+4+4
save ${src_mobile}		960 800		140x44	+4+4
save ${src_mobile}		800 960		140x44	+4+4
save ${src_mobile}		1080 960	140x44	+4+4
save ${src_mobile}		2048 2048	186x58	+12+12
save ${src_mobile}		1024 1024	140x44	+12+12
save ${src_mobile}		1440 1280	170x53	+12+40
fi

########## 2 monitors

if $do_2_monitor; then

$convert ${src_2_monitors} $(cropr 4000 3000 west) ${temp}4000x3000_1.psd
$convert ${src_2_monitors} $(cropr 4000 3000 east) ${temp}4000x3000_2.psd

# thumbs
save ${src_2_monitors}  200 75
save ${src_2_monitors}  400 150

# single image
save ${src_2_monitors}	2048 768		130x41	+12+28
save ${src_2_monitors}	2304 864		130x41	+12+28
save ${src_2_monitors}	2560 960		140x44	+12+40
save ${src_2_monitors}	2560 1024		140x44	+12+40
save ${src_2_monitors}	2800 1050		140x44	+12+40
save ${src_2_monitors}	2880 960		140x44	+12+40
save ${src_2_monitors}	3200 1200		170x53	+12+40
save ${src_2_monitors}	3840 1440		170x53	+12+40

save ${src_2_monitors}	2560 800		130x41	+12+28
save ${src_2_monitors}	2732 768		140x44	+12+40
save ${src_2_monitors}	2880 900		140x44	+12+40
save ${src_2_monitors}	3200 900		140x44	+12+40
save ${src_2_monitors}	3360 1050		140x44	+12+40
save ${src_2_monitors}	3840 1080		140x44	+12+40
save ${src_2_monitors}	3840 1200		170x53	+12+40
save ${src_2_monitors}	5120 1440		170x53	+12+40
save ${src_2_monitors}	5120 1600		170x53	+12+40

#x2_1
save ${temp}4000x3000_1.psd	1024 768		130x41	+12+28	x2_1
save ${temp}4000x3000_1.psd	1152 864		130x41	+12+28	x2_1
save ${temp}4000x3000_1.psd	1280 960		140x44	+12+40	x2_1
save ${temp}4000x3000_1.psd	1280 1024		140x44	+12+40	x2_1
save ${temp}4000x3000_1.psd	1400 1050		140x44	+12+40	x2_1
save ${temp}4000x3000_1.psd	1440 1080		140x44	+12+40	x2_1
save ${temp}4000x3000_1.psd	1600 1200		170x53	+12+40	x2_1
save ${temp}4000x3000_1.psd	1920 1440		170x53	+12+40	x2_1

save ${temp}4000x3000_1.psd	1280 800		130x41	+12+28	x2_1
save ${temp}4000x3000_1.psd	1366 854		140x44	+12+40	x2_1
save ${temp}4000x3000_1.psd	1440 900		140x44	+12+40	x2_1
save ${temp}4000x3000_1.psd	1600 1000		140x44	+12+40	x2_1
save ${temp}4000x3000_1.psd	1680 1050		140x44	+12+40	x2_1
save ${temp}4000x3000_1.psd	1920 1080		140x44	+12+40	x2_1
save ${temp}4000x3000_1.psd	1920 1200		170x53	+12+40	x2_1
save ${temp}4000x3000_1.psd	2560 1440		170x53	+12+40	x2_1
save ${temp}4000x3000_1.psd	2560 1600		170x53	+12+40	x2_1

#x2_2
save ${temp}4000x3000_2.psd	1024 768		130x41	+12+28	x2_2
save ${temp}4000x3000_2.psd	1152 864		130x41	+12+28	x2_2
save ${temp}4000x3000_2.psd	1280 960		140x44	+12+40	x2_2
save ${temp}4000x3000_2.psd	1280 1024		140x44	+12+40	x2_2
save ${temp}4000x3000_2.psd	1400 1050		140x44	+12+40	x2_2
save ${temp}4000x3000_2.psd	1440 1080		140x44	+12+40	x2_2
save ${temp}4000x3000_2.psd	1600 1200		170x53	+12+40	x2_2
save ${temp}4000x3000_2.psd	1920 1440		170x53	+12+40	x2_2

save ${temp}4000x3000_2.psd	1280 800		130x41	+12+28	x2_2
save ${temp}4000x3000_2.psd	1366 854		140x44	+12+40	x2_2
save ${temp}4000x3000_2.psd	1440 900		140x44	+12+40	x2_2
save ${temp}4000x3000_2.psd	1600 1000		140x44	+12+40	x2_2
save ${temp}4000x3000_2.psd	1680 1050		140x44	+12+40	x2_2
save ${temp}4000x3000_2.psd	1920 1080		140x44	+12+40	x2_2
save ${temp}4000x3000_2.psd	1920 1200		170x53	+12+40	x2_2
save ${temp}4000x3000_2.psd	2560 1440		170x53	+12+40	x2_2
save ${temp}4000x3000_2.psd	2560 1600		170x53	+12+40	x2_2


fi

########## 3 monitors

if $do_3_monitor; then

$convert ${src_3_monitors} $(cropr 2667 2000 west) ${temp}2667x2000x3_1.psd
$convert ${src_3_monitors} $(cropr 2667 2000 center) ${temp}2667x2000x3_2.psd
$convert ${src_3_monitors} $(cropr 2667 2000 east) ${temp}2667x2000x3_3.psd

# thumbs
save ${src_3_monitors}   300 75
save ${src_3_monitors}   600 150

#single
save ${src_3_monitors}	3072 768		130x41	+12+28
save ${src_3_monitors}	3456 864		130x41	+12+28
save ${src_3_monitors}	3840 960		140x44	+12+40
save ${src_3_monitors}	3840 1024		140x44	+12+40
save ${src_3_monitors}	4200 1050		140x44	+12+40
save ${src_3_monitors}	4320 960		140x44	+12+40
save ${src_3_monitors}	4800 1200		170x53	+12+40
save ${src_3_monitors}	5760 1440		170x53	+12+40

save ${src_3_monitors}	3840 800		130x41	+12+28
save ${src_3_monitors}	4098 768		140x44	+12+40
save ${src_3_monitors}	4320 900		140x44	+12+40
save ${src_3_monitors}	4800 900		140x44	+12+40
save ${src_3_monitors}	5040 1050		140x44	+12+40
save ${src_3_monitors}	5760 1080		140x44	+12+40
save ${src_3_monitors}	5760 1200		170x53	+12+40
save ${src_3_monitors}	7680 1440		170x53	+12+40
save ${src_3_monitors}	7680 1600		170x53	+12+40

#x3_1
save ${temp}2667x2000x3_1.psd		1024 768		130x41	+12+28	x3_1
save ${temp}2667x2000x3_1.psd		1152 864		130x41	+12+28	x3_1
save ${temp}2667x2000x3_1.psd		1280 960		140x44	+12+40	x3_1
save ${temp}2667x2000x3_1.psd		1280 1024		140x44	+12+40	x3_1
save ${temp}2667x2000x3_1.psd		1400 1050		140x44	+12+40	x3_1
save ${temp}2667x2000x3_1.psd		1440 1080		140x44	+12+40	x3_1
save ${temp}2667x2000x3_1.psd		1600 1200		170x53	+12+40	x3_1
save ${temp}2667x2000x3_1.psd		1920 1440		170x53	+12+40	x3_1

save ${temp}2667x2000x3_1.psd		1280 800		130x41	+12+28	x3_1
save ${temp}2667x2000x3_1.psd		1366 854		140x44	+12+40	x3_1
save ${temp}2667x2000x3_1.psd		1440 900		140x44	+12+40	x3_1
save ${temp}2667x2000x3_1.psd		1600 1000		140x44	+12+40	x3_1
save ${temp}2667x2000x3_1.psd		1680 1050		140x44	+12+40	x3_1
save ${temp}2667x2000x3_1.psd		1920 1080		140x44	+12+40	x3_1
save ${temp}2667x2000x3_1.psd		1920 1200		170x53	+12+40	x3_1
save ${temp}2667x2000x3_1.psd		2560 1440		170x53	+12+40	x3_1
save ${temp}2667x2000x3_1.psd		2560 1600		170x53	+12+40	x3_1

#x3_2
save ${temp}2667x2000x3_2.psd		1024 768		130x41	+12+28	x3_2
save ${temp}2667x2000x3_2.psd		1152 864		130x41	+12+28	x3_2
save ${temp}2667x2000x3_2.psd		1280 960		140x44	+12+40	x3_2
save ${temp}2667x2000x3_2.psd		1280 1024		140x44	+12+40	x3_2
save ${temp}2667x2000x3_2.psd		1400 1050		140x44	+12+40	x3_2
save ${temp}2667x2000x3_2.psd		1440 1080		140x44	+12+40	x3_2
save ${temp}2667x2000x3_2.psd		1600 1200		170x53	+12+40	x3_2
save ${temp}2667x2000x3_2.psd		1920 1440		170x53	+12+40	x3_2

save ${temp}2667x2000x3_2.psd		1280 800		130x41	+12+28	x3_2
save ${temp}2667x2000x3_2.psd		1366 854		140x44	+12+40	x3_2
save ${temp}2667x2000x3_2.psd		1440 900		140x44	+12+40	x3_2
save ${temp}2667x2000x3_2.psd		1600 1000		140x44	+12+40	x3_2
save ${temp}2667x2000x3_2.psd		1680 1050		140x44	+12+40	x3_2
save ${temp}2667x2000x3_2.psd		1920 1080		140x44	+12+40	x3_2
save ${temp}2667x2000x3_2.psd		1920 1200		170x53	+12+40	x3_2
save ${temp}2667x2000x3_2.psd		2560 1440		170x53	+12+40	x3_2
save ${temp}2667x2000x3_2.psd		2560 1600		170x53	+12+40	x3_2

#x3_3
save ${temp}2667x2000x3_3.psd		1024 768		130x41	+12+28	x3_3
save ${temp}2667x2000x3_3.psd		1152 864		130x41	+12+28	x3_3
save ${temp}2667x2000x3_3.psd		1280 960		140x44	+12+40	x3_3
save ${temp}2667x2000x3_3.psd		1280 1024		140x44	+12+40	x3_3
save ${temp}2667x2000x3_3.psd		1400 1050		140x44	+12+40	x3_3
save ${temp}2667x2000x3_3.psd		1440 1080		140x44	+12+40	x3_3
save ${temp}2667x2000x3_3.psd		1600 1200		170x53	+12+40	x3_3
save ${temp}2667x2000x3_3.psd		1920 1440		170x53	+12+40	x3_3

save ${temp}2667x2000x3_3.psd		1280 800		130x41	+12+28	x3_3
save ${temp}2667x2000x3_3.psd		1366 854		140x44	+12+40	x3_3
save ${temp}2667x2000x3_3.psd		1440 900		140x44	+12+40	x3_3
save ${temp}2667x2000x3_3.psd		1600 1000		140x44	+12+40	x3_3
save ${temp}2667x2000x3_3.psd		1680 1050		140x44	+12+40	x3_3
save ${temp}2667x2000x3_3.psd		1920 1080		140x44	+12+40	x3_3
save ${temp}2667x2000x3_3.psd		1920 1200		170x53	+12+40	x3_3
save ${temp}2667x2000x3_3.psd		2560 1440		170x53	+12+40	x3_3
save ${temp}2667x2000x3_3.psd		2560 1600		170x53	+12+40	x3_3

fi


rm -rf ${temp}
echo "--- Done!"