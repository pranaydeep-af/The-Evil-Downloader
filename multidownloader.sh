#Usage: 
#1 <url> 
#2 <number of parts to do it in> 
#3 <name of folder to save in> (default, if possible: file name)
#4 <interface number to start from (default is 0)>
#5 <number of aliases to use (upper limit) (default: all available)>
#6 <size of fixed block to use (num of parts will be calcuated acc to it)

url=$1
echo "URL: $url"
parts="$2"
echo "Parts to split into: $parts"

if [ $# -ge 3 ]
then
name="$3"
else
echo "Autodetecting file name."
name=`echo "${url##*/}"`
fi

echo "Destination file name: $name"

startingalias=0

if [ $# -ge 4 ]
then
startingalias="$4"
echo "Entered alias to start from: eno1:$startingalias."
fi

if [ $# -ge 5 ]
then
endingalias="$5"
echo "Entered alias to use up to: eno1:$endingalias."
fi

if [ $# -eq 6 ]
then
	manualpartsize=`expr "$6" \* 1024 \* 1024 `
	echo "Size of each part should be (in  bytes): $manualpartsize ."
	echo "The number of parts required will be calculated after size is retreived."
fi
#-------------------------------------------------------------------------------------------
sudo echo "bash multidownloader.sh '$1' '$2' '$3'" >> ~/MultipartDownloads/commandhistory.txt


if [[ -e ~/MultipartDownloads/"$name"/completed ]]
then
	echo "This has already been downloaded you cunt. I am leaving :\ "
	exit 0
fi

read -p "Ready to go. Press 1 to Start the Download. 2 If you want to do Offline Concatenation. 3 If You Have No idea What To Do:	" conf
clear
if [ $conf -eq 2 ]
then
#-------------------------------------------------------------------------------------------

#-------------------------------------------------------------------------------------------

ls -l ~/MultipartDownloads/"$name"
echo -n "Running precompacter to Merge Subparts and Filter Error Files If Any... "
bash precompacter.sh "$name"
echo "Done. Contents of the folder are now: "
ls -l ~/MultipartDownloads/"$name"

#-------------------------------------------------------------------------------------------

	read -p "Would you like to run the concatenation script? ( 1 or 2 ): " concatres
	clear	
	if [ $concatres -eq 1 ]
	then
		echo "Concatenating the downloaded files."
	bash concat.sh "$name" "$name"
	else
		echo "What the fuck do I do then?"
	fi
	
	read -p "Would You Like To Delete The Temporary Part Files Of The Download? ( 1 or 2 ): " tempdelres
	clear	
	if [ $tempdelres -eq 1 ]
	then
		echo "Deleting the temporary part files. Say bye!!!"
		rm ~/MultipartDownloads/"$name"/part*
		rm ~/MultipartDownloads/"$name"/*.txt
	else
		echo "What to do next then?"
	fi
	exit 1
#-------------------------------------------------------------------------------------------
elif [[ $conf -eq 3 ]]
then
echo "I knew you were a dumbass. Go Watch Porn now"
exit 1
fi

#-------------------------------------------------------------------------------------------

globbingoff=0
s5on=0

#check for support normally:
echo "Getting headers and file size via normal connection: "
headers=`curl -sIL --interface eno1:1 "$url" --range 0-10000 --retry 5`
echo "Headers for file: "
echo "$headers"
echo "-------------------------------------------------------------"
echo "$headers" | grep "206 Partial Content"
echo "-------------------------------------------------------------"

success=0

echo -n "Getting file size via normal method... "
size=`echo "$headers" | grep Content-Range | awk -F "/" '{ print $2 }' | head --bytes=-2`

bytes=`echo $size | wc -c`


if [ $bytes -le 1 ]
then
	size=`echo "$headers" | grep Content-Length | awk -F " " '{ print $2 }' | head --bytes=-2`
	bytes=`echo $size | wc -c`
fi
#echo "bytes=$bytes"
if [ $bytes -gt 1 ]
then
	echo "We Got The Size Buddy!. Size is $size bytes."
	success=1
else
	echo "PHAIL. Couldn't get size (Received headers):"
	echo "-------------------------------------------------------------"
	echo "$headers"
	echo "-------------------------------------------------------------"
	echo -n "Retrying with URL globbing off... "
	#echo "-------------------------------------------------------------"
	#curl -sIL --interface eno1:0 "$url" --range 0-100000 --retry 3 -g
	#echo "-------------------------------------------------------------"
	headersgoff=`curl -sIL --interface eno1:0 "$url" --range 0-100000 --retry 3 -g`
	size=`echo "$headersgoff" | grep Content-Range | awk -F "/" '{ print $2 }' | head --bytes=-2`
fi

bytes=`echo $size | wc -c`
#echo "bytes=$bytes"
if [ $bytes -le 1 ]
then
	size=`echo "$headers" | grep Content-Length | awk -F " " '{ print $2 }' | head --bytes=-2`
bytes=`echo $size | wc -c`
fi


#-------------------------------------------------------------------------------------------

manualsize=0
read -p "Enter a manual size in Bytes for the file, or enter 0 to use the autodetected size: " manualsize

if [ manualsize -eq 0 ]
then 
	manualsize=$size
fi
	size=`echo $manualsize`

clear
#let size=$size
#let parts=$parts
#let sizeofpart=$sizeofpart

echo "Extra arguments being used: globbingoff=$globbingoff s5on=$s5on."

multiplier=1
if [[ `echo "$size" | grep "KB" -o | wc -c` -gt 0 ]]
then
	multiplier=1024
	echo "Size in KB detected. Converting to bytes."
	#read -p "Enter file size in bytes: " size
elif [[ `echo "$size" | grep "MB" -o | wc -c` -gt 0 ]]
then
	multiplier=1048576
	echo "Size in MB detected. Converting to bytes."
	#read -p "Enter file size in bytes: " size
elif [[ `echo "$size" | grep "GB" -o | wc -c` -gt 0 ]]
then
	multiplier=1073741824
	echo "Size in GB detected. Converting to bytes."
	#read -p "Enter file size in bytes: " size
fi
if [[ $multiplier -ne 1 ]]
then
	temp=`echo $size | awk -F " " '{ print $1 }'`
	size=`echo $temp \* $multiplier | bc`
	echo "Prelim Calculated size in bytes: $size bytes."
	size=`echo $size / 1 | bc`
	size=`echo $size + 1 | bc`
	echo "Calculated size in bytes: $size bytes."
	echo "Size converted to bytes: $size. "
	echo "Waiting 3 seconds."
	sleep 3
fi

#-------------------------------------------------------------------------------------------

if [ $# -eq 6 ]
then
	#if split is done on basis of fixed part size:
	sizeofpart=$manualpartsize
	parts=`expr $size / $sizeofpart`
	temp=`expr "$sizeofpart" \* "$parts"`
	lastpartsize=`expr "$size" - "$temp"`
	partsplusone=`expr "$parts" + 1`
	parts=$partsplusone
else
	#if split is done on basis of number of parts:
	sizeofpart=`expr "$size" / "$parts" `
	partsminusone=`expr "$parts" - 1`
	temp=`expr "$sizeofpart" \* "$partsminusone"`
	lastpartsize=`expr "$size" - "$temp"`
fi

partsminusone=`expr "$parts" - 1`
temp=`expr "$sizeofpart" \* "$partsminusone"`
lastpartsize=`expr "$size" - "$temp"`

echo "Size of each part ( x $partsminusone parts): $sizeofpart bytes."
echo "Size of last part (#$parts): $lastpartsize bytes."

lpsizebytes=`echo $lastpartsize | wc -c`
if [ $lpsizebytes -eq 0 -o $lpsizebytes -eq 1 ]
then
echo "Error during calculation of part sizes. Check it out. Exiting."
exit 1
fi


#-------------------------------------------------------------------------------------------


if [ ! -d ~/MultipartDownloads/"$name" ]; then

	read -p "This download's folder does not exist. Would you like to create the folder and start the download? ( 1 or 2 ): " conf
	clear	
	if [ $conf -eq 1 ]
	then
		echo "Folder Created."
		mkdir ~/MultipartDownloads/"$name"
	else
		echo "LOL! Goodbye then!"		
		exit 1
	fi
else
	echo "This download's folder already exists. Showing current files."
	ls -l ~/MultipartDownloads/"$name"
	read -p "Would you like to: 1. Resume The Download or 2: Delete The Folder and Start Over or 3:Get abused and quit. " conf
	if [ $conf -eq 1 ]
	then
		echo "Okay!. Resuming download."
	elif [ $conf -eq 2 ]
	then
		rm -rf ~/MultipartDownloads/"$name"
		echo "Deleted Previous Files For This Download. Starting over.."
		mkdir ~/MultipartDownloads/"$name"
	else
		echo "MOFO What the hell do you think you are doing? Fuck Off! Quiting......"		
		exit 1
	fi
fi

#-------------------------------------------------------------------------------------------

if [ ! -e ~/MultipartDownloads/"$name"/size.txt ]; then
	echo "$size" > ~/MultipartDownloads/"$name"/size.txt
fi
if [ ! -e ~/MultipartDownloads/"$name"/sizeofpart.txt ]; then
	echo "$sizeofpart" > ~/MultipartDownloads/"$name"/sizeofpart.txt
fi
if [ ! -e ~/MultipartDownloads/"$name"/parts.txt ]; then
	echo "$parts" > ~/MultipartDownloads/"$name"/parts.txt
fi
if [ ! -e ~/MultipartDownloads/"$name"/lastpartsize.txt ]; then
	echo  "$lastpartsize" > ~/MultipartDownloads/"$name"/lastpartsize.txt
fi

#-------------------------------------------------------------------------------------------

#	echo "$size" > ~/MultipartDownloads/"$name"/size.txt
#	echo "$sizeofpart" > ~/MultipartDownloads/"$name"/sizeofpart.txt
#	echo "$parts" > ~/MultipartDownloads/"$name"/parts.txt
#	echo  "$lastpartsize" > ~/MultipartDownloads/"$name"/lastpartsize.txt

#-------------------------------------------------------------------------------------------

#echo -n "Running Precompacter To Merge Subparts and Filter Error Files If Any... "
#bash precompacter.sh "$name"
#echo "Done. Contents of folder are now: "
#ls -l ~/MultipartDownloads/"$name"

#-------------------------------------------------------------------------------------------

ifconfig | grep "eno1:" > aliases.txt
numofaliases=`cat aliases.txt | wc -l`
aliaslimit=`expr $numofaliases - 1`
echo "Total number of Aliases up: $numofaliases (Upper Limit: eno1:$aliaslimit)"

if [[ $# -ge 5 ]]
then
	if [[ $endingalias -le $aliaslimit ]]
	then
		echo "You have Entered The Upper Limit Alias to Use: eno1:$endingalias."
	else
		echo "You have Entered the Upper Limit Alias (eno1:$endingalias) Higher Than The Number of Aliases Currently Available (eno1:$aliaslimit). Didn't Know You Were This Stupid. So, Will Use Only Till The Available Limit."
		endingalias=$aliaslimit
	fi
else
	endingalias=$aliaslimit
	echo "You Have Not Entered A Custom Upper Alias Limit To Use. There are $numofaliases Aliases (till eno1:$aliaslimit) Up Right Now. So, Will Use Till eno1:$endingalias."
fi

cur=0
endcur=0
interface=$startingalias
i=1

for (( interface = $startingalias , i = 1 ; interface <= $endingalias && i <= $parts; i++ )) do

	endcur=`expr $cur + $sizeofpart - 1`
	if [ $i -eq $parts ]
	then
		endcur=$size
		sizeofpart=$lastpartsize
	fi
	
	partpath=~/MultipartDownloads/"$name"/part$i
	if [[ -e "$partpath" ]]
	then
	
		filesize=`ls -l "$partpath" | awk -F" " '{ print $5 }'`
		if [[ $filesize -eq $sizeofpart ]]
		then
			#this part is already done completely. skip to next part.
			echo "Completed part=$i Found. (filesize $filesize bytes.) Skipping Part. Current Interface=eno1:$interface"
			cur=`expr $endcur + 1`
			#interface=`expr $interface + 1` <-we aren't supposed to use next interface here
	
		elif [[ $filesize -lt $sizeofpart ]]
		then
			echo "Current Size of part$i is $filesize bytes, and cur=$cur. So, Launching Remaining as Subpart part{$i}a on Interface eno1:$interface."
			cur=`expr $cur + $filesize`
			echo -n "Launching part=part{$i}a on Interface eno1:$interface From cur=$cur to endcur=$endcur ..."
			if [ $globbingoff -eq 1 ]
			then
				#echo "trying with globbing off."
				konsole --title "Part=part{$i}a on Interface eno1:$interface from cur=$cur to endcur=$endcur ..." -e curl "$url" --retry 3 -L --interface eno1:$interface --range $cur-$endcur -g  -o ~/MultipartDownloads/"$name"/part{$i}a #&& echo "Successfully downloaded part=$i from cur=$cur to endcur=$endcur" && wait
			else
				konsole --title "Part=part{$i}a on Interface eno1:$interface from cur=$cur to endcur=$endcur ..." -e curl "$url" --retry 3 -L --interface eno1:$interface --range $cur-$endcur -o ~/MultipartDownloads/"$name"/part{$i}a #&& echo "Successfully downloaded part=$i from cur=$cur to endcur=$endcur" && wait
			fi
		echo " Success." # Successfully launched part={$i}a from cur=$cur to endcur=$endcur"
		cur=`expr $endcur + 1`
		interface=`expr $interface + 1`
		else
			echo "Apparently the filesize on disk is greater than the file size the part should be. Something gg. Exiting Script.. Check It Out."
			exit 1
		fi
	else
		echo -n "Launching part=part$i on interface eno1:$interface from cur=$cur to endcur=$endcur ..."
		if [ $globbingoff -eq 1 ]
		then
			#echo "trying with globbing off."
			 konsole --title "Part=part{$i}a on Interface eno1:$interface from cur=$cur to endcur=$endcur ..." -e curl  "$url" --retry 3 -L --interface eno1:$interface --range $cur-$endcur -g  -o ~/MultipartDownloads/"$name"/part$i  #&& echo "Successfully downloaded part=$i from cur=$cur to endcur=$endcur" && wait
		else
			  konsole --title "Part=part{$i}a on interface eno1:$interface from cur=$cur to endcur=$endcur ..." -e curl  "$url" --retry 3 -L --interface eno1:$interface --range $cur-$endcur  -o ~/MultipartDownloads/"$name"/part$i  #&& echo "Successfully downloaded part=$i from cur=$cur to endcur=$endcur" && wait
		fi
		echo " Success. " #Successfully launched part=$i from cur=$cur to endcur=$endcur"
		cur=`expr $endcur + 1`
		interface=`expr $interface + 1`

	fi

		#this looping section can be disabled if the intended behaviour is to just launch one part on each available interface, instead of launching every part of the download on that range.
		#loop interfaces when ending alias limit crossed:
		if [[ $interface -gt $endingalias ]]
		then
			if [ $i -lt $parts ] #only show this message if there are actually parts remaining to launch.
			then
				echo "Reached custom or default alias limit ( eno1:$endingalias ). Setting current interface number back to eno1:$startingalias to loop back."
			fi
			interface=$startingalias
		fi

done

#-------------------------------------------------------------------------------------------

i=`expr $i - 1`

if [[ $i -eq $parts ]] 
then
	echo "All $parts parts of the file have been launched."
	
	wait

	read -p "If all the processes have terminated. Would you like to run the concatenation script? ( 1 or 2 ): " concatres
	clear	
	if [ $concatres -eq 1 ]
	then
		echo "Concatenating the downloaded files."
	bash concat.sh "$name" "$name"
	else
		echo "Concatenation Li8. What should I do now?"
	fi

	read -p "Would you like to delete the temporary part files of the download? ( 1 or 2 ): " tempdelres
	clear	
	if [ $tempdelres -eq 1 ]
	then
		echo "Deleting the temporary part files."
		rm ~/MultipartDownloads/"$name"/part*
		rm ~/MultipartDownloads/"$name"/*.txt
	else
		echo "Not my problem. Waste space on your Drive if you want."
	fi

else
	echo "Parts of the file till part $i have been launched (due to restrictions on number of aliases to use). No all-parts-done-verification-or-concatenation will be performed."
fi
	
#-------------------------------------------------------------------------------------------

echo "Okay! Whatever Shit you wanted done is done. Downloader says Bye!"
