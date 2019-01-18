#!/bin/bash

#### Misc

# really hacky; don't tell anyone
_indirect() {
	echo ${!1}
}

alias const=readonly

#### Color 

_color() {
	case $1 in
	black)
		return 0;;
	red)
		return 1;;
	green)
		return 2;;
	yellow)
		return 3;;
	blue)
		return 4;;
	magenta)
		return 5;;
	cyan)
		return 6;;
	white)
		return 7;;
	brightBlack)
		return 60;;
	brightRed)
		return 61;;
	brightGreen)
		return 62;;
	brightYellow)
		return 63;;
	brightBlue)
		return 64;;
	brightMagenta)
		return 65;;
	brightCyan)
		return 66;;
	brightWhite)
		return 67;;
	esac
}

_fgcolor() {
	_color $1
	return $(($? + 30))
}

_bgcolor() {
	_color $1
	return $(($? + 40))
}

color() {
	local OPTIND o a

	fg=0
	bg=0
	clear=0
	pipe=1
	while getopts "f:b:cn" arg; do
		case "$arg" in
		f)
			_fgcolor "$OPTARG"
			fg=$?
			;;
		b)
			_bgcolor "$OPTARG"
			bg=$?
			;;
		c)
			clear=1
			;;
		n)
			pipe=0
			;;
		*)
			echo Unknown option $arg.
			;;
		esac
	done

	shift $((OPTIND - 1))

	if test $fg = 0 -a $bg = 0; then
		pipe=0
	fi

	if test $fg != 0; then
		echo -ne "\033[${fg}m"
	fi
	if test $bg != 0; then
		echo -ne "\033[${bg}m"
	fi
	if test $pipe = 1; then
		cat
	fi
	if test $clear = 1; then
		echo -ne "\033[0m"
	fi
}

#### Input

_yesNo() {
	case $1 in
	y|yes|Y|YES)
		return 0;;
	n|no|N|NO)
		return 1;;
	*)
		return 2;;	
	esac
}

decision() {
	text="$1"
	prefered="$2"

	while true; do
		echo -n "$text "
		if test "$prefered" = "y"; then
			echo -n "[Y/n] "
		elif test "$prefered" = "n"; then
			echo -n "[y/N] "
		else
			echo -n "[y/n] "
		fi

		read ans

		if test -z "$ans"; then
			if test -z "$prefered"; then
				echo "Please answer with yes or no (no prefered)."
			else
				_yesNo $prefered
				return $?
			fi
		fi

		_yesNo $ans
		result=$?
		if test $result = 2; then
			echo "Please answer with yes or no."
		else
			return $result
		fi
	done

}

getch() {
  stty -icanon
  eval "$1=\$(dd bs=1 count=1 2>/dev/null)"
  stty icanon
}

enableEcho() {
	stty echo
}

disableEcho() {
	stty -echo
}

pause() {
	local tmp
	disableEcho
	echo -n "Press any key to continue. "
	getch tmp
	enableEcho
	echo
}

#### LOGGING

const _VERBOSITY_DEBUG=-1
const _VERBOSITY_INFO=0
const _VERBOSITY_WARN=1
const _VERBOSITY_ERROR=2
const _VERBOSITY_CRITICAL=3
const _VERBOSITY_SILENT=100

const _VERBOSITY_DEFAULT=$_VERBOSITY_INFO

setVerbosity() {
	export _VERBOSITY=$(_indirect "_VERBOSITY_$1")
}

getVerbosity() {
	level=$1
	if test -z "$level"; then
		level=$_VERBOSITY
	fi
	case $level in
	$_VERBOSITY_DEBUG)
		echo DEBUG;;
	$_VERBOSITY_INFO)
		echo INFO;;
	$_VERBOSITY_WARN)
		echo WARN;;
	$_VERBOSITY_ERROR)
		echo ERROR;;
	$_VERBOSITY_CRITICAL)
		echo CRITICAL;;
	*)
		echo UNKNOWN;;
	esac	
}

_getVerbosityColor() {
	level=$1
	if test -z "$level"; then
		level=$_VERBOSITY
	fi
	case $level in
	$_VERBOSITY_DEBUG)
		echo blue;;
	$_VERBOSITY_INFO)
		echo cyan;;
	$_VERBOSITY_WARN)
		echo yellow;;
	$_VERBOSITY_ERROR)
		echo red;;
	$_VERBOSITY_CRITICAL)
		echo brightRed;;
	*)
		echo black;;
	esac	
}

setVerbosity DEFAULT

setLogfile() {
	export _LOGFILE=$1
}

setLogfile ""

setLogDate() {
	_yesNo $1
	export _LOGDATE=$?
}

setLogDate yes

_logfile() {
	if test -n "$_LOGFILE"; then
		cat >> $_LOGFILE
	fi
}

log() {
	level=$1
	if test -z "$level"; then
		level=$_VERBOSITY_DEFAULT
	else
		level=$(_indirect _VERBOSITY_$level)
		if test -z "$level"; then 
			level=10
		fi
	fi

	if test "$level" -lt $_VERBOSITY; then
		return
	fi

	if test $_LOGDATE = 0; then
		echo -n "$(date --iso-8601=ns)" | tee >(_logfile)
	fi

	echo -n " [$(getVerbosity $level)] " | tee >(_logfile) | color -f $(_getVerbosityColor) -c

	cat | tee >(_logfile)
}


#### DEPENDENCIES

dependencies() {
	declare -a missing

	for dependency in $@; do
		if which $dependency > /dev/null; then
			# dependency found
			:	
		else
			missing+=$dependency
		fi
	done

	if test "${#missing[@]}" = 0; then
		return 0
	fi

	echo "The following dependencies are missing: "
	for dependency in $missing; do
		echo "- $dependency"	
	done
	return 1
}
