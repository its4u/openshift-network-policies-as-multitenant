#!/bin/bash

#Test si connecte au cluster
if oc whoami > /dev/null 2> /dev/null; then
    echo "Connected to cluster."
else
    echo "Not connected to cluster. Please run 'oc login' with administrator credentials."
    exit 1
fi

#Fichier des projets à selectionner
FILE=./projects_selected

#Si le fichier existe, appliquer les regles pour chaques projets
if test -f "$FILE"; then
    #Pour chaque lignes 'p' du fichier (donc pour chaque projet)
    while read p; do
        echo "Creating for project $p";
        oc create -n $p -f ./network-policies/allow-from-openshift-ingress.yml;
        oc create -n $p -f ./network-policies/allow-from-openshift-monitoring.yml;
        oc create -n $p -f ./network-policies/allow-same-namespace.yml;
    done < $FILE;
    exit 0;

#si le fichier n'existe pas, creer le fichier et lister tous les projet
else
    touch $FILE;
    oc projects -q | grep -v openshift | grep -v kube | grep -v default > $FILE;

    echo "Please delete all project that are not concerned by the Network Policies in the file $FILE, then run this script again."
    exit 0
fi
