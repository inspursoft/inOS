#!/bin/bash

. ./inOS-download-k8s.sh

function buildk8senvironment {
echo "Build the kubernetes enviroment"
downloadk8sbinary
}
