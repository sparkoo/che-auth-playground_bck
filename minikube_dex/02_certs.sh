#!/bin/bash

set -x

MINIKUBE_DOMAIN=$( minikube ip ).nip.io

rm -rf ssl && mkdir -p ssl


## generate certs
cat << EOF > ssl/req.cnf
[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name

[req_distinguished_name]

[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = dex.${MINIKUBE_DOMAIN}
EOF

openssl genrsa -out ssl/ca-key.pem 2048
openssl req -x509 -new -nodes -key ssl/ca-key.pem -days 10 -out ssl/ca.pem -subj "/CN=kube-ca"

openssl genrsa -out ssl/key.pem 2048
openssl req -new -key ssl/key.pem -out ssl/csr.pem -subj "/CN=kube-ca" -config ssl/req.cnf
openssl x509 -req -in ssl/csr.pem -CA ssl/ca.pem -CAkey ssl/ca-key.pem -CAcreateserial -out ssl/cert.pem -days 10 -extensions v3_req -extfile ssl/req.cnf


## copy certs so minikube can see it
mkdir -p ~/.minikube/files/etc/ca-certificates/
cp ssl/ca.pem ~/.minikube/files/etc/ca-certificates/openid-ca.pem

set +x

echo
echo "Action item ===> Import 'ssl/ca.pem' into your browser <==="
echo