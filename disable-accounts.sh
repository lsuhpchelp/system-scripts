# Systematically Disalbe User Accounts
# Written by Wei Feinstein 7/2016
# Version 1.1

#!/bin/sh

admid=$USER
timestamp=`date +%F`

exclude_hpc=(train gold nandakum ftsai jembrown moreno walkertr sjpark autoaccounts directory_test dquery ldap02 ldap03 ldapReplicants loadleveler redminequery xymonquery)
exclude_loni=(train gold ramu michal cice cortez csumma blevins  autoaccounts jabber l1f1u02 l6l1u01_ldap l6l1u02_ldap ldap02 ldap03 ldap04 ldapReplicants loadleveler lonimail cysuser lonircs otrsuser)

#********************beginning of functions***************************
Usage(){
       echo " "
       echo "** usage: $0 [params] **"
       echo " "
       echo "   params:"
       echo "  -u  uid"
       echo "  -g  [hpc/loni/xsede/teragrid]"
       echo "  -o  [disable/reenable]"	
       echo "  -h  - get this help message"
       echo " "
}
Generate_ldif_loni_dis() {

	passwd="{CRYPT}$(Genpasswd)"
	shell="/bin/false"

	if [ -z "$des" ]; then
		ldif=$(echo dn: uid=$uid,ou=People,ou=$institute,ou=Users,dc=loni,dc=org)
		ldif=$(echo $ldif"\n"changetype: modify)
		ldif=$(echo $ldif"\n"add: description)
		#no leading/trailing spaces in "description" to avoid encription	
		ldif=$(echo $ldif"\n"description:$reason $admid `date +%F`"\n")
	else
		ldif=$(echo dn: uid=$uid,ou=People,ou=$institute,ou=Users,dc=loni,dc=org)
		ldif=$(echo $ldif"\n"changetype: modify)
		ldif=$(echo $ldif"\n"replace: description)
		ldif=$(echo $ldif"\n"description:$des";"$reason $admid `date +%F`"\n")
	fi
	ldif=$(echo $ldif"\n"dn: uid=$uid,ou=People,ou=$institute,ou=Users,dc=loni,dc=org)
        ldif=$(echo $ldif"\n"changetype: modify)
        ldif=$(echo $ldif"\n"replace: userPassword)
        ldif=$(echo $ldif"\n"userPassword:$passwd"\n")
	
	ldif=$(echo $ldif"\n"dn: uid=$uid,ou=People,ou=$institute,ou=Users,dc=loni,dc=org)
        ldif=$(echo $ldif"\n"changetype: modify)
        ldif=$(echo $ldif"\n"replace: loginShell)
        ldif=$(echo $ldif"\n"loginShell:$shell"\n")

	ldif=$(echo $ldif"\n"dn: uid=$uid,ou=People,ou=$institute,ou=Users,dc=loni,dc=org)
	ldif=$(echo $ldif"\n"changetype: moddn)
	ldif=$(echo $ldif"\n"newrdn: uid=$uid)
	ldif=$(echo $ldif"\n"deleteoldrdn: 1)
	ldif=$(echo $ldif"\n"newsuperior: ou=People,ou=$institute,ou=Users,ou=DisabledAccounts,dc=loni,dc=org"\n")

}	
Generate_ldif_loni_react() {

	passwd="{CRYPT}$(Genpasswd)"
	shell="/bin/bash"

        if [ -z "$des" ]; then
                ldif=$(echo dn: uid=$uid,ou=People,ou=$institute,ou=Users,ou=DisabledAccounts,dc=loni,dc=org)
                ldif=$(echo $ldif"\n"changetype: modify)
                ldif=$(echo $ldif"\n"add: description)
                #no leading/trailing spaces in text fields to avoid encription        
                ldif=$(echo $ldif"\n"description:$reason $admid `date +%F`"\n")
        else
                ldif=$(echo dn: uid=$uid,ou=People,ou=$institute,ou=Users,ou=DisabledAccounts,dc=loni,dc=org)
                ldif=$(echo $ldif"\n"changetype: modify)
                ldif=$(echo $ldif"\n"replace: description)
                ldif=$(echo $ldif"\n"description:$des";"$reason $admid `date +%F`"\n")
        fi
        ldif=$(echo $ldif"\n"dn: uid=$uid,ou=People,ou=$institute,ou=Users,ou=DisabledAccounts,dc=loni,dc=org)
        ldif=$(echo $ldif"\n"changetype: modify)
        ldif=$(echo $ldif"\n"replace: userPassword)
        ldif=$(echo $ldif"\n"userPassword:$passwd "\n")
        
	ldif=$(echo $ldif"\n"dn: uid=$uid,ou=People,ou=$institute,ou=Users,ou=DisabledAccounts,dc=loni,dc=org)
        ldif=$(echo $ldif"\n"changetype: modify)
        ldif=$(echo $ldif"\n"replace: loginShell)
        ldif=$(echo $ldif"\n"loginShell:$shell"\n")

        ldif=$(echo $ldif"\n"dn: uid=$uid,ou=People,ou=$institute,ou=Users,ou=DisabledAccounts,dc=loni,dc=org)
        ldif=$(echo $ldif"\n"changetype: moddn)
        ldif=$(echo $ldif"\n"newrdn: uid=$uid)
        ldif=$(echo $ldif"\n"deleteoldrdn: 1)
        ldif=$(echo $ldif"\n"newsuperior: ou=People,ou=$institute,ou=Users,dc=loni,dc=org"\n")
#echo -e $ldif
}

Generate_ldif_hpc_dis() {
	
	passwd="{CRYPT}$(Genpasswd)"
	shell="/bin/false"

	if [ $institute == 'xsede' ]; then
		user=xsede
	else
		user=Users
			fi

	if [ -z "$des" ]; then
		ldif=$(echo dn: uid=$uid,ou=$user,ou=People,dc=hpc,dc=lsu,dc=edu)
		ldif=$(echo $ldif"\n"changetype: modify)
		ldif=$(echo $ldif"\n"add: description)
		ldif=$(echo $ldif"\n"description:$reason $admid `date +%F`"\n")
	else
		ldif=$(echo dn: uid=$uid,ou=$user,ou=People,dc=hpc,dc=lsu,dc=edu)
		ldif=$(echo $ldif"\n"changetype: modify)
		ldif=$(echo $ldif"\n"replace: description)
		ldif=$(echo $ldif"\n"description:$des";"$reason $admid `date +%F`"\n")
	fi	
	ldif=$(echo $ldif"\n"dn: uid=$uid,ou=$user,ou=People,dc=hpc,dc=lsu,dc=edu)
        ldif=$(echo $ldif"\n"changetype: modify)
        ldif=$(echo $ldif"\n"replace: userPassword)
        ldif=$(echo $ldif"\n"userPassword:$passwd"\n")
	
	ldif=$(echo $ldif"\n"dn: uid=$uid,ou=$user,ou=People,dc=hpc,dc=lsu,dc=edu)
        ldif=$(echo $ldif"\n"changetype: modify)
        ldif=$(echo $ldif"\n"replace: loginShell)
        ldif=$(echo $ldif"\n"loginShell:$shell"\n")

	ldif=$(echo $ldif"\n"dn: uid=$uid,ou=$user,ou=People,dc=hpc,dc=lsu,dc=edu)
	ldif=$(echo $ldif"\n"changetype: moddn)
	ldif=$(echo $ldif"\n"newrdn: uid=$uid)
	ldif=$(echo $ldif"\n"deleteoldrdn: 1)
	ldif=$(echo $ldif"\n"newsuperior: ou=$user,ou=People,ou=DisabledAccounts,dc=hpc,dc=lsu,dc=edu"\n")
#echo -e $ldif
}	
Generate_ldif_hpc_react() {
        passwd="{CRYPT}$(Genpasswd)"
	shell="/bin/bash"

	if [ $institute == 'xsede' ]; then
                user=xsede
	else 
		user=Users
        fi

        if [ -z "$des" ]; then
	        ldif=$(echo dn: uid=$uid,ou=$user,ou=People,ou=DisabledAccounts,dc=hpc,dc=lsu,dc=edu)
                ldif=$(echo $ldif"\n"changetype: modify)
                ldif=$(echo $ldif"\n"add: description)
                ldif=$(echo $ldif"\n"description:$reason $admid `date +%F`"\n")
        else
                ldif=$(echo dn: uid=$uid,ou=$user,ou=People,ou=DisabledAccounts,dc=hpc,dc=lsu,dc=edu)
                ldif=$(echo $ldif"\n"changetype: modify)
                ldif=$(echo $ldif"\n"replace: description)
                ldif=$(echo $ldif"\n"description:$des";"$reason $admid `date +%F`"\n")
        fi
        ldif=$(echo $ldif"\n"dn: uid=$uid,ou=$user,ou=People,ou=DisabledAccounts,dc=hpc,dc=lsu,dc=edu)
        ldif=$(echo $ldif"\n"changetype: modify)
        ldif=$(echo $ldif"\n"replace: userPassword)
        ldif=$(echo $ldif"\n"userPassword:$passwd"\n")
        
	ldif=$(echo $ldif"\n"dn: uid=$uid,ou=$user,ou=People,ou=DisabledAccounts,dc=hpc,dc=lsu,dc=edu)
        ldif=$(echo $ldif"\n"changetype: modify)
        ldif=$(echo $ldif"\n"replace: loginShell)
        ldif=$(echo $ldif"\n"loginShell:$shell"\n")
        
	ldif=$(echo $ldif"\n"dn: uid=$uid,ou=$user,ou=People,ou=DisabledAccounts,dc=hpc,dc=lsu,dc=edu)
        ldif=$(echo $ldif"\n"changetype: moddn)
        ldif=$(echo $ldif"\n"newrdn: uid=$uid)
        ldif=$(echo $ldif"\n"deleteoldrdn: 1)
        ldif=$(echo $ldif"\n"newsuperior: ou=$user,ou=People,dc=hpc,dc=lsu,dc=edu"\n")
#echo -e $ldif
}

Deactivate_accounts(){

	if [[ $category == "loni" && $action == "disable" ]]; then
		Generate_ldap_ldif=Generate_ldif_loni_dis
	elif [[ $category == "loni" && $action == "reenable" ]]; then
		Generate_ldap_ldif=Generate_ldif_loni_react
	elif [[ $category == "hpc" && $action == "reenable" ]]; then
                Generate_ldap_ldif=Generate_ldif_hpc_react
	elif [[ $category == "hpc" && $action == "disable" ]]; then
		Generate_ldap_ldif=Generate_ldif_hpc_dis 
	fi
 	#get institute 
        if [ $category == "loni" ]; then
                institute=$(echo "$results" |awk -v FS="People,ou=" '{print $2}'|awk -v FS="," '{print $1}')
        elif [ $category == "hpc" ]; then
		institute=$(echo "$results" |awk -v FS=",ou=" '{print $2}')
	fi
	if [ $institute == "xsede" ]; then
		echo $uid is a XSESED user, Abort! $'\n'
		exit 1
	fi
	$Generate_ldap_ldif 
}
Genpasswd(){
	passwd=$(openssl rand -base64 32|md5sum |cut -c1-31)
	epasswd=$(echo "$passwd" | openssl passwd -1 -stdin)
	eepasswd=$(echo "$epasswd" | openssl passwd -1 -stdin)
}
Check(){
       
        #exlude predefined user accounts
        i=0
        exclude_list=$(echo ${exclude_arr[@]})
        if [[ `echo $exclude_list |grep $uid` && "$action" == "disable" ]]; then
		echo $uid is in the allocation committee, can not be $action"d" $'\n'
		exit 1
	fi
	
	index=3
	results="ldap_bind"
#    	while [[ `echo "$results" |grep "Invalid credentials"` &&  $index >0 ]];
    	while [[ `echo "$results" |grep "ldap_bind"` &&  $index >0 ]];
    	do
        	echo Type password to access LDAP, followed by return
        if [[ $category == "hpc" ]]; then
                results=$(ldapsearch -LLL -ZZ -x -h ldap01.hpc.lsu.edu  -D uid=$admid,ou=Admins,ou=People,dc=hpc,dc=lsu,dc=edu -W -b dc=hpc,dc=lsu,dc=edu "uid=$uid"  2>&1)
       	else
                results=$(ldapsearch -LLL -ZZ -x -h ldap01.sys.loni.org  -D uid=$admid,ou=People,ou=Admins,dc=loni,dc=org -W -b dc=loni,dc=org "uid=$uid" 2>&1)
        fi

        index=$(echo $index-1|bc)
    	done
	if [[ `echo "$results" |grep "ldap_bind"` ]]; then
                echo Passwd failed 3 times!$'\n'
                exit 1
	elif [[ ! `echo "$results" |grep "dn"` ]]; then 
		echo user $uid does not exist, abort! $'\n' 
		exit 1
   	fi
	#check if admin 
	if [[ `echo "$results" |grep "Admins"` && "$action" == "disable" ]]; then
                echo $uid belongs to Admins group, can not be disabled$'\n'
                exit 1
        fi
   	if [[ `echo "$results" |grep "description:"` ]]; then
		des=$(echo "$results" | awk -v c=0 '{if($1=="description:") c=1; else if (c>0 && substr($0, 0, 1)==" ") c++; else c=0; if (c>0) print $0}' |tr "\n" "_" | sed -e 's/\_\ //g; s/\_//g'| awk -v FS="description:" '{print $2}')
		des=$(echo $des) #  |xargs -0)   #trim white space
        else   des=''
        fi
	if [[ `echo "$results" |grep "\b$uid\b"` ]]; then
        	if [[ `echo "$results" |grep "DisabledAccounts"`&& $action == "disable" ]]; then
                	echo $'\n'$uid is already disabled in $category LDAP, Abort! $'\n'
                	exit 1
        	elif [[ ! `echo "$results" |grep "DisabledAccounts"`&& $action == "reenable" ]]; then
                	echo $'\n'$uid is already alive in $category LDAP, Abort! $'\n'
               	 	exit 1
        	else    
                	echo $'\n'$uid from $type will be $action"d" from $category LDAP. $'\n'
        	fi 
   	fi
	
}

#********************end of functions***************************

if [[ ! "$#" || "$1" == "-h" ]]; then 
	Usage
	exit 1
fi

if [[ "$#" != 6 ]]; then
        echo Not enough parameters 
        Usage
        exit 1
fi

while (( "$#" )); 
do
        case "$1" in
        -h)
                Usage
                exit
                ;;
        -u)
                uid=$2
                ;;
        -g)
                type=$2
                ;;
	-o)	
		action=$2
		;;
        esac
        shift 2
done

declare -a typearr=(hpc loni teragrid xsede)
element=$(echo  ${typearr[@]}|grep  "\b$type\b")

if [ -z  "$element" ]; then
	echo "Select a group from [loni|hpc|xsede|teragrid] "
	Usage 
	exit 1
fi
if [[ "$action" != "disable" && "$action" != "reenable" ]]; then 
	echo "Select an action from [ disable|reenable ] " 
        Usage
        exit 1
fi
#not on XSESE user yet
if [ "$type" == "xsede" ]; then
	echo  $uid is a XSESED user, Abort! $'\n'
                exit 1
fi

if [[ "$type" == "teragrid" || $type == "loni" ]]; then 
	category=loni
	exclude_arr=("${exclude_loni[@]}")
elif [[ "$type" == "xsede" || $type == "hpc" ]]; then 
	category=hpc
	exclude_arr=("${exclude_hpc[@]}")
fi

# check user info 
Check 

index=3
reason=""
#blank reason
while [[ $reason != *[!\ ]*  &&  $index >0 ]];
do
	read -p "Please provide reason to $action the account: "  reason
	
	index=$(echo $index-1|bc)
done
if [ ! $index ]; then
	echo No input for reason to $action the account. abort!
	exit 1
else 
	reason=$(echo $reason)
fi


Deactivate_accounts 

# modify LDAP
log="ldap_bind"
index=5
while [[ `echo $log |grep "ldap_bind"` &&  $index >0 ]];
    do
        echo Enter LDAP passwd to commit, followed by return
        if [[ $category == "hpc" ]]; then
		log=$(echo -e $ldif | ldapmodify -ZZ -h ldap01.hpc.lsu.edu  -W -x -D uid=$admid,ou=Admins,ou=People,dc=hpc,dc=lsu,dc=edu 2>&1)
        else
		log=$(echo -e $ldif | ldapmodify -ZZ -h ldap01.sys.loni.org -W -x -D uid=$admid,ou=People,ou=Admins,dc=loni,dc=org 2>&1)
        fi
        index=$(echo $index-1|bc)
    done
#echo $log

if [[ `echo $log |grep "ldap_bind"` ]]; then
	echo Passwd failed 5 times! quit for now!$'\n'
	exit 1
fi

#check if sucessful                   
declare -a errorarr=("No such object" "attribute or value exists" "invalid attribute syntax" "no such attribute" "insufficient access rights", "wrong attributeType")
for error in "${errorarr[@]}"
do
        if [[ `echo $log|grep "\b$error\b"` ]];then
                echo Failed duo to "$error". Please investigate! $'\n'
                exit 1
        fi
done
echo Successfully Done! $'\n'


