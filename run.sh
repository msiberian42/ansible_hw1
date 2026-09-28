#!/usr/bin/env bash

set -e

# Образы
UBUNTU_IMAGE="ubuntu:latest"
FEDORA_IMAGE="fedora:latest"
CENTOS_IMAGE="rockylinux:9"

CONTAINERS=("centos7" "ubuntu" "fedora")

cleanup() {
    echo
    echo "Stopping and removing containers..."

    for container in "${CONTAINERS[@]}"; do
        docker rm -f "$container" >/dev/null 2>&1 || true
    done 
}

trap cleanup EXIT

echo "Pulling Docker images..."

docker pull "$UBUNTU_IMAGE"
docker pull "$FEDORA_IMAGE"
docker pull "$CENTOS_IMAGE"

echo "Creating containers..."

docker rm -f centos7 ubuntu fedora >/dev/null 2>&1 || true

docker run -d \
    --name centos7 \
    "$CENTOS_IMAGE" \
    tail -f /dev/null

docker run -d \
    --name ubuntu \
    "$UBUNTU_IMAGE" \
    tail -f /dev/null

docker run -d \
    --name fedora \
    "$FEDORA_IMAGE" \
    tail -f /dev/null

echo "Containers started:" 

docker ps --filter "name=centos7" \
    --filter "name=ubuntu" \
    --filter "name=fedora"

docker exec centos7 mkdir -p /tmp/.ansible/tmp
docker exec ubuntu mkdir -p /tmp/.ansible/tmp
docker exec fedora mkdir -p /tmp/.ansible/tmp

echo "Installing Python..."

docker exec ubuntu bash -c \
    "apt-get update && apt-get install -y python3"

docker exec fedora bash -c \
    "dnf install -y python3"

echo "Running Ansible playbook..."

cd playbook/

ansible-playbook \
    -i inventory/prod.yml \
    site.yml \
    --ask-vault-pass
    
echo "Done"