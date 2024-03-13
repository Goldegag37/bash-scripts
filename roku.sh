#!/bin/bash

# this is a script to control a roku player over wifi

# feel free to use code from this script anywhere.

declare -g roku_ip

roku_ip=192.168.0.101

first_run=false

if ! curl --version >/dev/null 2>&1;then
echo "curl required for script to run, please install curl and try again."; exit
fi
find_roku_ip() {
    local ip_start
    local i

    default_start=192.168.0.0

    read -r -p "Enter the starting ip: " -i "$default_start" -e ip_start 

    ii=${ip_start##*.}
    ip_start=${ip_start%.*}

    for ((i=ii; i<256; i++)); do
        if ping -s 4 -c 1 -W 0.05 "$ip_start.$i" >/dev/null 2>&1; then
            if curl -s --connect-timeout 1 --max-time 1 "http://$ip_start.$i:8060/query/device-info" >/dev/null 2>&1; then
                echo "Roku found: $ip_start.$i"
                device_info="$(curl -s --connect-timeout 1 --max-time 1 "http://$ip_start.$i:8060/query/device-info" >/dev/null 2>&1)"
                start=${device_info#*<user-device-name>}
                start=${start%%</user-device-name>*}
                device_name=${start#*<user-device-name>}

                echo "name: $device_name"
                all_ip="$all_ip,$ip_start.$i - $device_name"
            fi
        fi
    done

    if [ -n "$all_ip" ]; then
        IFS=','
        read -ra all_ip_array <<< "$all_ip"
        echo "Select an IP address:"
        select ip in exit "${all_ip_array[@]}"; do
            if [[ -n $ip ]]; then
                ip=${ip%% *}
                ip="${ip/% - */}"
                roku_ip=$ip
                clearscreen
                break
            fi
        done
    else
    echo "No Roku devices found on your network."
    fi
}

edit_ip() {
  local new_ip
  read -r -p "Enter the Roku's IP: " new_ip
  if [ -z "$new_ip" ]; then
    echo "leaving roku_ip as \"$roku_ip\" "
    return 1
  fi
  if ! [[ $new_ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
    clearscreen
    echo "Invalid IP address format."
    edit_ip
    return
  fi
  if ! ping -c 1 -W 1 "$new_ip" > /dev/null 2>&1; then
    clearscreen
    echo "Device not found at \"$new_ip\"."
    edit_ip
    return 1
  fi
  sed -i "s/^roku_ip=.*/roku_ip=$new_ip/" "$0"
  roku_ip=$new_ip
  clearscreen
  echo "Roku IP changed to \"$new_ip\"."
}

press() {
    if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
        echo "Error: key not specified."
        exit 1
    fi

    if [[ "$1" == *" "* ]]; then
        for word in $1; do
            curl -d '' "http://$roku_ip:8060/keypress/$word"
        done
    else
        if [ -z "$2" ]; then
            curl -d '' "http://$roku_ip:8060/keypress/$1"
        else

        for ((i=1; i<=$2; i++)); do
            curl -d '' "http://$roku_ip:8060/keypress/$1"
        done
    fi
    fi
}

launch() {
    if [ "$#" -ne 1 ]; then
        echo "Error: channel number not specified"
        exit 1
    fi
    curl -d "" "http://$roku_ip:8060/launch/$1"
}

# this can type in all textboxes ive tried (if you find one it doesnt work with report an issue on github)
type() {
    # if you cant type "~" then change it here.
    backspace='~'

    if [ "$#" -ne 1 ]; then
        echo
        echo "NOTE: a tilde ($backspace) can be used as backspace." | sed -E 's/\(([^)]+)\)/\x1b[31m(\1)\x1b[0m/g'
        read -r -p "What to type: " to_type
    else
        to_type="$1"
    fi

    for ((i=0; i<${#to_type}; i++)); do
        letter="${to_type:$i:1}"
        case $letter in
            "$backspace") curl -d '' http://"$roku_ip":8060/keypress/Backspace ;;
            * ) curl -d "" http://"$roku_ip":8060/keypress/"$(printf '%02x' "'$letter")" ;;
        esac
    done
}



macro() {
    echo
    case $1  in
        '') echo "Error: no macro id provided.";;

        'curiousGeorge') press "Home"; sleep 3; press "Up" 2; press "Select"; 
              type "Curious George"; press "Right" 5; sleep 1.2; 
              press "Right Select" ; sleep 1; press "Select";;

        'bluey') launch 837; sleep 4; press "Left Up Right"; 
        type "Bluey Official Channel"; sleep 1.5; press "Down" 5; press "Right Select"; sleep 1.7; press Down 3; press Select ;;

        'nextYtVid') press "Down Down Select" ;;

        'test') 
                device_info="$(curl -s --connect-timeout 1 --max-time 1 "http://$roku_ip:8060/query/device-info" >/dev/null 2>&1)"; echo "$device_info";;

        *) echo "Error: invalid macro id."
    esac
    sleep 2
}

roku_input() {
    echo -n " - "

    read -rsn1 key
    if [[ $key == $'\x1b' ]]; then
        read -rsn2 key
        case $key in

            '[A') echo -n "Up"; press "Up" ;;
            '[B') echo -n "Down"; press "Down" ;;
            '[C') echo -n "Right"; press "Right";;
            '[D') echo -n "Left"; press Left;;
            *) echo "?"
        esac
    else
        case $key in
            'h') echo "$help_msg" ;;
            'H') echo -n "Home";         press Home; sleep 2 ;;
            $'\x7f') echo -n "Back";     press Back ;;
            'r') echo -n "Rewind";       press Rewind ;;
            'f') echo -n "Fast Forward"; press FastForward ;;
            'i') echo -n "Info";         press Info ;;
            'p') echo -n "Play/Pause";   press Play ;;
            '' ) echo -n "OK";           press Select ;;
            'R') echo -n "Replay";       press InstantReplay ;;
            'E') echo -n "Enter";        press Enter ;;
            't') type ;;
            'c') clearscreen ;;
            'e') edit_ip ;;
            'q') clear; exit ;;

            'C') find_roku_ip ;;

            # only supported devices/remotes
            'F') echo -n "Find Remote"; press FindRemote ;;

            's') press Search ;;
        #
            '1') echo -n "Launch Hulu"; launch 2285 ;;
            '2') echo -n "Launch YouTube"; launch 837 ;;
            '3') echo -n "Launch name"; macro ;;
            '4') echo -n "Launch name"; macro ;;
            '5') echo -n "Next"; macro nextYtVid ;;
            '6') echo -n "Launch name"; macro id ;;
            '7') echo -n "Launch name"; macro test ;;
            '8') echo -n "Launch bluey"; macro bl ;;
            '9') echo -n "Play Curious George"; macro curiousGeorge;;
            '0') echo -n "Launch name"; launch id ;;
            
            # Roku tv
            'P') echo -n "Powering off..."; press PowerOff; clear; echo "Powering Off..." ; exit;;
            '^') echo -n "Open Tuner"; press InputTuner ;;
            '!') echo -n "Open HDMI1"; press InputHDMI1 ;;
            '@') echo -n "Open HDMI2"; press InputHDMI2 ;;
            '#') echo -n "Open HDMI3"; press InputHDMI3 ;;
            '$') echo -n "Open HDMI4"; press InputHDMI4 ;;
            '%') echo -n "Open AV1"  ; press InputAV1 ;;
            
            '>') echo -n "Volume up"  ; curl -d '{"key": "volumeup"}' http://"$roku_ip":8060/keypress/VolumeUp ;;
            '<') echo -n "Volume down"; curl -d '{"key": "volumedown"}' http://"$roku_ip":8060/keypress/VolumeDown ;;
            'm') echo -n "Volume mute"; curl -d '{"key": "volumemute"}' http://"$roku_ip":8060/keypress/VolumeMute ;;

            '+') read -r -p "Do what: "; $REPLY ;;
            '*') bash "$0" "$@" ; exit ;;
            *) echo -n "?" ;;
        esac
    fi
}



if [ $first_run = true ]; then
    select option in  "Search for Roku" "Enter IP Address"; do
        case $option in
            "Search for Roku") echo "searching for roku ip address..."; find_roku_ip;;
            "Enter IP Address") edit_ip;;
            "Quit")  exit ;;
        esac

        sed -i 's/first_run=false/first_run=false/g' "$0"
    done

fi



help_msg=$(printf "Navigation: (H)ome | (backspace)-back | (Enter)-OK | arrow keys (↑)-Up (↓)-Down (←)-Left (→)-Right\nOther: (h)elp | (q)uit | (r)ewind | (f)ast forward | (I)nfo | (p)ause/play | (t)ext | (e)dit ip address | (c)lear screen\nChannels: (1)-Hulu | (2)-Youtube | Case Sensitive" | sed -E 's/\(([^)]+)\)/\x1b[31m(\1)\x1b[0m/g')
clearscreen() {
clear
echo "$help_msg"
echo "$roku_ip"
}

clearscreen
while true; do
    roku_input "$@"
done
