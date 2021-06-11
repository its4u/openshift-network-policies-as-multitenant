#!/bin/bash

source vars

#####
## Verify everything required is available
#####
    #jq to edit json formated stream
    if ! which jq > /dev/null 2> /dev/null;then
        echo "Please install jq";
        exit 1
    fi
    #oc to manipulate OpenShift cluster
    if ! which oc > /dev/null 2> /dev/null; then
        echo "Please install oc."
        exit 1
    fi
    #connection to cluster
    if ! oc whoami > /dev/null 2> /dev/null; then
        echo "Not connected to cluster. Please run 'oc login' with administrator credentials."
        exit 1
    fi

#####
## Apply NetworkPolicies to existing namespaces
#####
while read -r ns; do
    echo ">>Analysing namespace $ns";

    # Get the current state of the namespace
    res=$(oc get namespace $ns -o jsonpath='{.metadata.labels.'$NS_LABEL'}')

    # When the namespace is excluded from this patch
    if [ "$res" = "false" ]; then
        echo "Not Concerned.";$
        echo "";
        continue;
    fi;

    #Apply all network-policies in the folder
    for np in ./network-policies/*.json; do
        jq '.metadata.labels."'$NP_LABEL'" |= "true"' $np | oc apply -n $ns -f -;
    done;

    #change the namespace state
    oc label namespace $ns $NS_LABEL="true" --overwrite;

    echo "";

#get all projects name, exclude 'default' and all namespaces begenning with 'openshift' and 'kube'
done < <(oc get namespace -o name | sed 's:^namespace/::' | grep -vE '^(default$|openshift|kube)')

#####
## Apply to default template
#####

# Get current project-request if exist, create default if not
if oc get template -n openshift-config | grep "project-request" > /dev/null; then
    oc get template project-request -n openshift-config -o json > $TEMPLATE;
else
    oc adm create-bootstrap-project-template -o json > $TEMPLATE;
fi;

#Adding all network policies in the template file
echo "Adding Network Policy to template..."
for np in ./network-policies/*.json; do
    jq '.metadata.labels."'$NP_LABEL'" |= "true"' $np > $TEMP_FIL2

    jq '.objects += $obj' $TEMPLATE --slurpfile obj $TEMP_FIL2 > $TEMP_FILE && mv $TEMP_FILE $TEMPLATE
done;

#Add labels to new project
jq '.objects |=  (map(.kind) | index("Project")) as $obj | .[$obj]["metadata"]["labels"]["'$NS_LABEL'"] = "true"' $TEMPLATE > $TEMP_FILE && mv $TEMP_FILE $TEMPLATE

echo "Uploading template to cluster..."
oc apply -f $TEMPLATE -n openshift-config

echo "Update cluster to use this template by default..."
oc patch project.config.openshift.io/cluster --type=json -p='[{"op": "replace", "path": "/spec/projectRequestTemplate", "value": {"name":"project-request"}}]'

echo "Cleaning files..."
rm $TEMPLATE $TEMP_FILE $TEMP_FIL2
