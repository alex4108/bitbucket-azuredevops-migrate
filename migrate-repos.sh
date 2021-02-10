#!/usr/bin/env bash
set -e
set pipefail

source .env

if [[ "${ADO_ORG}" == "" ]]; then
	echo "ERROR ADO_ORG variable is not set."
	exit 1
fi

if [[ "${ADO_PAT}" == "" ]]; then
	echo "ERROR ADO_PAT variable is not set."
	exit 1
fi

curl_opts="-s -u $(whoami):${ADO_PAT}"

getAdoProject() { 
	proj_id=$(curl ${curl_opts} -X GET https://dev.azure.com/${ADO_ORG}/_apis/projects?api-version=6.0 | jq -r ".value[] | select(.name == \"$1\").id")
}

createAdoProject() { 
	output=$(curl ${curl_opts} -X POST https://dev.azure.com/${ADO_ORG}/${proj_id}/_apis/git/repositories?api-version=6.0 \
	--header "Content-Type: application/json" \
	--data "{ \"name\": \"$1\", \"project\": { \"id\": \"${proj_id}\" } }")
	errorMsg=$(echo "${output}" | jq -r '.message' || true)

	if [[ "${errorMsg}" != "null" ]]; then
		echo "ERROR Creating repository $1 in project ${proj_id}"
		exit 1
	fi

	repo_url=$(echo ${output} | jq -r '.sshUrl')
}

lines=$(cat repos.csv)
SAVEIFS=$IFS   # Save current IFS
IFS=$'\n'      # Change IFS to new line
lines=($lines) # split to array $projects
IFS=$SAVEIFS   # Restore IFS

for (( i=0; i<${#lines[@]}; i++ ))
do
	line=${lines[$i]}
	echo "${line}"
	
	sourceRepo=$(echo ${line} | cut -d, -f1)
	targetProject=$(echo ${line} | cut -d, -f2)
	
	git clone ${sourceRepo}
	
	sourceFolderWithGit=$(echo ${sourceRepo} | cut -d/ -f2)
	sourceFolder=$(echo ${sourceFolderWithGit} | sed 's/.git//g')

	getAdoProject "${targetProject}"
	createAdoProject ${sourceFolder}

	cd ${sourceFolder}
	git remote rm origin
	git remote add origin ${repo_url}
	git push -u origin --all
	cd ../
	
	rm -rf ${sourceFolder}
done

