# Scenario 1: Pods Running but Application Unreachable

## Most likely root cause

The pods are Running and the code hasn't changed, so the problem is likely on the path between the user and the pods:

```text
User → Azure Load Balancer → (Ingress) → Service → Endpoints → Pods
```

Most likely causes, in order:

1. The Service has **no endpoints**: its selector doesn't match the pod labels, or pods are Running but not Ready.
2. The Service `targetPort` doesn't match the container port.
3. An **Azure network issue** (NSG, Load Balancer probe) is dropping traffic.

A **timeout** (not "connection refused") means packets are being silently dropped, which points towards NSGs or the Load Balancer.

## 1. First 3 kubectl commands

```bash
kubectl get svc,ingress -n <ns> -o wide                                  # type, external IP, selector
kubectl get endpointslices -n <ns> -l kubernetes.io/service-name=<svc>   # is the Service connected to pods?
kubectl describe svc <svc> -n <ns>                                       # selector, ports, Azure LB events
```

- Empty endpoints = problem is inside Kubernetes (selector, labels, readiness).
- Endpoints present = check ports, Ingress, then Azure.
- Also check `kubectl get pods --show-labels` and the READY column, not just STATUS.

## 2. Which resource first

**Service first**, then Ingress, then NSG. The Deployment is already shown healthy by `Running`.

- A wrong selector fails silently, and checking endpoints takes seconds.
- Ingress next: host/path rules, ingress class, backend service and port.
- NSG last because it is outside Kubernetes, but it becomes the main suspect if everything inside the cluster checks out.

## 3. Pod vs Service vs Ingress/network

Test from the inside out. The first layer that fails is the problem.

| Level | Test |
|---|---|
| Pod | `kubectl port-forward pod/<pod> 8080:<port>` then `curl localhost:8080` |
| Service | From a debug pod: `kubectl exec debug -- wget -qO- -T 3 http://<svc>.<ns>.svc.cluster.local` |
| Ingress | From the debug pod, call the ingress controller with the correct `Host` header |
| Network | `curl -v http://<external-ip>` from outside, plus Network Watcher IP flow verify |

If it works inside the cluster but not from outside, the problem is in Azure.

**Lab:** I reproduced two failures on kind ([screenshots](screenshots/)):

- **Selector mismatch:** pods Running, no endpoints, requests fail.
- **Wrong targetPort:** endpoints present, requests still fail.

## 4. Two Azure-specific causes

1. **NSG blocking traffic:** a custom NSG on the node subnet denies inbound 80/443. NSG denies drop packets, causing a timeout.
   Fix: add an allow rule for TCP 80/443 from the expected sources.
2. **Load Balancer health probe failing:** if no node passes the probe, the Load Balancer drops all traffic. Often the probe path (e.g. `/`) doesn't return 200.
   Fix: set `service.beta.kubernetes.io/azure-load-balancer-health-probe-request-path` to a real health endpoint.

Others: a route table sending traffic through Azure Firewall (asymmetric routing), or `loadBalancerSourceRanges` limiting access.

## Fix

- Correct the selector/labels or the readiness probe.
- Match `targetPort` to the container port (named ports prevent this).
- Fix Ingress rules, the NSG rule, or the health probe as needed.
- **Prevent it:** alert on Services with zero endpoints, and add an external check that calls the public URL every minute.
