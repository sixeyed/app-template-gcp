# Docker Application Templates for Google Cloud Platform

A set of [Application Templates](https://blog.docker.com/2019/07/application-templates-docker-desktop-enterprise/) for deploying app's to GCP.

## Pre-requisites

1. A version of Docker Desktop Enterprise with Application Designer.

> The demo is a Linux app, so on Windows you need to use Linux container mode

2. A GCP project.

3. A Service Account in GCP, with access granted to your GCP project.

4. gcloud installed and initialized.

## Setup

Clone this repo:

```
git clone https://github.com/sixeyed/app-template-gcp.git

cd app-template-gcp
```

Pull the scaffolding images:

```
docker-compose pull
```

Copy `gcp-library.yaml` to somewhere useful:

```
cp gcp-library.yaml /tmp
```

Update your App Template config in `~/.docker/application-template/preferences.yaml` include the new library. 

This example includes the local demo library and the main Docker library:

```
apiVersion: v1alpha1
disableFeedback: false
kind: Preferences
repositories:
- name: gcp-library
  url: file:///tmp/gcp-library.yaml
- name: library
  url: https://docker-application-template.s3.amazonaws.com/production/v0.1.4/library.yaml
```
