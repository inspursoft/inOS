#!/bin/bash
## Set the target image
## Can be docker/kubemaster/kubenode

function usage {
	echo "inOS-build.sh [options]"
	echo "	options:"
	echo "		--target : Set the inOS target(docker/kubemaster/kubenode), default: docker"
	echo "		--masterip : Set the kubernetes master ip"
	echo "		--nodeip : Set this kubernetes node ip"
	echo "		--rootpasswd passwd: Set the inOS's root password, default: 123456a?"
	echo "		--help: show this usage"
}

set -- `getopt -u -l help,rootpasswd:,target:,masterip:,nodeip: -- $0 $@`
while true ; do
	case $1 in
	--help) usage ; exit 1;;
	--rootpasswd) ROOTPW="$2" ; shift 2 ;;
	--target) TARGET="$2" ; shift 2 ;;
	--masterip) MASTERIP="$2" ; shift 2 ;;
	--nodeip) NODEIP="$2" ; shift 2 ;;
	--) shift ; break ;;
	*) usage ; exit 1 ;;
	esac
done

if [ "$TARGET" = "kubemaster" ]
then
if [ -z "$MASTERIP" ]
then
echo "When build kubernetes master, you should give the master's ip"
exit 1
fi
elif [ "$TARGET" = "kubenode" ]
then
if [ -z "$NODEIP" ] || [ -z "$MASTERIP" ]
then
echo "When build kubernetes node, you should give the master's ip and node's ip"
exit 1
fi
elif [ "$TARGET" != "docker" ]
then
echo "Unkown target"
exit 1
fi

buildrootfslocal
buildinitrdlocal
modifygrublocal
