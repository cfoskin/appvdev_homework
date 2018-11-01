#!/bin/bash
# Setup Development Project
if [ "$#" -ne 1 ]; then
    echo "Usage:"
    echo "  $0 GUID"
    exit 1
fi

GUID=$1
DEV_PROJECT=$GUID-parks-dev
echo "Setting up Parks Development Environment in project ${GUID}-parks-dev"

# Code to set up the parks development project.

# To be Implemented by Student
oc new-project $DEV_PROJECT --display-name="${GUID} AdvDev Homework Parks Development"

oc policy add-role-to-user edit system:serviceaccount:$GUID-jenkins:jenkins -n ${GUID}-parks-dev
oc policy add-role-to-user admin system:serviceaccount:$GUID-jenkins:jenkins -n ${GUID}-parks-dev

oc process -f ../templates/mongodb-single-template.yml -p NAMESPACE=$DEV_PROJECT | oc create -f -


while : ; do
  echo "Checking if Mongodb is Ready..."
  output=$(oc get pods --field-selector=status.phase='Running' | grep 'mongodb' | grep -v 'deploy' | grep '1/1' | awk '{print $2}')
  [[ "${output}" != "1/1" ]] || break #testing here
  echo "...no Sleeping 10 seconds."
  sleep 10
done
echo "Mongodb Deployment complete"