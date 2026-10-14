# SRE / DevOps Intern Take-Home Assessment

My submission for the three technical tests. Each folder has its own README with the
reasoning behind my choices, setup steps, evidence and what I would improve.

| Test | What I built | Environment |
|---|---|---|
| [**Test 1: Monitoring**](test-1-monitoring/) | Logs and metrics stack (Grafana Alloy, Loki, Prometheus, Grafana), 3 dashboards and 3 alerts, all as code and rebuildable with one script | Local 3-node **kind** cluster |
| [**Test 2: Automation**](test-2-automation/) | Terraform for a VNet, subnets, NSGs and two Ubuntu 22.04 VMs; Ansible to configure them | **Azure**, deployed, tested, then destroyed |
| [**Test 3: Troubleshooting**](test-3-troubleshooting/) | Answer to Scenario 1, with the Kubernetes failures reproduced on a local cluster | Written answer + lab |

## Highlights

- **Everything as code:** alerts are `PrometheusRule` resources, dashboards are JSON
  files, and `test-1-monitoring/install.sh` rebuilds the full monitoring stack.
- **Every alert was proven to fire** using test workloads (crash loop, CPU burner,
  memory hog).
- **Real Azure deployment:** NSG rules were verified with Azure Network Watcher, and
  the Ansible playbook was shown to be idempotent.
- **Honest notes:** each README has a "Problems I hit" section explaining what went
  wrong and how I fixed it.

## Azure

Azure-specific choices are marked in each README, including: AKS-relevant monitoring
decisions (Test 1), NSG default rules and Network Watcher (Test 2), and AKS networking
causes such as NSGs and Load Balancer health probes (Test 3).

## Tools Used

Docker Desktop with WSL2 (Ubuntu), kind, kubectl, Helm, Terraform, Azure CLI, Ansible.

## Security

No passwords, keys or credentials are committed. Sensitive values are passed as
environment variables or generated at run time, and state files, `.tfvars` files and
generated inventories are git-ignored.
