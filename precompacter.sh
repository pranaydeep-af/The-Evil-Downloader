# precompacts files and also filters error files if any.

folderpath=~/MultipartDownloads/"$1"

parts=`cat "$folderpath"/parts.txt`
for (( i = 1 ; i <= parts ; i++ )) do
	##filename scheme: part6a1, etc.
	#subparts=`ls -l $folderpath | grep "part{$i}a" | wc -l`
	#for (( j = 1 ; j <=subparts ; j++ )) do
	
	#error file discarding: if any part is less than 5kb, most likely an error message, so delete that file so that it redownloads.
	echo "Checking errors in $folderpath"
	if [ -e "$folderpath"/part$i ]
	then
		filesize=`ls -l "$folderpath"/part$i | awk -F" " '{ print $5 }'`
		#echo "Filesize: $filesize"
		if [ $filesize -lt 5120 ]
		then
			echo "Detected that part$i (filesize $filesize bytes) is less than 5120 bytes, so it may be an error. Deleting the file so that can be redowloaded. (backup also made)"
			mv "$folderpath"/part$i "$folderpath"/backuppart$i
			rm "$folderpath"/part$i	
			
			if [ -e "$folderpath"/part{$i}a ]
			then
				echo "Also found part{$i}a, which will probably be invalid too. Deleting it as well."
				rm "$folderpath"/part{$i}a
			fi
		fi
	fi
	if [ -e "$folderpath"/part{$i}a ]
	then
		cat "$folderpath"/part{$i}a >> "$folderpath"/part$i
		rm "$folderpath"/part{$i}a
	fi
	#done
done
