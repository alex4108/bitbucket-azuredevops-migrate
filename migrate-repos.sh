#!/usr/bin/env bash
set -e
set pipefail
set -x

source common.sh
source .env
log="migrate-repos.log"

chkErr() { 
	if [[ "$?" -gt "0" ]]; then
		error $@
		SKIP=1
	fi
}

if [[ "${ADO_ORG}" == "" ]]; then
	error "ERROR ADO_ORG variable is not set."
	exit 1
fi

if [[ "${ADO_PAT}" == "" ]]; then
	error "ERROR ADO_PAT variable is not set."
	exit 1
fi

curl_opts="-s -u $(whoami):${ADO_PAT}"

createAdoRepo() { 
	echo "Creating repo in ADO for $1 in project ${project_id}"
	response=$(curl ${curl_opts} -X POST -s -w "\n%{http_code}" https://dev.azure.com/${ADO_ORG}/${proj_id}/_apis/git/repositories?api-version=6.0 \
	--header "Content-Type: application/json" \
	--data "{ \"name\": \"$1\", \"project\": { \"id\": \"${proj_id}\" } }")

	create_result="$(tail -n1 <<< "$response")"
	output="$(sed '$ d' <<< "$response")"

	if [[ "${create_result}" != "200" && "${create_result}" != "201" && "${create_result}" != "000204" && "${create_result}" != "204" ]]; then
		error "ERROR (${create_result}) Creating repository $1 in project ${proj_id} :: $(echo ${output} | jq -r '.message')"
		SKIP=1
	else
		info "Create repo success"
	fi

	repo_url=$(echo ${output} | jq -r '.sshUrl')
}


lines=$(cat repos.csv)
SAVEIFS=$IFS   # Save current IFS
IFS=$'\n'      # Change IFS to new line
lines=($lines) # split to array $projects
IFS=$SAVEIFS   # Restore IFS
startLog
for (( i=0; i<${#lines[@]}; i++ ))
do
	SKIP=0
	line=${lines[$i]}
	echo "${line}"
	
	sourceRepo=$(echo ${line} | cut -d, -f1)
	targetProject=$(echo ${line} | cut -d, -f2)
	
	
	sourceFolderWithGit=$(echo ${sourceRepo} | cut -d/ -f2)
	sourceFolder=$(echo ${sourceFolderWithGit} | sed 's/.git//g')

	if [[ "${SKIP}" != "1" ]]; then
		getAdoProject "${targetProject}"
	fi
	 
	if [[ "${SKIP}" != "1" ]]; then
		createAdoRepo ${sourceFolder}
	fi
	
	if [[ "${SKIP}" != "1" ]]; then

		info "Starting git mitgration for ${sourceRepo}"

		if [[ "${SKIP}" != "1" ]]; then
			git clone ${sourceRepo}
			chkErr "Tried to clone ${sourceRepo}"
		fi
		
		cd ${sourceFolder}

		# Fetch all branches https://stackoverflow.com/questions/67699/how-to-clone-all-remote-branches-in-git
		for branch in $(git branch --all | grep '^\s*remotes' | egrep --invert-match '(:?HEAD|master)$'); do
			git branch --track "${branch##*/}" "$branch"
		done
		if [[ "${SKIP}" != "1" ]]; then
			git fetch --all
			chkErr "git fetch --all"
		fi
		
		if [[ "${SKIP}" != "1" ]]; then
			git pull --all
			chkErr "git pull --all"
		fi
	
		if [[ "${SKIP}" != "1" ]]; then
			git remote rm origin
			chkErr "git remote rm origin"
		fi
		
		if [[ "${SKIP}" != "1" ]]; then
			git remote add origin ${repo_url}
			chkErr "git remote add origin ${repo_url}"
		fi
		
		if [[ "${SKIP}" != "1" ]]; then
			git push -u origin --all
			chkErr "git push -u origin --all"
		fi
		
		if [[ "${SKIP}" != "1" ]]; then
			git push --tags
			chkErr "git push --tags"
		fi
		
		success "Git migration complete for ${sourceRepo}"

		cd ../

		rm -rf ${sourceFolder}
	fi
	total=$((${total}+1))
	exit 0
done

info "Done!"
info "Success: $(cat .countSuc) | Errors: $(cat .countError) | Total: ${total}"
endLog