

## Description

Thoses two script help in the deployment of a multitenant policy (each namespace are isolated from eachother).

The first script, `to_new_projects_by_default.sh`, edit the default project template, to apply the policy to each new projects.
The second script, `to_already_created_project.sh`, edit all created project (except project created by openshift) to apply the policy.

## Usage:

```shell
bash to_new_projects_by_default.sh
bash to_already_created_project.sh
```