#!/bin/bash

source functions.sh
verify_installation


echo "Removing NetworkPolicy on projects..."

#For each project (see "done" for the list), remove currently applied network policies
while read -r p; do
    echo ">>Analysing project $p";

    #Check the project state
    res=$(oc get project $p -o json | jq '.metadata.annotations["'$ANNOTATION'"]')

    #Remove policies only if project has applied policies by this script
    if [ "$res" = "\"Applied\"" ]; then

        #For each policies in the project (see "done" for the list)
        while read -r np; do

            #Check if policy has been created by this script
            res=$(oc get networkpolicy $np -n $p -o json | jq '.metadata.annotations["'$ANNOTATION'"]');
            
            #Remove the policy only if applied by this script
            if [ "$res" = "\"true\"" ]; then
                oc delete networkpolicy $np -n $p;
            fi;

        #get all network policies of the project, and format the output to get only names.
        done < <(oc get networkpolicy -o name -n $p | sed 's:^networkpolicy.networking.k8s.io/::')

        #Change the project state
        oc annotate namespace $p $ANNOTATION=NotApplied --overwrite;
    
    #If project state is not "applied", nothing to do
    else
        echo "Not concerned..."
    fi

#get all projects name, exclude 'default' and all project begenning with 'openshift' and 'kube'
done < <(oc projects -q | grep -vE '^(default$|openshift|kube)')

#Remove network policies in the default template used when creating new project.
oc get template project-request -n openshift-config -o json > template.json;
jq 'del(.objects[] | select(.metadata.annotations["'$ANNOTATION'"]=="true"))' template.json > tmp.json
mv tmp.json > template.json
oc apply -f template.json -n openshift-config
rm template.json
