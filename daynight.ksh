#!/usr/bin/ksh
PATH=/usr/local/bin:/usr/bin:/bin
CURL_BIN_URL="https://curl.haxx.se/docs/install.html"
CURL_QUERY_URL="https://www.almanac.com/astronomy/rise/zipcode"

#Check if cURL is installed
if [ ! -x /usr/bin/local/bin/curl ] && [ ! -x /usr/bin/curl ] && [ ! -x /bin/curl ]; then
  install_str="You can install it with "

  if [ -x /usr/bin/apt-get ]; then #debian variants
    install_str="${install_str}sudo apt-get install curl or apt-get install (if root)"
  elif [ -x /usr/bin/yum ]; then #redhat variants
    install_str="${install_str}sudo yum install curl or yum install curl (if root)"
  elif [ -x /usr/bin/pacman ]; then #archlinux
    install_str="${install_str}pacman -S curl"
  elif [ -x /usr/bin/zypper ] ; then #suse
    install_str="${install_str}zypper in curl"
  else
    install_str="You can try building and installing cURL using the instructions here : ${CURL_BIN_URL}"
  fi
  
  print "This script needs the cURL binary to run.\n"
  print "${install_str}"
  
  exit 1
fi

function prompt_for_zip 
{
  print "Please enter the 5 digit zipcode of where you'd like to know if its day or night :\n"
  read zipcode

  if [[ $zipcode != +([0-9]) ]]; then
    print "\nThe zipcode you input needs to be numeric.\n"
    prompt_for_zip  
  elif [[ ${#zipcode} != 5 ]]; then
    print "\nThe zipcode you input needs to be exactly 5 digits long.\n"
    prompt_for_zip   
  fi
  
  return 0
}

prompt_for_zip

function is_day_time
{
  typeset local_date="$(date +%Y-%m-%d)"
  typeset url="${CURL_QUERY_URL}/${zipcode}/${local_date}"
  
  #get the zipcode's locality for display, if the result is empty, stop
  zip_locality="$(curl --silent "${url}" | grep locality)"
  
  if [ -z $zip_locality ]; then
    return 2
  fi
  
  zip_locality=${zip_locality:38}
  str_len=$((${#zip_locality}-4))
  zip_locality=${zip_locality:0:$str_len}
  
  #get the timezone for the zipcode in question, if its not recognized, stop
  typeset curl_output="$(curl --silent "${url}" | grep rise_timezone | sed -n 's/.*<p class=\"rise_timezone\">\([^<]*\)<\/p>.*/\1/p')"
  
  typeset utc_offset=0
  
  #DST support TODO?
  case $curl_output in
    *Eastern* )
      utc_offset=4 ;;
    *Central* )
      utc_offset=5 ;;
    *Mountain* )
      utc_offset=6 ;;
    *Pacific* )
      utc_offset=7 ;;      
    * )
      return 3 ;;
  esac

  export TZ=UTC+${utc_offset}
  
  typeset zip_date="$(date +%Y-%m-%d)"
  typeset hour=$(date +%H)
  typeset min=$(date +%m)  
  
  url="${CURL_QUERY_URL}/${zipcode}/${zip_date}"
  curl_output="$(curl --silent "${url}" | grep rise_results | cut -d\< -f42-44)"

  typeset sunrise="$(print ${curl_output} | cut -d\  -f2)"
  typeset sunset="$(print ${curl_output} | cut -d\  -f4)"

  typeset srh=$(print ${sunrise} | cut -d: -f1)            ; 
  typeset srm=$(print ${sunrise} | cut -d: -f2)
  
  typeset ssh=$(( $(print ${sunset} | cut -d: -f1) + 12 ))
  typeset ssm=$(print ${sunset} | cut -d: -f2)
  
  #now let's test the current hour/minute against the sunrise/sunset times
  print "\nTesting current time in ${zip_locality} : ${hour}:${min} against sunrise ${srh}:${srm} and sunset ${ssh}:${ssm}..."

  if [ $hour -eq $srh -a $min -ge $srm ] ; then
    return 0	# special case of sunrise hour
  fi
  
  if [ $hour -gt $srh -a $hour -lt $ssh ] ; then
    return 0	# easy: after sunrise, before sunset
  fi
  
  if [ $hour -eq $ssh -a $min -le $ssm ] ; then
    return 0    # special case: sunset hour
  fi

  return 1
}

if is_day_time ; then
  print "\nIt's daytime in ${zip_locality}\n"
else
  if [ $? -eq 2 ]; then
    print "\nNo results were returned for the zipcode : ${zipcode}\n"
  elif [ $? -eq 3 ]; then
    print "\nUnable to determine the timezone for the zipcode : ${zipcode}\n"
  else 
    print "\nIt's nighttime in ${zip_locality}\n"
  fi
fi

exit 0
