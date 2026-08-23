# Bitcoin Core Local Deployment & Observability Platform

A production-modeled, "one-click" local Kubernetes platform provisioning a synced Bitcoin Testnet node with declarative GitOps delivery (ArgoCD) and real-time observability (Prometheus & Grafana).

---

## 1. Architecture Overview

The platform uses a layered infrastructure-as-code and GitOps architecture:

1. **Bootstrap & Infrastructure Layer (Terraform)**: Deploys a multi-node KinD Kubernetes cluster along with core foundational controllers (`ingress-nginx`, `argo-cd`, `kube-prometheus-stack`).
2. **Delivery Layer (ArgoCD GitOps)**: Reconciles the target application manifests declaratively from Git.
3. **Application Layer (`base-workload` Helm Chart)**: A parameterized chart rendering hardened `StatefulSet` primitives, health probes, non-root security contexts, and headless service discovery.
4. **Observability Layer (Prometheus & Grafana)**: Zero-touch metric collection using Prometheus Operator `ServiceMonitor` CRDs and auto-provisioned Grafana dashboards.

```text
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
|                             |  | Prometheus & Grafana|  | Bitcoin Core Node  | |  |
|                             |  | (Auto-Provisioned)  |  | StatefulSet (HA)   | |  |
|                             |  +----------+----------+  | - bitcoind (27.0)  | |  |
|                             |             ^             | - exporter (8334)  | |  |
|                             |             |             +---------+----------+ |  |
|                             |             +-- ServiceMonitor -----+            |  |
|                             +--------------------------------------------------+  |
+-----------------------------------------------------------------------------------+
2. Platform Verification & Visual StatusGrafana Live Metrics DashboardAuto-provisioned under folder Blockchain->Bitcoin Node DashboardArgoCD GitOps Sync TopologyDeclarative state reconciliation of the bitcoin-nodeworkload3. Metrics ComplianceRequired MetricPrometheus SourceGrafana Panel RepresentationHighest Block Numberbitcoin_blocksSingle-stat card ( Synced Height ) displaying live chain tip (~2.86M+).Connected Peersbitcoin_peersSingle-stat threshold indicator showing active network peers ( 10 ).Metrics Over Time Graphbitcoin_blocksTime-series graph plotting continuous block sync progress.4. Key Design Decisions & Production ConsiderationsModular Reusable Chart ( base-workload) : Replaces hardcoded manifests with a generic, parameterized workload abstraction supporting both Deploymentand StatefulSettopologies.Storage-Constrained Optimization : Bitcoin testnet uses prune=1000(~1GB block limit) and txindex=0to preserve local disk resources while sustaining full block validation.Non-Root Pod Security Context : Enforces strict container isolation ( runAsUser: 1000, runAsNonRoot: true, privilege escalation disabled, and capabilities dropped to ALL).Resilient Startup & Readiness Probes : Executes bitcoin-cli getnetworkinfochecks with customized failure thresholds to prevent premature container restarts during chainstate verification.High Availability & Scheduling : Configured with podAntiAffinityrules to distribute multi-replica stateful instances across separate cluster worker nodes.Zero-Touch Observability : Eliminates manual dashboard imports by injecting providers directly via Helm values ​​into the Grafana container file system.5. PrerequisitesEnsure the following tools are installed locally:Docker Engine ( >= 24.0)KinD ( >= 0.23.0)Terraform ( >= 1.5.0)kubectl ( >= 1.28.0)Helm ( >= 3.12.0)Make & Curl6. Quickstart Execution1. Provision PlatformBashmake up
Initializes Terraform, creates the KinD multi-node cluster, deploys core ingress/monitoring controllers, registers the ArgoCD GitOps application, and waits for container readiness.2. Run Automated Verification SuiteBashmake verify
Runs end-to-end tests validating cluster topology, container statuses, RPC responses, exporter metric scraping endpoints, ArgoCD sync health, and Ingress routing.3. TeardownBashmake down
7. Endpoints & UI AccessAdd the following entries to /etc/hostsif local .localhostwildcard resolution is not enabled:Plaintext127.0.0.1 grafana.localhost argocd.localhost
ServiceAccess URLCredentialsPurposeGrafanahttp://grafana.localhostadmin/adminReal-time blockchain observabilityArgoCDhttp://argocd.localhost(Insecure / Single-Sign-On)Workload GitOps state engineBitcoin RPC127.0.0.1:8332(Secret Managed)Headless ClusterIP JSON-RPC endpoint8. Directory LayoutPlaintextplatform/
├── Makefile                     # Top-level platform commands (up, down, verify, lint)
├── README.md                    # System architecture documentation
├── .env.example                 # Sample environment variables
├── config/
│   ├── cluster.yaml             # KinD multi-node cluster topology
│   ├── ingress-values.yaml      # NGINX Ingress Controller Helm configuration
│   ├── argocd-values.yaml       # ArgoCD server and Ingress values
│   ├── monitoring-values.yaml   # Prometheus Operator & auto-provisioned dashboards
│   └── application-values.yaml  # Bitcoin node runtime configuration & resource specs
├── terraform/
│   ├── main.tf                  # Root IaC orchestrator
│   ├── variables.tf
│   ├── versions.tf
│   └── modules/                 # Sub-modules: kind, ingress, monitoring, argocd
├── charts/
│   └── base-workload/           # Generic parameterized Helm chart
│       ├── Chart.yaml
│       └── templates/           # StatefulSet, Service, ServiceMonitor, Probes
├── gitops/
│   └── application.yaml         # ArgoCD Application CRD declaration
└── scripts/
    ├── up.sh                    # End-to-end platform bootstrap
    ├── down.sh                  # Platform destruction
    └── verify.sh                # Test assertion harness