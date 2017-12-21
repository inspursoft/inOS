## Introduction

This guide provides how to build and run inOS as a kubernetes cluster's node.

## Step 1: Install CentOS 7-1611


Install CentOS-7-1611 on computer in "minimal" mode

## Step 2: Clone code for build inOS with kubernetes

```
$ git clone https://github.com/inspursoft/inOS.git
```


## Step 3: Build inOS with kubernetes

```
$ cd inOS
```

```
$ ./inOS-k8s.build.sh
```

The inOS-k8s.build.sh script has some options:

--help show the script usage.

--mastername and --masterip can define the kubernetes master info. 

You should build the kubernetes master by yourself. This script only build the inOS as a node of the kubernetes cluster.You can define the master by masterip alone. If use the master's hostname, you must define mastername and masterip both, the script will add static dns in /etc/hosts.

--hostname and --hostip is used to define the info of node which running this script.

As the mastername, hostname must define with hostip.

--registryip can define the insecure registry ip in you LAN network.

--rootpasswd can define the inOS's root password. The default password is `inspuros`
	
Waiting for automated build inOS image.

LIMITION:

1.The net device name in my computer is enp0s31f6, you should refine it for yourself.

2.The script only build the intel's e1000e ethernet card driver in kernel.

## Step 4: Reboot system and select "inOS-kubernetes"

