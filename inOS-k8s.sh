#!/bin/bash

. ./inOS-download-k8s.sh

function copyk8smaster {
mkdir -p ${ROOTFSPATH}/etc/kubernetes/{manifests,certs}
mkdir -p ${ROOTFSPATH}/var/lib/inOS/images

cp kubernetes/server/bin/{kube-apiserver,kube-controller-manager,kube-scheduler}.tar ${ROOTFSPATH}/var/lib/inOS/images
cp images/*.tar ${ROOTFSPATH}/var/lib/inOS/images
cp kubernetes/server/bin/{kubelet,kubectl} ${ROOTFSPATH}/usr/bin
}

function copyk8snode {
mkdir -p ${ROOTFSPATH}/etc/kubernetes/{manifests,certs}
mkdir -p ${ROOTFSPATH}/var/lib/inOS/images
mkdir -p ${ROOTFSPATH}/opt/cni/bin

cp images/*.tar ${ROOTFSPATH}/var/lib/inOS/images
cp kubernetes/server/bin/{kubelet,kubectl,kube-proxy} ${ROOTFSPATH}/usr/bin
cp bin/* ${ROOTFSPATH}/opt/cni/bin

sed -i '/ExecStart/s/$/ --iptables=false/' ${ROOTFSPATH}/usr/lib/systemd/system/docker.service
}

function createkubeletconfig {
cat > ${ROOTFSPATH}/usr/lib/systemd/system/kubelet.service << EOF
[Unit]
Description=Kubernetes Kubelet Server
Documentation=https://github.com/GoogleCloudPlatform/kubernetes
After=inOS-loadimages.service
Requires=inOS-loadimages.service

[Service]
WorkingDirectory=/var/lib/kubelet
EnvironmentFile=-/etc/kubernetes/config
EnvironmentFile=-/etc/kubernetes/kubelet
ExecStart=/usr/bin/kubelet --pod-manifest-path /etc/kubernetes/manifests --fail-swap-on=false
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

mkdir -p ${ROOTFSPATH}/var/lib/kubelet
pushd ${ROOTFSPATH}/etc/systemd/system/multi-user.target.wants/
ln -sv /usr/lib/systemd/system/kubelet.service kubelet.service
popd
}

function createkubeletandkubeproxyconfig {
cat > ${ROOTFSPATH}/usr/lib/systemd/system/kubelet.service << EOF
[Unit]
Description=Kubernetes Kubelet Server
Documentation=https://github.com/GoogleCloudPlatform/kubernetes
After=inOS-loadimages.service
Requires=inOS-loadimages.service

[Service]
WorkingDirectory=/var/lib/kubelet
EnvironmentFile=-/etc/kubernetes/config
EnvironmentFile=-/etc/kubernetes/kubelet
ExecStart=/usr/bin/kubelet --pod-manifest-path /etc/kubernetes/manifests --fail-swap-on=false --network-plugin kubenet --hostname-override=${NODEIP} --allow-privileged=true --kubeconfig /etc/kubernetes/kubeletconfig.yaml
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

cat > ${ROOTFSPATH}/usr/lib/systemd/system/kube-proxy.service << EOF
[Unit]
Description=Kubernetes Kubelet Server
Documentation=https://github.com/GoogleCloudPlatform/kubernetes
After=inOS-loadimages.service
Requires=inOS-loadimages.service

[Service]
WorkingDirectory=/var/lib/kubelet
EnvironmentFile=-/etc/kubernetes/config
EnvironmentFile=-/etc/kubernetes/kubelet
ExecStart=/usr/bin/kube-proxy --kubeconfig /etc/kubernetes/kubeproxyconfig.yaml
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

cat > ${ROOTFSPATH}/etc/kubernetes/kubeletconfig.yaml << EOF
apiVersion: v1
clusters:
- cluster:
    server: http://${MASTERIP}:8080
  name: local
contexts:
- context:
    cluster: local
    user: kubelet
  name: kubelet-context
current-context: kubelet-context
kind: Config
preferences: {}
users:
- name: kubelet
EOF

cat > ${ROOTFSPATH}/etc/kubernetes/kubeproxyconfig.yaml << EOF
apiVersion: v1
clusters:
- cluster:
    server: http://${MASTERIP}:8080
  name: local
contexts:
- context:
    cluster: local
    user: kube-proxy
  name: kube-proxy-context
current-context: kube-proxy-context
kind: Config
preferences: {}
users:
- name: kube-proxy
EOF

mkdir -p ${ROOTFSPATH}/var/lib/kubelet
pushd ${ROOTFSPATH}/etc/systemd/system/multi-user.target.wants/
ln -sv /usr/lib/systemd/system/kubelet.service kubelet.service
ln -sv /usr/lib/systemd/system/kube-proxy.service kube-proxy.service
popd
}

function createloadimagesconfig {
cat > ${ROOTFSPATH}/usr/bin/inOS-loadimages << EOF
#!/bin/bash
for image in \`ls /var/lib/inOS/images/*\`
do
docker load -i \$image
done
EOF
chmod +x ${ROOTFSPATH}/usr/bin/inOS-loadimages

cat > ${ROOTFSPATH}/usr/lib/systemd/system/inOS-loadimages.service << EOF
[Unit]
Description=inOS load images
Documentation=http://docs.docker.com
After=docker.service
Wants=docker.service
Requires=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/bin/inOS-loadimages

[Install]
WantedBy=multi-user.target
EOF

pushd ${ROOTFSPATH}/etc/systemd/system/multi-user.target.wants/
ln -sv /usr/lib/systemd/system/inOS-loadimages.service inOS-loadimages.service
popd
}

function createmanifestsconfig {
## Create the master container files
cat > ${ROOTFSPATH}/etc/kubernetes/manifests/etcd.manifest << EOF
{
"apiVersion": "v1",
"kind": "Pod",
"metadata": {
  "name":"etcd-serverv3.0.17",
  "namespace": "kube-system"
},
"spec":{
"hostNetwork": true,
"containers":[
    {
    "name": "etcd-container",
    "image": "gcr.io/google_containers/etcd:3.0.17",
    "resources": {
      "requests": {
        "cpu": 1
      }
    },
    "command": [
              "/bin/sh",
              "-c",
              "if [ -e /usr/local/bin/migrate-if-needed.sh ]; then /usr/local/bin/migrate-if-needed.sh 1>>/var/log/etcd/3.0.17.log 2>&1; fi; /usr/local/bin/etcd --name etcd-${MASTERIP} --listen-peer-urls http://${MASTERIP}:2380 --initial-advertise-peer-urls http://${MASTERIP}:2380 --advertise-client-urls http://${MASTERIP}:2379 --listen-client-urls http://${MASTERIP}:2379 --quota-backend-bytes=4294967296 --data-dir /var/etcd/data/3.0.17 --initial-cluster-state new --initial-cluster etcd-${MASTERIP}=http://${MASTERIP}:2380 1>>/var/log/etcd/3.0.17.log 2>&1"
            ],
    "env": [
      { "name": "TARGET_STORAGE",
        "value": "etcd3"
      },
      { "name": "TARGET_VERSION",
        "value": "3.0.17"
      },
      { "name": "DATA_DIRECTORY",
        "value": "/var/etcd/data/3.0.17"
      }
        ],
    "livenessProbe": { "httpGet": {
        "host": "${MASTERIP}",
        "port": 2379,
        "path": "/health"
      },
      "initialDelaySeconds": 15,
      "timeoutSeconds": 15
    },
    "ports": [
      { "name": "serverport",
        "containerPort": 2380,
        "hostPort": 2380 
      },
      { "name": "clientport",
        "containerPort": 2379,
        "hostPort": 2379
      }
        ],
    "volumeMounts": [
      { "name": "varetcd",
        "mountPath": "/var/etcd",
        "readOnly": false
      },
      { "name": "varlogetcd",
        "mountPath": "/var/log/etcd",
        "readOnly": false
      },
      { "name": "etc",
        "mountPath": "/srv/kubernetes",
        "readOnly": false
      }
    ]
    }
],
"volumes":[
  { "name": "varetcd",
    "hostPath": {
        "path": "/mnt/master-pd/var/etcd"}
  },
  { "name": "varlogetcd",
    "hostPath": {
        "path": "/var/log/etcd"}
  },
  { "name": "etc",
    "hostPath": {
        "path": "/srv/kubernetes"}
  }
]
}
}
EOF

cat > ${ROOTFSPATH}/etc/kubernetes/manifests/apiserver.manifest << EOF
{
	"kind": "Pod",
	"apiVersion": "v1",
	"metadata": {
		"name": "kube-apiserver"
	},
	"spec": {
		"hostNetwork": true,
		"containers": [
		{
			"name": "kube-apiserver",
			"image": "gcr.io/google_containers/kube-apiserver:${KUBEVER}",
			"command": [
				"kube-apiserver",
				"--logtostderr=true",
				"--v=0",
				"--etcd-servers=http://${MASTERIP}:2379",
				"--insecure-bind-address=0.0.0.0",
				"--allow-privileged=true",
				"--service-cluster-ip-range=10.254.0.0/16",
				"--admission-control=NamespaceLifecycle,NamespaceExists,LimitRanger,SecurityContextDeny,ResourceQuota"
			],
			"ports": [
				{
					"name": "https",
					"hostPort": 6443,
					"containerPort": 6443
				},
				{
					"name": "local",
					"hostPort": 8080,
					"containerPort": 8080
				}
			],
			"volumeMounts": [
				{
					"name": "etckube",
					"mountPath": "/etc/kubernetes",
					"readOnly": true
				}
			],
			"livenessProbe": {
				"httpGet": {
					"scheme": "HTTP",
					"host": "127.0.0.1",
					"port": 8080,
					"path": "/healthz"
				},
				"initialDelaySeconds": 15,
				"timeoutSeconds": 15
			}
		}
		],
		"volumes": [
		{
			"name": "etckube",
			"hostPath": {
				"path": "/etc/kubernetes"
			}
		}
		]
	}
}
EOF

cat > ${ROOTFSPATH}/etc/kubernetes/manifests/controller-manager.manifest << EOF
{
	"kind": "Pod",
	"apiVersion": "v1",
	"metadata": {
		"name": "kube-controller-manager"
	},
	"spec": {
		"hostNetwork": true,
		"containers": [
		{
			"name": "kube-controller-manager",
			"image": "gcr.io/google_containers/kube-controller-manager:${KUBEVER}",
			"command": [
				"kube-controller-manager",
				"--logtostderr=true",
				"--v=0",
				"--master=http://${MASTERIP}:8080",
				"--cluster-cidr=10.253.0.0/16",
				"--service-cluster-ip-range=10.254.0.0/16",
				"--allocate-node-cidrs=true"
			],
			"volumeMounts": [
				{
					"name": "srvkube",
					"mountPath": "/srv/kubernetes",
					"readOnly": true
				}
			],
			"livenessProbe": {
				"httpGet": {
					"scheme": "HTTP",
					"host": "127.0.0.1",
					"port": 10252,
					"path": "/healthz"
				},
				"initialDelaySeconds": 15,
				"timeoutSeconds": 15
			}
		}
		],
		"volumes": [
		{
			"name": "srvkube",
			"hostPath": {
				"path": "/srv/kubernetes"
			}
		}
		]
	}
}
EOF

cat > ${ROOTFSPATH}/etc/kubernetes/manifests/scheduler.manifest << EOF
{
	"kind": "Pod",
	"apiVersion": "v1",
	"metadata": {
		"name": "kube-scheduler"
	},
	"spec": {
		"hostNetwork": true,
		"containers": [
		{
			"name": "kube-scheduler",
			"image": "gcr.io/google_containers/kube-scheduler:${KUBEVER}",
			"command": [
				"kube-scheduler",
				"--logtostderr=true",
				"--v=0",
				"--master=http://${MASTERIP}:8080"
			],
			"livenessProbe": {
				"httpGet": {
					"scheme": "HTTP",
					"host": "127.0.0.1",
					"port": 10251,
					"path": "/healthz"
				},
				"initialDelaySeconds": 15,
				"timeoutSeconds": 15
			}
		}
		]
	}
}
EOF
}

function buildk8senvironment {
echo "Build the kubernetes enviroment"
downloadk8sbinary
if [ ${TARGET} = "kubemaster" ]
then
copyk8smaster
createkubeletconfig
createmanifestsconfig
else
copyk8snode
createkubeletandkubeproxyconfig
fi
createloadimagesconfig
}
