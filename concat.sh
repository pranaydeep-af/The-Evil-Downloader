echo "Welcome to the Concatenator. I am a Jerk too."
name=$1
folder=Releases
read size < ~/MultipartDownloads/"$name"/size.txt
read parts < ~/MultipartDownloads/"$name"/parts.txt
read -p "The Download $name was downloaded in $parts parts and the complete size was $size bytes. Is that Correct? 1 or 2:	" verify
if [ $verify -eq 1 ]
then
	echo "Fine. Let's Continue."
else
	echo "Fuck You Then. Go try something else. Can't Help You"
	exit 0
fi
read -p "Would you like to Put the Output in the Default New Releases Folder? 1 or 2" addr
if [ $addr -eq 1 ]
then
	echo "Proceeding......"
else
	read -p "Where the hell do you want it then?" output
fi
i=1
for (( i=1; i<=parts; i++ ))
do
	cat ~/MultipartDownloads/"$name"/part$i >> ~/../../media/artemisfowl/Database/"$folder"/"$name"
done
ls -lah ~/../../media/artemisfowl/Database/"$folder"/"$name" > ~/temp.txt
read a b c d sizeoffile f < ~/temp.txt
echo "Concatenation completed with file size $sizeoffile"



	

