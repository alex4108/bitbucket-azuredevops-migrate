#!/usr/bin/env bash
set -eo pipefail

# If you really hosed something, use this to delete all repos found in repos.csv
# From azure devops!

source .env
curl_opts="-s -u $(whoami):${ADO_PAT}"
getAdoProject() { 
	proj_id=$(curl ${curl_opts} -X GET https://dev.azure.com/${ADO_ORG}/_apis/projects?api-version=6.0 | jq -r ".value[] | select(.name == \"$1\").id")
}

getRepoId() { 
    project=$1
    repo_name=$2
    repo_id=$(curl ${curl_opts} -X GET GET https://dev.azure.com/${ADO_ORG}/${project}/_apis/git/repositories?api-version=6.1-preview.1 | jq -r ".value[] | select (.name==\"${repo_name}\").id")
    if [[ "${repo_id}" == "" || "${repo_id}" == "null" ]]; then
	    echo "Failed to getRepoId for project $project :: repo $repo_name"
        exit 1
    fi
}

deleteAdoRepo() { 
    proj_id=$1
    repo_id=$2
    delete_result=$(curl ${curl_opts} -X DELETE https://dev.azure.com/${ADO_ORG}/${project}/_apis/git/repositories/${repo_id}?api-version=6.0)
    if [[ "${repo_id}" != "" ]]; then
	    echo "Error during delete repo :: project $project :: repo $repo_name"
        exit 1
    fi
}


lines=$(cat repos.csv)
SAVEIFS=$IFS   # Save current IFS
IFS=$'\n'      # Change IFS to new line
lines=($lines) # split to array $projects
IFS=$SAVEIFS   # Restore IFS

if [[ "$1" != "--delete" ]]; then
    echo "WARNING WARNING WARNING"
    for (( i=0; i<${#lines[@]}; i++ ))
    do
        line=${lines[$i]}
        
        sourceRepo=$(echo ${line} | cut -d, -f1)
        targetProject=$(echo ${line} | cut -d, -f2)
        sourceFolderWithGit=$(echo ${sourceRepo} | cut -d/ -f2)
        sourceFolder=$(echo ${sourceFolderWithGit} | sed 's/.git//g')
        repoName=$(echo ${sourceFolder} | sed "s/git@bitbucket.org:${BB_ORG}//g" | sed "s/.git//g")

        echo "${sourceFolder}"

    done
    echo "WARNING WARNING WARNING"
    echo "All repositories listed above will be DELETED from Azure DevOps!"
    echo "ENSURE YOU HAVE A COPY OF ALL REPOSITORIES BEFORE PROCEEDING."
    echo "TO PROCEED, RUN THIS SCRIPT AGAIN WITH THE --delete FLAG"
else
    for (( i=0; i<${#lines[@]}; i++ ))
    do
        line=${lines[$i]}
        echo "${line}"

        sourceRepo=$(echo ${line} | cut -d, -f1)
        targetProject=$(echo ${line} | cut -d, -f2)
        sourceFolderWithGit=$(echo ${sourceRepo} | cut -d/ -f2)
        sourceFolder=$(echo ${sourceFolderWithGit} | sed 's/.git//g')
        repoName=$(echo ${sourceFolder} | sed "s/git@bitbucket.org:${BB_ORG}//g" | sed "s/.git//g")

        getAdoProject "${targetProject}"
        getRepoId "${proj_id}" "${repoName}"
        deleteAdoRepo "${proj_id}" "${repo_id}"
    done
fi