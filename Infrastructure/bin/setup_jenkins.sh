#!/bin/bash
# Setup Jenkins Project
if [ "$#" -ne 3 ]; then
    echo "Usage:"
    echo "  $0 GUID REPO CLUSTER"
    echo "  Example: $0 wkha https://github.com/wkulhanek/ParksMap na39.openshift.opentlc.com"
    exit 1
fi

GUID=$1
REPO=$2
CLUSTER=$3
JENKINS_PROJECT=$GUID-jenkins
echo "Setting up Jenkins in project $JENKINS_PROJECT from Git Repo ${REPO} for Cluster ${CLUSTER}"

# Code to set up the Jenkins project to execute the
# three pipelines.
# This will need to also build the custom Maven Slave Pod
# Image to be used in the pipelines.
# Finally the script needs to create three OpenShift Build
# Configurations in the Jenkins Project to build the
# three micro services. Expected name of the build configs:
# * mlbparks-pipeline
# * nationalparks-pipeline
# * parksmap-pipeline
# The build configurations need to have two environment variables to be passed to the Pipeline:
# * GUID: the GUID used in all the projects
# * CLUSTER: the base url of the cluster used (e.g. na39.openshift.opentlc.com)

# To be Implemented by Student

oc new-project $JENKINS_PROJECT --display-name "Shared Jenkins"

echo $JENKINS_PROJECT
oc project $JENKINS_PROJECT

oc process -f ../templates/jenkins-template.yml -p NAMESPACE=$JENKINS_PROJECT | oc create -f -

echo "Building the slave"

oc new-build --name=jenkins-slave-maven-appdev -D $'FROM docker.io/openshift/jenkins-slave-maven-centos7:v3.9\nUSER root\nRUN yum -y install skopeo\nUSER 1001' -n $JENKINS_PROJECT
sleep 120

echo "Configuring slave"
# configure kubernetes PodTemplate plugin.
oc new-app -f ../templates/jenkins-config.yml --param GUID=$GUID -n $JENKINS_PROJECT

echo "Slave configured"