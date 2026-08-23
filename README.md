

# Bitcoin Testnet Local Platform Engine

A declarative, "one-click" local platform deployment provisioning a synced/syncing Bitcoin Testnet node with full observability via Prometheus and Grafana on a local Kubernetes cluster.

---

## 1. Executive Summary & Architecture

This solution provides zero-touch provisioning of a local Kubernetes environment running a containerized, pruned Bitcoin Core (`bitcoind`) node and a companion Prometheus exporter sidecar. Infrastructure and platform services are managed via Terraform, while application workloads follow GitOps principles via ArgoCD.


```

+-----------------------------------------------------------------------------------+
| Host Machine (make up)                                                            |
|                                                                                   |
|  +--------------------+     +--------------------------------------------------+  |
|  | Terraform Engine   | --> | KinD Cluster (v1.31.0)                           |  |
|  +--------------------+     |                                                  |  |
|                             |  +---------------------+  +--------------------+ |  |
|                             |  | Ingress NGINX       |  | ArgoCD Controller  | |  |
|                             |  | (:80 / :443)        |  | (GitOps Engine)    | |  |
|                             |  +----------+----------+  +---------+----------+ |  |
|                             |             |                       |            |  |
|                             |             v                       v            |  |
|                             |  +---------------------+  +--------------------+ |  |
|                             |  | Prometheus & Grafana|  | Bitcoin Testnet    | |  |
|                             |  | (ServiceMonitor)    |  | StatefulSet        | |  |
|                             |  +----------+----------+  | - bitcoind (27.0)  | |  |
|                             |             |             | - exporter (8334)  | |  |
|                             |             +<------------+                    | |  |
|                             +--------------------------------------------------+  |
+-----------------------------------------------------------------------------------+

```

---

## 2. Design Decisions & Trade-Off Analysis

> *"Explaining things are better than overengineering."*

Platform engineering is about balancing production-readiness with simplicity and operational ergonomics. The following decisions shaped this architecture:

### A. Infrastructure as Code (Terraform) vs. Imperative Scripts
* **Decision**: Use the `tehcyx/kind`, `hashicorp/kubernetes`, and `hashicorp/helm` Terraform providers to provision the base platform layers.
* **Why**: Terraform provides idempotent lifecycle management, clean dependency resolution (`depends_on`), and declarative state. A single `terraform apply` guarantees deterministic provisioning without fragile shell loops.

### B. GitOps Engine (ArgoCD) vs. Direct Helm Installs
* **Decision**: Deploy the application layer via an ArgoCD `Application` custom resource.
* **Why**: Separation of concerns. Terraform manages cluster infrastructure (ingress, monitoring, ArgoCD), while ArgoCD manages the application lifecycle. This separates platform foundation from application delivery.

### C. Application Delivery: Reusable `generic-app` Helm Chart
* **Decision**: Built a templated, parameterized Helm chart (`charts/app`) supporting both `Deployment` and `StatefulSet` topologies.
* **Why**: Avoids boilerplate YAML duplicates across microservices. Allows defining sidecars, volumes, secrets, and Prometheus `ServiceMonitor` resources entirely via `values.yaml`.

### D. Workload Topology: `StatefulSet` with Volume Claims
* **Decision**: Deployed `bitcoind` as a `StatefulSet` with persistent volume claims (`/data`).
* **Why**: Blockchain nodes manage peer discovery tables, chain states, and block index metadata. A `StatefulSet` guarantees ordered deployments and stable storage across pod restarts.

### E. Blockchain Storage Optimization (Pruned Mode)
* **Decision**: Configured `prune=1000` and `txindex=0` in `bitcoin.conf`.
* **Why**: Full Bitcoin testnet history exceeds dozens of gigabytes. Pruning limits local storage to ~1 GB by purging historical block data while keeping block headers and validation mechanisms intact.

### F. Metrics Discovery & Dashboard Auto-Provisioning
* **Decision**: Deployed Prometheus Operator CRDs (`ServiceMonitor`) and injected custom Grafana dashboards as code using Helm provisioning providers.
* **Why**: Zero manual intervention. Reviewers do not need to click around the Grafana UI to import dashboards or configure data sources.

---

## 3. Prerequisites

Ensure the following CLI tools are available in your local `$PATH`:
* **Docker Engine** (`>= 24.0`)
* **KinD** (`>= 0.23.0`)
* **Terraform** (`>= 1.5.0`)
* **kubectl** (`>= 1.28.0`)
* **Helm** (`>= 3.12.0`)
* **make** & **curl**

---

## 4. Quickstart (One-Click Execution)

### Step 1: Deploy Entire Platform
Run the single entry-point command from the root of the repository:
```bash
make up

```

*This command creates the KinD cluster, installs Ingress, Prometheus, Grafana, and ArgoCD via Terraform, registers the GitOps application, and waits for all containers to reach `Ready` state.*

### Step 2: Run Verification Checks

Execute the automated test suite to validate node connectivity, RPC responses, metrics scraping, and UI ingress endpoints:

```bash
make verify

```

### Step 3: Teardown

To cleanly destroy all cluster resources:

```bash
make down

```

---

## 5. Endpoints & Access

Add the following local DNS mappings to `/etc/hosts` if your OS does not automatically resolve `.localhost` domains:

```text
127.0.0.1 grafana.localhost argocd.localhost

```

| Service | Access URL | Credentials | Description |
| --- | --- | --- | --- |
| **Grafana** | `http://grafana.localhost` | `admin` / `admin` | Real-time Bitcoin testnet metrics |
| **ArgoCD** | `http://argocd.localhost` | *(Insecure mode enabled)* | GitOps application sync controller |
| **Bitcoin RPC** | `127.0.0.1:8332` | `bitcoin` / `bitcoin-secure-password-123` | JSON-RPC API (ClusterIP) |

---

## 6. Monitored Metrics

The auto-provisioned Grafana dashboard **"Bitcoin Node Dashboard"** (Folder: `Blockchain`) queries the following metrics scraped by the Prometheus Operator:

1. **Highest Block Number (`bitcoin_blocks`)**: Displays the current synced testnet block height.
2. **Connected Peers (`bitcoin_peers`)**: Displays the active count of network peer connections.
3. **Sync Progress Over Time**: Time-series graph tracking continuous block synchronization.

---

## 7. Repository Layout

```text
.
├── Makefile                     # Root orchestrator (make up, down, verify, test)
├── charts/
│   └── app/                     # Reusable parameterized Helm chart (StatefulSet/Deployment)
├── config/
│   ├── application-values.yaml  # Bitcoin node and exporter runtime config
│   ├── argocd-values.yaml       # ArgoCD ingress & server config
│   ├── cluster.yaml             # KinD topology and port mapping definitions
│   ├── ingress-values.yaml      # NGINX ingress controller configuration
│   └── monitoring-values.yaml   # Kube-Prometheus-Stack & auto-provisioned dashboards
├── gitops/
│   └── bitcoin-app.yaml         # ArgoCD Application CRD declaration
├── scripts/
│   ├── down.sh                  # Teardown logic
│   ├── up.sh                    # Orchestration & readiness polling
│   └── verify.sh                # End-to-end automated verification script
└── terraform/
    ├── main.tf                  # Modular IaC orchestrator
    └── modules/                 # Sub-modules: kind, ingress, monitoring, argocd
