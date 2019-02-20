#!/bin/bash

set -e 

sudo apt-get update
sudo apt-get -y install curl

# sudo touch /etc/apt/sources.list.d/gitlab-runner.list

curl -L https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.deb.sh | sudo bash

sudo apt-get -y install gitlab-runner

gitlab-runner --version
