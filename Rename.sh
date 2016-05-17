#!/bin/bash

EXT=".avi"   # the extension of files that we are interested in

for file in *$EXT; do

        FILE_LEN=(${#file}-${#EXT})   # deduce length of filename w/o extension

        MODFILE=`echo ${file:0:$FILE_LEN} | tr '.' ' '`   # convert file name using substring of full file name

        mv $file "${MODFILE}${EXT}"   # perform move; surround modified filename with quotes so spaces aren't literally interpreted.

done

#rename 's/\.shp$/_poly.shp/' *shp
#rename 's/_/ /g' *
#rename 's/\.mp4$/ [TheEvilTwin].mp4/' *mp4
