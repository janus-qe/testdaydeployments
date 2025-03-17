# Red Hat Developer Hub Deployment Repository for Test day deployments

This repository provides scripts and configuration files to deploy **Red Hat Developer Hub (RHDH)** on OpenShift using two different methods:
- **Helm Chart-based Installation**
- **Operator-based Installation**

## Repository Structure

```
|____helm
| |____rhdh-secrets.yaml               # Secrets template for Helm deployment
| |____helm-install.sh                 # Helm installation script
| |____value_file.yaml                 # Helm values file
| |____app-config-rhdh.yaml            # Application configuration
|____operator
| |____rhdh-secrets.yaml               # Secrets template for Operator deployment
| |____subscription.yaml               # RHDH Subscription manifest
| |____dynamic-plugins.yaml            # Dynamic plugins configuration
| |____op-install.sh                   # Operator installation script
| |____app-config-rhdh.yaml            # Application configuration
|____.env                              # Environment variables file
```

---

## Prerequisites

- Access to an **OpenShift Cluster**
- `oc` CLI installed and configured
- `helm` CLI installed
- Cluster-admin privileges
- `.env` file configured with required environment variables

---

## 1️⃣ Helm-based Installation

### Script:
`helm/helm-install.sh`

### Usage:

```bash
cd helm
./helm-install.sh --namespace=<namespace> --CV=<cv-version>
```

### Parameters:

| Parameter     | Description                                 | Example                |
|--------------|---------------------------------------------|-----------------------|
| `--namespace` | Target OpenShift project/namespace          | `rhdh`                |
| `--CV`        | Chart version of Developer Hub              | `1.5-171-CI`          |

### Steps Performed:

1. Creates or switches to the specified namespace.
2. Applies RHDH CI repository.
3. Configures cluster router base URL for RHDH.
4. Applies secrets (`rhdh-secrets.yaml`).
5. Creates configmap with app configuration (`app-config-rhdh.yaml`).
6. Installs or upgrades the Helm chart with values from `value_file.yaml`.

### Access:
Once deployed, Developer Hub will be accessible at:

```
https://redhat-developer-hub-<namespace>.<cluster-router-base>
```

---

## 2️⃣ Operator-based Installation

### Script:
`operator/op-install.sh`

### Usage:

```bash
cd operator
./op-install.sh --namespace=<namespace> --version=<version>
```

### Parameters:

| Parameter     | Description                                 | Example      |
|--------------|---------------------------------------------|-------------|
| `--namespace` | Target OpenShift project/namespace          | `rhdh`      |
| `--version`   | RHDH Operator release version               | `1.5`       |

### Steps Performed:

1. Creates or switches to the specified namespace.
2. Downloads and runs catalog source installation script.
3. Configures cluster router base URL for RHDH.
4. Applies secrets (`rhdh-secrets.yaml`).
5. Creates configmaps for app config (`app-config-rhdh.yaml`) and dynamic plugins (`dynamic-plugins.yaml`).
6. Waits for Backstage CRD creation.
7. Applies subscription manifest (`subscription.yaml`).

### Access:
Once deployed, Developer Hub will be accessible at:

```
https://backstage-developer-hub-<namespace>.<cluster-router-base>
```

---

## Configuration Files Overview:

| File                              | Description                                                           |
|-----------------------------------|-----------------------------------------------------------------------|
| `.env`                            | Contains shared environment variables                                 |
| `rhdh-secrets.yaml`               | Template for secrets, used by both Helm and Operator installations    |
| `app-config-rhdh.yaml`            | Developer Hub application configuration                               |
| `dynamic-plugins.yaml`            | Dynamic plugins configuration                                         |
| `subscription.yaml`               | Subscription manifest to install the RHDH Operator                    |
| `value_file.yaml`                 | Helm values configuration file                                       |

---

## Notes:

- Ensure the `.env` file contains all necessary environment variables before running the scripts.
- Both methods will configure the necessary secrets, configmaps, and resources automatically.
- For customizations, modify the respective `app-config-rhdh.yaml`, `value_file.yaml`, or `dynamic-plugins.yaml` files as needed.


