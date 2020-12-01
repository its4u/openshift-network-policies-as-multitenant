

## Description

Thoses scripts help in the deployment of a multitenant policy (when each namespace are isolated from eachother).

The first script, `to_new_projects_by_default.sh`, edit the default project template, to apply the policy to each new projects.\
The second script, `to_already_created_project.sh`, edit all created project (except project created by openshift) to apply the policy.

The last scrip giver, `remove_policy.sh`, remove policies that have been have been applied by the previous script, on all projects.

## Require

`jq` : json file editor in command line\
`oc` : Openshift Command line interface\
Admin access to cluster.

## Usage:

```shell
bash to_new_projects_by_default.sh

bash to_already_created_project.sh

bash remove_policy.sh
```