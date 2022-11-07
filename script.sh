#!/bin/bash

BROWSER=chromium
DOTOOL=xdotool

if ! command -v apt-get >/dev/null 2>/dev/null; then
	echo "Currently, this script can only be run on Debian or debian-like-systems like Ubuntu"
	exit 1
fi

if ! command -v chromium >/dev/null 2>/dev/null; then
	echo "chromium not installed. Trying to install..."
	if uname -a | grep Ubuntu; then
		BROWSER=chromium-browser
	fi

	sudo apt-get install $BROWSER
fi

if [[ "$XDG_SESSION_TYPE" == "x11" ]]; then
	if ! command -v xdotool >/dev/null 2>/dev/null; then
		echo "xdotool not installed. Trying to install..."
		sudo apt-get install xdotool
	fi
	DOTOOL=xdotool
else
	if ! command -v ydotool >/dev/null 2>/dev/null; then
		echo "ydotool not installed. Trying to install..."
		sudo apt-get install ydotool
	fi

	echo "!!! ydotool needs sudo rights to run. Please enter your sudo password !!!"
	sudo true
	DOTOOL="sudo ydotool"
fi

function echoerr() {
	echo "$@" 1>&2
}

function red_text {
        echoerr -e "\e[31m$1\e[0m"
}

set -e

function calltracer () {
        echo 'Last file/last line:'
        caller
}
trap 'calltracer' ERR

function help () {
        echo "Possible options:"
        echo "  --username=USERNAME				Shibboleth username"
	echo "  --password=PASSWORD				Shibboleth password (when not entered, it will ask you via zenity)"
	echo "  --url=STARTURL					Starturl"
	echo "  --home_network_name=HOME_NETWORK_NAME		Name of your network at home"
        echo "  --force_home_office				Force Home Office"
        echo "  --force_auf_arbeit				Force auf Arbeit"
        echo "  --help					this help"
        echo "  --debug					Enables debug mode (set -x)"
        exit $1
}

export USERNAME
PASSWORD=""
ABTEILUNG=""
export force_home_office
export force_auf_arbeit
URL=""
HOME_NETWORK_NAME=""

for i in $@; do
        case $i in
                --home_network_name=*)
                        HOME_NETWORK_NAME="${i#*=}"
                        shift
                        ;;
                --abteilung=*)
                        ABTEILUNG="${i#*=}"
                        shift
                        ;;
                --username=*)
                        USERNAME="${i#*=}"
                        shift
                        ;;
                --password=*)
                        PASSWORD="${i#*=}"
                        shift
                        ;;
                --force_home_office)
                        force_home_office=1
                        shift
                        ;;
                --force_auf_arbeit)
                        force_auf_arbeit=1
                        shift
                        ;;
		--url=*)
			URL="${i#*=}"
			shift
			;;
                -h|--help)
                        help 0
                        ;;
                --debug)
                        set -x
                        ;;
                *)
                        red_text "Unknown parameter $i" >&2
                        help 1
                        ;;
        esac
done

if [[ ! -z $force_home_office ]]; then
	if [[ ! -z $force_auf_arbeit ]]; then
		if [[ -z "$HOME_NETWORK_NAME" ]]; then
			red_text "Parameter --home_network_name cannot be empty"
			help 1
		fi
	fi
fi

if [[ -z "$URL" ]]; then
	red_text "Parameter --url cannot be empty"
	help 1
fi

if [[ -z "$USERNAME" ]]; then
	red_text "Parameter --username cannot be empty"
	help 1
fi

if [[ -z "$ABTEILUNG" ]]; then
	red_text "Parameter --abteilung cannot be empty"
	help 1
fi





HOME_OFFICE=0

if [[ "$force_home_office" -eq "1" ]]; then
	if [[ "$force_auf_arbeit" -eq "1" ]]; then
		red_text "Cannot combine --force_home_office and and --force_auf_arbeit"
		exit 2
	fi
fi

if [[ "$force_home_office" -eq "1" ]]; then
	HOME_OFFICE=1
elif [[ "$force_auf_arbeit" -eq "1" ]]; then
	HOME_OFFICE=0
else
	if ! command -v nmcli >/dev/null 2>/dev/null; then
		echo "chromium not installed. Trying to install..."
		sudo apt-get install nmcli
	fi

	if [[ "$(nmcli -t -f active,ssid dev wifi | egrep '(yes|ja):' | sed -e 's/.*://' | grep \"$HOME_NETWORK_NAME\" | wc -l)" -ge "1" ]]; then
		HOME_OFFICE=1
	fi
fi

ARBEIT_RUNTER=1
ABTEILUNG_RUNTER=1

if [[ "$HOME_OFFICE" -eq "1" ]]; then
	ARBEIT_RUNTER=3
fi

case $ABTEILUNG in
	IAK)
		ABTEILUNG_RUNTER=1
		;;
	IMC)
		ABTEILUNG_RUNTER=2
		;;
	NK)
		ABTEILUNG_RUNTER=3
		;;
	SD)
		ABTEILUNG_RUNTER=4
		;;
	OPS)
		ABTEILUNG_RUNTER=5
		;;
	SDE)
		ABTEILUNG_RUNTER=6
		;;
	VDR)
		ABTEILUNG_RUNTER=7
		;;
	*)
		echo "Unbekannte Abteilung $ABTEILUNG"
		exit 2
esac

if [[ -z "$PASSWORD" ]]; then
	if ! command -v zenity >/dev/null 2>/dev/null; then
		echo "chromium not installed. Trying to install..."
		sudo apt-get install zenity
	fi

	PASSWORD=$(zenity --password)
fi

(eval $BROWSER $URL) &
sleep 2
# schrottlogin
eval $DOTOOL type $USERNAME
eval $DOTOOL key Tab
set +x
eval $DOTOOL type $PASSWORD
unset PASSWORD
set -x
eval $DOTOOL key Return
sleep 2
# strg f drücken, nach new item suchen, suche abbrechen wo er es gefunden hat, link mit enter aufrufen
eval $DOTOOL getactivewindow key ctrl+f
eval $DOTOOL type 'new'
eval $DOTOOL key space
eval $DOTOOL type 'item'
sleep 1
eval $DOTOOL key Return
eval $DOTOOL key Escape
eval $DOTOOL key Return
sleep 3

eval $DOTOOL getactivewindow key ctrl+f
eval $DOTOOL type 'person'
sleep 1
eval $DOTOOL key Return
eval $DOTOOL key Escape
sleep 1

eval $DOTOOL key Tab
eval $DOTOOL type $USERNAME
sleep 1
eval $DOTOOL key Return
sleep 2

# telnr usw. skippen
eval $DOTOOL key Tab
sleep 0.5
eval $DOTOOL key Tab
sleep 0.5
eval $DOTOOL key Tab
sleep 0.5
eval $DOTOOL key Tab
sleep 0.5

eval $DOTOOL key Tab
sleep 0.5
eval $DOTOOL key Tab

# auf arbeit auswählen
sleep 1
eval $DOTOOL key Down
for i in $(seq 1 $ARBEIT_RUNTER); do
	$DOTOOL key Down
done
eval $DOTOOL key Return
sleep 1

# bemerkung skippen
eval $DOTOOL key Tab

# abteilung auswählen
eval $DOTOOL key Tab

eval $DOTOOL key Down
for i in $(seq 1 $ABTEILUNG_RUNTER); do
	eval $DOTOOL key Down
done
eval $DOTOOL key Return

# speichern
eval $DOTOOL key Tab
eval $DOTOOL key Return
sleep 5

kill %1
