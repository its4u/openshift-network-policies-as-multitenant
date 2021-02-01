#!/bin/bash

source functions.sh
verify_installation


echo "Retrieving default project template..."

#Check if 'project-request' template already exist
pr_exist="false";
while read -r tp; do
    if [ "$tp" = "project-request" ]; then
        pr_exist="true";
        break;
    fi;
done < <(oc get template -n openshift-config -o name | sed "s:template.template.openshift.io/::")

#Get the 'project-request' template if it exist
if [ "$pr_exist" = "true" ]; then
    oc get template project-request -n openshift-config -o json > template.json;
    #Delete all network policy generated from this script, to begin with a clean template
    jq 'del(.objects[] | select(.metadata.annotations["'$ANNOTATION'"]=="true"))' template.json > tmp.json
    mv tmp.json template.json
#Or generate the default template
else
    oc adm create-bootstrap-project-template -o json > template.json;
    oc create -f template.json -n openshift-config --save-config
fi;

#Adding all network policies in the template file
echo "Adding Network Policy to template..."
for f in ./network-policies/*.json; do
    verify_json $f

    jq '.objects += $var1' \
        template.json \
        --slurpfile var1 $f \
        > new_template.json;
    mv new_template.json template.json;
done;

#Add annotations to new project
jq '.objects[0].metadata.annotations |= . + { "'$ANNOTATION'" : "Applied" }' \
    template.json \
    > new_template.json;
mv new_template.json template.json;


echo "Uploading template to cluster..."
oc apply -f template.json -n openshift-config


echo "Update cluster to use this template by default..."
#check wich template is used for project creation
res=$(oc get project.config.openshift.io/cluster -o json | jq '.spec.projectRequestTemplate.name')
#when no template is used, add the newly created one
if [ "$res" = "null" ]; then
    oc get project.config.openshift.io/cluster -o json | \
        jq '.spec.projectRequestTemplate |= . + {"name":"project-request"}' > tmp.json
    oc apply -f tmp.json -n openshift-config
    rm tmp.json
#when another template is used, use this one instead
elif [ ! "$res" = "\"project-request\"" ]; then
    oc patch project.config.openshift.io/cluster --type=json \
        -p='[{"op":"replace", "path":"/spec/projectRequestTemplate/name", "value":"project-request"}]'
fi;


echo "Update namespace 'default' with correct label..."
oc label namespaces default network.openshift.io/policy-group=ingress


echo "Cleaning files..."
rm template.json
