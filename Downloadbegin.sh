clear
read -p "Welcome to TheAbusiveCunt Tools. Do you want to create IP's for Downloads or Browse the net? Press 1 for IP Binding, Downloading or Concatenation , Press 2 for browsing mode, Press 3 to get abused :\ -" initcheck
flag=0
onemoreflag=0
if [ $initcheck -eq 1 ]
then
	echo "Get ready for some Evil downloading :O"
elif [ $initcheck -eq 2 ]
then
	echo "Browsing mode active. Let's get logged in........"
	while read a b;
	do 
	 	curl -s -k -d "mode=191&userName=$a&password=$b&btnSubmit=Login" https://10.1.0.10:8090/httpclient.html > dresult.txt
         	time=`date`
         	if grep -q 'logged in' "dresult.txt"; 
         	then           		
		echo "Go do your thing. You are logged in"	 	
		printf "Logged into eno1 using ID $a at $time \n" >> loginbrowse.txt;
	 	((flag=1))
         	exit 0
         	else
         	printf "Login failed for eno1 using ID $a at $time \n" >> loginbrowse.txt;
	 	fi
		if [ $flag -eq 0 ]
		then   
			echo "Hmmmmm. Either ID's over or something else gg. Sorry try later :("
			exit 0
		fi
	done < passfinal.txt
else
	echo "BC MKL Kuch karna nahi to script kyon kholi Chut :( "
	exit 0
fi
echo "Hmmmm. Let's get going..........."
read -p "If you have already created IP's and logged in, press 2 to Skip to Downloading or Concatenation. 1 to Continue" ipcheck
if [ $ipcheck -eq 1 ]
then
	ipcount=0
	read -p "First of all How many IP's would you like to create? Limit to about 40:	" ipcount
	echo "Alright then. Creating $ipcount IP's....."
	i=0
	ipstart=220
	ipaddr=0
	inc=1
	for (( i = 0; i < $ipcount; i++ )) do
		ipaddr=`expr $ipstart + $i`
		sudo ifconfig eno1:$i 10.4.3.$ipaddr netmask 255.255.255.0 broadcast 10.255.255.255 up
	done
	clear
	read -p "IP's created. You wanna login and get started?		" logincheck
	if [ $logincheck -eq 1 ]
		then
			echo "Let's get started May take upto 50 seconds, So be Patient Asshole."
		else
			echo "GM BHOPDIKE TUCHIYE :( "
			exit 0
		fi
	x=0
	while read a b;
	do
		for (( i = x ; i < $ipcount; i++)) do
	        	
		         curl -k -d "mode=191&userName=$a&password=$b&btnSubmit=Login" https://10.1.0.10:8090/httpclient.html --interface eno1:$i > dresult.txt
		         time=`date`
		         if grep -q 'logged in' "dresult.txt"; 
		         then           		
				 printf "Logged into eno1:$i using ID $a at $time \n" >> loginlog.txt;
				 ((x++))
			         break
		         else
			         printf "Login failed for eno1:$i using ID $a at $time \n" >> loginlog.txt;
			 fi
	
	   	done
	done < passfinal.txt
	logincount=`grep -c 'Logged into' "loginlog.txt"`
	echo "Out of $ipcount, $logincount IP's have logged in. Go to loginlog.txt and re-login for one's not logged in"
	ip=0
	ipcheck=2
fi
if [ $ipcheck -eq 2 ]	
then
	read -p "Okay! For Downloading Press 1. But If Download Already Completed Press 2 for Concatenation:	" downcheck
	if [ $downcheck -eq 2 ]
	then
	read -p "Proceeding to Concatenation. Enter name of Folder: " folder
	bash concat.sh "$folder"
	exit 0
	fi	
	clear
	if [ $downcheck -eq 1 ]
	then
		echo "Preparing for downloading....."
	else
		echo "GADHE IP KA KYA KAREGA AGAR DOWNLOAD NAHI KAREGA"
		exit 0
	fi
	read -p "Input the URL for download: \n" url
	read -p "Enter how many IP's you want then:	" ip
	read -p "Enter folder name:		" folder
	clear
	bash multidownloader.sh "$url" "$ip" "$folder"
fi
echo "So! Happy with the Download? I don't give a Shit :D"
