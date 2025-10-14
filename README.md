# PDND Interop Infrastructure

## Introduction

This repository contains the Terraform implementation (on AWS) for the PDND Interop infrastructure.

About the project:

[PDND Interop landing page](https://interop.pagopa.it)

[Developer Portal](https://developer.pagopa.it/pdnd-interoperabilita/overview)

## Required tools

### Terraform version management

`tfenv` is used to manage Terraform versions using a version file located in `src/.terraform-version`.
You can also put multiple versions of that file in the subfolders (in case different states require different TF versions), and tfenv will read the closest one.

1. Install [tfenv](https://github.com/tfutils/tfenv)
2. Run:
```bash
cd src/
tfenv install # will read the version from .terraform-version
```

### VPN 

[AWS Client VPN](https://aws.amazon.com/vpn/client-vpn-download) is used to establish a VPN connection to the VPC, it supports both mutual authentication and SAML authentication.

The current code uses mutual authentication for non-production environments and SAML auth for production.
VPN credentials (used by mutual authentication) can be generated using `easyrsa3` as suggested by [AWS documentation](https://docs.aws.amazon.com/vpn/latest/clientvpn-admin/client-auth-mutual-enable.html).

### OpenAPI integration

Python 3.8+ is required to run the custom scripts that generate modified ("integrated") versions of the OpenAPI specifications found in `src/main/core/openapi`.
The output uses [OpenAPI extensions](https://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-swagger-extensions.html) to integrate API Gateway with the VPC Link.

### PostgreSQL

DB users are managed by a custom Terraform module that uses `psql` to run SQL statements.

### tf-summarize (optional)

[tf-summarize](https://github.com/dineshba/tf-summarize) is used in our Terraform wrapper script (see following sections) to prettify the TF plan output.

## Project structure

The code is currently organized into multiple Terraform states:

- `src/init` manages the Terraform backend resources necessary for the [remote state](https://developer.hashicorp.com/terraform/language/backend/s3).
- `src/main/core` manages the core AWS resources.
- `src/main/k8s` manages the internal Kubernetes resources.
- `src/main/analytics` manages the analytics resources (data warehouse).
- `src/main/analytics-quicksight` manages the Quicksight dashboards to visualize KPIs.

Each state has an `env/` folder that contains one subfolder (e.g. `env/dev/`) for each environment where the state needs to be deployed.
The environment subfolder contains the TF backend configuration and TF variables values for that specific environment.

We use a wrapper script `src/terrafrom.sh` (referenced by all states) to run Terraform commands on an environment with simplified syntax, for example:
```bash
cd src/main/core
./terraform.sh plan dev # will use ./env/dev/
```







