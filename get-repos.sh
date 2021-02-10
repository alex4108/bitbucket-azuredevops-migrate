#!/usr/bin/env bash
set -e
set pipefail



source .env

if [[ "${BB_USER}" == "" ]]; then
	echo "ERROR BB_USER variable is not set."
	exit 1
fi

if [[ "${BB_TOKEN}" == "" ]]; then
	echo "ERROR BB_TOKEN variable is not set."
	exit 1
fi

if [[ "${BB_ORG}" == "" ]]; then
	echo "ERROR BB_ORG variable is not set."
	exit 1
fi


repos=$(curl --user "${BB_USER}:${BB_TOKEN}" https://api.bitbucket.org/2.0/repositories/${BB_ORG}?pagelen=100 | jq -r '.values[].links.clone[] | select(.name=="ssh").href')
echo ${repos} > repos.csv
sed -i "s/ /,\n/g" repos.csv # gets most lines :shrug: