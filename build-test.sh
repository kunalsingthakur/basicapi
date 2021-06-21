#! /bin/bash
docker_username=$1
set -xe

curl -sL https://kind.sigs.k8s.io/dl/v0.11.1/kind-linux-amd64 -o /usr/local/bin/kind
chmod 755 /usr/local/bin//kind

curl -sL https://storage.googleapis.com/kubernetes-release/release/v1.21.1/bin/linux/amd64/kubectl -o /usr/local/bin/kubectl
chmod 755 /usr/local/bin//kubectl

curl -LO https://get.helm.sh/helm-v3.1.2-linux-amd64.tar.gz
tar -xzf helm-v3.1.2-linux-amd64.tar.gz
mv linux-amd64/helm /usr/local/bin/
rm -rf helm-v3.1.2-linux-amd64.tar.gz

kind version
kubectl version --client=true
helm version

kind create cluster --wait 10m --config kind-config.yaml

kubectl get nodes

docker build -t $docker_username/basicapi:dev .
kind load docker-image $docker_username/basicapi:dev

kubectl apply -f basicapi-deployment.yaml
kubectl apply -f basicapi-service.yaml

NODE_IP=$(kubectl get node -o wide|tail -1|awk {'print $6'})
NODE_PORT=$(kubectl get svc basicapi-service -o go-template='{{range.spec.ports}}{{if .nodePort}}{{.nodePort}}{{"\n"}}{{end}}{{end}}')
sleep 60
NODE_IP=$(kubectl get node -o wide|tail -1|awk {'print $6'})
NODE_PORT=$(kubectl get svc basicapi-service -o go-template='{{range.spec.ports}}{{if .nodePort}}{{.nodePort}}{{"\n"}}{{end}}{{end}}')
SUCCESS=$(curl --write-out '%{http_code}' --silent --output /dev/null $NODE_IP:$NODE_PORT)
if [[ "${SUCCESS}" != "200" ]];
then
  kind -q delete cluster
  exit 1;
else
 kind -q delete cluster
 echo "Component test succesful"
fi

