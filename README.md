# Openshift - Network Policies as multitenant

## Description

This project contain scripts that help in the deployment of a multitenant policy (when each namespace is considered as a single tenant and is isolated from other namespaces).

The scripts are:
- `enable.sh`, Add Network Policies to all project, and create default project template to include Network Policies.\
- `disable.sh`, Remove any policies that have been have been applied on all projects, and remove the policies on project template.
- `exclude_namespace.sh`, force remove policies on current project (or named namespace).
To cancel exclusion, remove label on namespace.

## Require

`jq` : json file editor in command line\
`oc` : Openshift Command line interface\
Admin access to cluster.

## Usage:

```shell
bash <script>.sh
```
