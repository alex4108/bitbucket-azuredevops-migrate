# Migrate BitBucket repos to Azure DevOps

This migrates BitBucket repositories to Azure DevOps.  It will clone the repo from bitbucket, modify the remote origin, and push it to Azure DevOps, therefore preserving all commit history and branches.

It will not migrate Git LFS.

## Prereqs

* curl `sudo apt-get -y install curl`
* jq `sudo apt-get -y install jq`
* Your git client must authenticate to [BitBucket](https://support.atlassian.com/bitbucket-cloud/docs/set-up-an-ssh-key/) and [Azure Devops](https://docs.microsoft.com/en-us/azure/devops/repos/git/use-ssh-keys-to-authenticate?view=azure-devops) using SSH

## Setup .env

Fill in the variables...

* `BB_ORG`: The value here from this URL: https://bitbucket.org/${BB_ORG}
* `BB_USER`: Username from [this page](https://bitbucket.org/account/settings/)
* `BB_TOKEN`: App Password, [make one here](https://bitbucket.org/account/settings/app-passwords/).  Give it read permission for repositories.
* `ADO_ORG`: The Azure DevOps organiztion, URL is something like https://dev.azure.com/${ADO_ORG}
* `ADO_PAT`: Personal Access Token, make one here: https://dev.azure.com/${ADO_ORG}/_usersSettings/tokens.  Give it full repository permission.

## Get the list of repositories from BitBucket

```
bash get-repos.sh
```

This will generate a `repos.csv` file containing a list of all the repository names associated with your `${BB_ORG}`

## Prepare the mapping

The repos.csv file will map bitbucket sources to Azure Devops projects.  Column two must be the Azure Devops project name, which will be the parent for this repository.  

The destination project must already exist in Azure Devops before running the next script.

The destination repository must NOT already exist in Azure Devops; It will be created during execution.

If you don't want to bring a repository over, you can just remove it's row from the CSV file.

See the sample below if you want to.    

## Push the repos to Azure DevOps

Once you've created the mapping, run the script

```
bash migrate-repos.sh
```

This will create the repository using Azure Devops REST API, and push the repo to Azure Devops

# Project Sample

You can check out the `repos.sample.csv` for an example of what the final mapping file should look like

You can see what I cloned [from BitBucket](https://bitbucket.org/alex4108/azuredevops-migrate-sample/src/master/) [to AzureDevops](https://dev.azure.com/alex41081/BitBucket%20AzureDevops%20Migrate%20Sample/_git/azuredevops-migrate-sample)

For migrating JIRA Tickets, [this worked for me](https://github.com/solidify/jira-azuredevops-migrator)

# Contributing

Contributions are what make the open source community such an amazing place to be learn, inspire, and create. Any contributions you make are **greatly appreciated**.

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request