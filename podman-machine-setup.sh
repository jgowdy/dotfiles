#!/bin/bash


podman machine stop podman-machine-default
sleep 5
podman machine rm --force podman-machine-default 
podman machine init --cpus 4 --disk-size 128 --memory 4096 podman-machine-default
podman machine start podman-machine-default
sleep 5
podman machine ssh podman-machine-default sudo sed -i 's/enforcing/permissive/' /etc/containers/registries.conf
podman machine ssh podman-machine-default sudo rpm-ostree install qemu-user-static kitty-terminfo
podman machine ssh podman-machine-default sudo systemctl reboot



