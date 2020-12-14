#!/bin/bash

source functions.sh
verify_installation


echo "Applying NetworkPolicy on projects..."

#For each project (see "done" for the list)
while read -r p; do
    echo ">>Analysing project $p";

    #Get the current state of the project
    res=$(oc get project $p -o json | jq '.metadata.annotations["'$ANNOTATION'"]')

    #When project has already been applied with this patch
    if [ "$res" = "\"applied\"" ]; then
        echo "Already applied.";
    #When the project is excluded from this patch
    elif [ "$res" = "\"NotConcerned\"" ]; then
        echo "Not Concerned.";
    else
        #Apply all network-policies in the folder
        for f in ./network-policies/*.json; do
            verify_json $f

            oc create -n $p -f $f;
        done;

        #change the project state
        oc annotate namespace $p $ANNOTATION=applied --overwrite;
    fi;

#get all projects name, exclude 'default' and all project begenning with 'openshift' and 'kube'
done < <(oc projects -q | grep -vE '^(default$|openshift|kube)')


