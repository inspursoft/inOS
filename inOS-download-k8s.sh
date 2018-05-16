#!/bin/bash

function downloadk8sbinary {
echo "Downloading the latest release kubernetes binary"
echo "This may take several minitus"
## Download the latest kubernetes binary release
wget -c ${KUBEDOWNURL}
#wget -c `curl https://github.com/kubernetes/kubernetes/releases/latest 2>/dev/null | grep -oP '(?<=href=")[^"]*' | sed -e 's@tag@download@' -e 's@$@/kubernetes.tar.gz@'`
tar xf kubernetes.tar.gz
yes | kubernetes/cluster/get-kube-binaries.sh
tar xf kubernetes/server/kubernetes-server-linux-amd64.tar.gz
}
