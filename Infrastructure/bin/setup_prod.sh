#!/bin/bash
# Setup Production Project (initial active services: Green)
if [ "$#" -ne 1 ]; then
    echo "Usage:"
    echo "  $0 GUID"
    exit 1
fi

GUID=$1
PROD_PROJECT=$GUID-parks-prod
echo "Setting up Parks Production Environment in project ${PROD_PROJECT}"

# Code to set up the parks development project.

# To be Implemented by Student
oc new-project $PROD_PROJECT --display-name="${GUID} AdvDev Homework Parks Production"

oc policy add-role-to-user edit system:serviceaccount:$GUID-jenkins:jenkins -n ${PROD_PROJECT}
oc policy add-role-to-user admin system:serviceaccount:$GUID-jenkins:jenkins -n ${PROD_PROJECT}

echo "Creating internal mongo service.."
oc create -f ../templates/mongodb-service-internal-template.yml 

echo "Creating mongo service.."
oc create -f ../templates/mongodb-service-template.yml 

echo "Creating mongo StatefulSet.."
oc create -f ../templates/mongodb-statefulset-template.yml 


echo "Checking if Mongodb Stateful set is Ready..."
check_if_ready () {
   while : ; do
   	 echo "Checking mongodb-$1 pod.."
   	 output=$(oc get pods --field-selector=status.phase='Running' | grep 'mongodb-'$1 | grep '1/1' | awk '{print $2}')
   	 echo $output
	 [[ "${output}" != "1/1" ]] || break #testing here
	 echo "...no Sleeping 10 seconds."
	 sleep 10
   done	 
} 

check_if_ready "0"
check_if_ready "1"
check_if_ready "2"

echo "Mongodb Deployment complete"
# # Code to set up the parks production project. It will need a StatefulSet MongoDB, and two applications each (Blue/Green) for NationalParks, MLBParks and Parksmap.
# # The Green services/routes need to be active initially to guarantee a successful grading pipeline run.

# To be Implemented by Student
