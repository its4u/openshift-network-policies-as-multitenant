# Openshift - Network Policies as multitenant

## Description

This project contain scripts that help in the deployment of a multitenant policy (when each namespace are isolated from eachother).
The main scripts are:

- `to_new_projects_by_default.sh`, edit the default project template, to apply the policy to each new projects.\
- `to_already_created_project.sh`, apply policies to all project (except: openshift projects and excluded project).
- `remove_policy.sh`, remove policies that have been have been applied on all projects, and remove the policies on project template.

Some other script are available for specific use:

- `exclude_project.sh`, force remove policies on current project (or named project). Project will be excluded of the list in `to_already_created_project.sh`
- `add_project.sh`, force add policies to current project (or named project), even to project that has been excluded.


## Require

`jq` : json file editor in command line\
`oc` : Openshift Command line interface\
Admin access to cluster.

## Usage:

```shell
bash <script>.sh
```
