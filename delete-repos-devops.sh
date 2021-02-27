#!/usr/bin/env bash
set -e
set -x
# If you really hosed something, use this to delete all repos found in repos.csv
# From azure devops!
source common.sh
source .env

log="delete-repos.log"
# Colors 

curl_opts="-s -u $(whoami):${ADO_PAT}"

getRepoId() { 
    proj_id=$1
    repo_name=$2
    echo "Getting repo_id for $repo_name in project $proj_id"
    repo_id=$(curl ${curl_opts} -X GET https://dev.azure.com/${ADO_ORG}/${proj_id}/_apis/git/repositories?api-version=6.1-preview.1 | jq -r ".value[] | select (.name==\"${repo_name}\").id")
    if [[ "${repo_id}" == "" || "${repo_id}" == "null" ]]; then
        warning "Skipping $repo_name as it wasn't found in the project $proj_name ($proj_id)"
        export SKIP="1"
    elif [[ *"${repo_id}"* == "Error"  ]]; then
        error "Error retrieving repo id for ${repo_name} from project $proj_name ($proj_id)"
        export SKIP="1"
    else
        info "Got repo ID: ${repo_id}"
    fi

}

deleteAdoRepo() { 
    proj_id=$1
    repo_id=$2
    echo "Deleting repo $repo_id in project $proj_id"
    delete_result=$(curl ${curl_opts} -s -o /dev/null -w "%{http_code}" -X DELETE https://dev.azure.com/${ADO_ORG}/${proj_id}/_apis/git/repositories/${repo_id}?api-version=6.0)
    if [[ "${delete_result}" != "200" && "${delete_result}" != "000204" && "${delete_result}" != "204" ]]; then
	    error "Error during delete repo :: project $proj_name :: repo $repo_name ($repo_id)"
        export SKIP="1"
    else
        success "Deleted repo $repo_name from project $proj_name"
    fi
}


lines=$(cat repos.csv)
SAVEIFS=$IFS   # Save current IFS
IFS=$'\n'      # Change IFS to new line
lines=($lines) # split to array $projects
IFS=$SAVEIFS   # Restore IFS

if [[ "$1" != "--delete" ]]; then
    echo "${YELLOW}WARNING WARNING WARNING${COLOR_OFF}"
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
    echo "${YELLOW}WARNING WARNING WARNING${COLOR_OFF}"
    echo "All repositories listed above will be DELETED from Azure DevOps!"
    echo "${YELLOW}ENSURE YOU HAVE A COPY OF ALL REPOSITORIES BEFORE PROCEEDING.${COLOR_OFF}"
    echo "${GREEN}TO PROCEED, RUN THIS SCRIPT AGAIN WITH THE --delete FLAG${COLOR_OFF}"
else
    startLog
    for (( i=0; i<${#lines[@]}; i++ ))
    do
        SKIP=0
        line=${lines[$i]}

        sourceRepo=$(echo ${line} | cut -d, -f1)
        targetProject=$(echo ${line} | cut -d, -f2 | sed ':a;N;$!ba;s|\r\n||g' | sed ':a;N;$!ba;s|\n||g')
        sourceFolderWithGit=$(echo ${sourceRepo} | cut -d/ -f2)
        sourceFolder=$(echo ${sourceFolderWithGit} | sed 's/.git//g')
        repoName=$(echo ${sourceFolder} | sed "s/git@bitbucket.org:${BB_ORG}//g" | sed "s/.git//g")

        echo "Deleting ${repoName}"


        if [[ "$SKIP" != "1" ]]; then
            getAdoProject "${targetProject}"
        fi
        
        if [[ "$SKIP" != "1" ]]; then
            getRepoId "${proj_id}" "${repoName}"
        fi
        
        if [[ "$SKIP" != "1" ]]; then
            deleteAdoRepo "${proj_id}" "${repo_id}"
        fi
        total=$((${total}+1))
    done

    info "Done!"
    info "Success: $(cat .countSuc) | Errors: $(cat .countError) | Total: ${total}"
    endLog
fi