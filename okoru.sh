#!/bin/bash
##This script is a helper script defining universal functions to be used in other scripts -
#+namely logging levels error reporting.
#+The idea is to source it in other scripts and thus have them all log the same.

#Error array for scripts that report runtime errors
declare -a errors=()

#Function to create inital log; Accepts the prefix of the log and folder.
#+For example, passing logging testytest will create the folder /var/log/okori/testytest
#+As well as a log file named testytest_Log and a report named testytest_[script_run_time]
#+Ex: /var/log/okori/testytest/testytest.
#+These files can then be pulled, renamed and compressed on an Ansible node.

#Color output#
BLACK='\033[0;30m'
DARK_GRAY='\033[1;30m'
RED='\033[0;31m'
LIGHT_RED='\033[1;31m'
GREEN='\033[0;32m'
LIGHT_GREEN='\033[1;32m'
ORANGE='\033[0;33m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
LIGHT_BLUE='\033[1;34m'
PURPLE='\033[0;35m'
LIGHT_PURPLE='\033[1;35m'
CYAN='\033[0;36m'
LIGHT_CYAN='\033[1;36m'
WHITE='\033[0;37m'
GRAY='\033[1;37m'
STOP="\e[0m"

# Default VERBOSE and LOG to empty so sourcing scripts using set -u don't get
# unbound variable errors. VERBOSE=1 enables debug logging; LOG is set by logging().
VERBOSE="${VERBOSE:-}"
LOG="${LOG:-/dev/null}"
LOG_OPT="${LOG_OPT:-}"

#If a function calls 'logging' for a log, it will create a log file; otherwise, keep the
#+variable empty thus printing only to terminal
logging () {
	if [[ -n ${2:-} ]]; then
		if [[ ! -d "/var/log/okori/$1/" ]]; then
			mkdir -p "/var/log/okori/$1/"
		fi
		export LOG="/var/log/okori/$1/$2Log"
		export REPORT="/var/log/okori/$1/$2"
		export PREFIX=$2
	else
		if [[ ! -d "/var/log/okori/$1/" ]]; then
			mkdir -p "/var/log/okori/$1/"
		fi
		export LOG="/var/log/okori/$1/$1Log"
		export REPORT="/var/log/okori/$1/$1"
		export PREFIX=$1
	fi
	if [[ -f "$LOG" ]]; then
		OLD_LOG_DATE=$(stat $LOG | grep Modify | awk '{print $2}' | sed -e 's/-//g')
		OLD_LOG_TIME=$(stat $LOG | grep Modify | awk '{print $3}' | sed -e 's/://g' | awk -F. '{print $1}')
		mv "$LOG" "$(dirname $LOG)/$(basename $LOG)_"$OLD_LOG_DATE"_"$OLD_LOG_TIME"" 2> /dev/null 2>&1
		gzip -f "$(dirname $LOG)/$(basename $LOG)_"$OLD_LOG_DATE"_"$OLD_LOG_TIME"" > /dev/null 2>&1
#		^ Append timestamp (YYYYMMDD_HHMMSS - ex 20210301_093543) to log if it exists
	fi
	if [[ -f "$REPORT" ]]; then
		OLD_REPORT_DATE=$(stat $REPORT | grep Modify | awk '{print $2}' | sed -e 's/-//g')
		OLD_REPORT_TIME=$(stat $REPORT | grep Modify | awk '{print $3}' | sed -e 's/://g' | awk -F. '{print $1}')
		mv "$REPORT" "$(dirname $REPORT)/$(basename $REPORT)_"$OLD_REPORT_DATE"_"$OLD_REPORT_TIME"" 2> /dev/null 2>&1
		gzip -f "$(dirname $REPORT)/$(basename $REPORT)_"$OLD_REPORT_DATE"_"$OLD_REPORT_TIME"" > /dev/null 2>&1
	fi
	touch $LOG
	touch $REPORT
#Greeter
	if [[ -n "$1" ]]; then
		printf "Logging is ${GREEN}enabled${STOP} via Okori!\n"
		printf "Log file: ${LIGHT_CYAN}$LOG\n${STOP}"
	fi
}

#If VERBOSE mode is enabled, print debug messages
if [[ -n $VERBOSE ]]; then
	#Debugging level logging; can be toggled via a switch
	debug () {
		if [[ -z ${2:-} ]]; then
			printf "${PURPLE}$(date +"%T:%N")${STOP} ${BLUE}[DEBUG]:   %s${STOP}\n" "$1" $LOG_OPT
		else
			printf "${PURPLE}$(date +"%T:%N")${STOP} ${BLUE}[DEBUG]:   %s${STOP} ${LIGHT_BLUE}%s${STOP}\n" "$1" "${2:-}" $LOG_OPT
		fi | tee -a $LOG
	}
#Otherwise, ignore debug calls;
else
	debug () {
		:
	}
fi

#Information level logging;
info () {
	if [[ -z ${2:-} ]]; then
		printf "${PURPLE}$(date +"%T:%N")${STOP} ${CYAN}[INFO]:${STOP}    %s\n" "$1" $LOG_OPT
	else
		printf "${PURPLE}$(date +"%T:%N")${STOP} ${CYAN}[INFO]:${STOP}    %s ${LIGHT_CYAN}%s${STOP}\n" "$1" "${2:-}" $LOG_OPT
	fi | tee -a $LOG
}

#Warning level logging;
warn () {
	if [[ -z ${2:-} ]]; then
		printf "${PURPLE}$(date +"%T:%N")${STOP} ${ORANGE}[WARNING]:${STOP} %s\n" "$1" $LOG_OPT
	else
		printf "${PURPLE}$(date +"%T:%N")${STOP} ${ORANGE}[WARNING]:${STOP} %s ${YELLOW}%s${STOP}\n" "$1" "${2:-}" $LOG_OPT
	fi | tee -a $LOG
}

#Error level logging; errors are added to an array scripts can later recall
error () {
	if [[ -z ${2:-} ]]; then
		printf "${PURPLE}$(date +"%T:%N")${STOP} ${RED}[ERROR]:   %s${STOP}\n" "$1" $LOG_OPT
	else
		printf "${PURPLE}$(date +"%T:%N")${STOP} ${RED}[ERROR]:   %s${STOP}${LIGHT_RED} %s${STOP}\n" "$1" "${2:-}" $LOG_OPT
	fi | tee -a $LOG
        errors+=("$1")
        return 1
}

#Success level logging;
ok () {
	if [[ -z ${2:-} ]]; then
		printf "${PURPLE}$(date +"%T:%N")${STOP} ${GREEN}[SUCCESS]: %s${STOP}\n" "$1" $LOG_OPT
	else
		printf "${PURPLE}$(date +"%T:%N")${STOP} ${GREEN}[SUCCESS]: %s${STOP}${LIGHT_GREEN} %s${STOP}\n" "$1" "${2:-}" $LOG_OPT
	fi | tee -a $LOG
}

# Same as logging function opener, for scripts that need to wrap things up nicely
end_logging () {
	if [[ -f "$LOG" ]]; then
		OLD_LOG_DATE=$(stat $LOG | grep Modify | awk '{print $2}' | sed -e 's/-//g')
		OLD_LOG_TIME=$(stat $LOG | grep Modify | awk '{print $3}' | sed -e 's/://g' | awk -F. '{print $1}')
		mv "$LOG" "$(dirname $LOG)/$(basename $LOG)_"$OLD_LOG_DATE"_"$OLD_LOG_TIME"" 2> /dev/null 2>&1
		gzip -f "$(dirname $LOG)/$(basename $LOG)_"$OLD_LOG_DATE"_"$OLD_LOG_TIME"" > /dev/null 2>&1
#		^ Append timestamp (YYYYMMDD_HHMMSS - ex 20210301_093543) to log if it exists
	fi
}
