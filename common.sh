#!/usr/bin/env bash

countError=0
countSuc=0
countWarning=0
total=0

COLOR_OFF="\033[0m"
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
BLUE="\033[0;36m" # Is actually CYAN because BLUE is too dark imo

ts() { 
    # timestamp for logging
    date "+%Y-%m-%dT%H:%M:%S %Z%:z"
}

tsu() { 
    #timestamp in seconds since epoch (unix) format
    date "+%s"
}

tss() { 
    # timestamp-short
    date "+%Y-%m-%dT%H:%M:%S"
}   
incError() { 
    countError=$(( ${countError}+1 ))
    echo ${countError} > .countError
}

incWarning() {
    countWarning=$(( ${countWarning}+1 ))
    echo ${countWarning} > .countWarning
}
incSuc() { 
    countSuc=$(( ${countSuc}+1 ))
    echo ${countSuc} > .countSuc
}

info() {
    msg=$@
    echo -e "${BLUE}${msg}${COLOR_OFF}"
    echo "$(ts) INFO: ${msg}" >> ${log}
}

error() {
    # error "Message"
    msg=$@
    echo -e "${RED}${msg}${COLOR_OFF}"
    echo "$(ts) ERROR: ${msg}" >> ${log}
    incError
}

warning() { 
    # warning "Message"
    msg=$@
    echo -e "${YELLOW}${msg}${COLOR_OFF}"
    echo "$(ts) WARNING: ${msg}" >> ${log}
    incWarning
}   

success() { 
    # success "Message"
    msg=$@
    echo -e "${GREEN}${msg}${COLOR_OFF}"
    echo "$(ts) SUCCESS: ${msg}" >> ${log}
    incSuc
}   
startLog() { 
    info "SCRIPT START"
}
endLog() {
    info "SCRIPT END"
}

getAdoProject() { 
    proj_name="$1"
    echo "Getting project ID for ${proj_name}"
    proj_id=$(curl ${curl_opts} -X GET https://dev.azure.com/${ADO_ORG}/_apis/projects?api-version=6.0 | jq -r ".value[] | select(.name == \"${proj_name}\").id")
    if [[ "${proj_id}" == "" || *"${proj_id}"* == "Error"  ]]; then
        error "Error retrieving project id for ${proj_name}"
        export SKIP="1"
    else
        info "Got project ID: ${proj_id}"
    fi
}
