# kubectl pod-topology

[![Kubernetes](https://img.shields.io/badge/Kubernetes-kubectl%20plugin-326CE5?logo=kubernetes&logoColor=white)](https://kubernetes.io/)
[![Python](https://img.shields.io/badge/Python-3.9%2B-3776AB?logo=python&logoColor=white)](https://www.python.org/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](#license)

A **kubectl plugin** that inspects your live Kubernetes cluster and renders a visual
traffic-flow diagram tracing the full request path:

```text
Internet  ──▶  Ingress  ──▶  Service  ──▶  Pod  (Running / Pending / Failed)
```

The result is a single PNG image generated via **Luma AI UNI-1**, complete with
per-pod health status badges.

---

## Table of contents

- [How it works](#how-it-works)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Configuration](#configuration)
- [Usage](#usage)
  - [Options](#options)
- [Example output](#example-output)
- [Demo manifest](#demo-manifest)
- [Project layout](#project-layout)
- [Troubleshooting](#troubleshooting)
- [License](#license)

---

## How it works

| Step | Stage | What happens |
| :---: | :--- | :--- |
| **1** | **Gather** | Runs `kubectl get ingresses`, `kubectl get services` and `kubectl get pods` against your cluster. |
| **2** | **Analyze** | Sends the resource data to OpenAI (`gpt-4o`), which maps Ingress rules to backend Services and Services to their selected Pods via label selectors, producing a structured traffic-flow summary. |
| **3** | **Generate** | Injects that summary into a hardcoded visual-style prompt and submits it to the Luma AI UNI-1 API, then downloads the rendered PNG. |

The visual prompt is **hardcoded on purpose** — it guarantees a consistent diagram
style on every run. Only the cluster-specific values change.

---

## Prerequisites

- **Python 3.9** or newer
- **`kubectl`** installed and configured with a valid kubeconfig
- An **OpenAI API key** — used for cluster analysis (`gpt-4o`)
- A **Luma AI API key** — used for image generation (UNI-1)

---

## Installation

```bash
# 1. Clone the repository and enter it
git clone git@github.com:Preetam-3/TASK_4.git
cd pod-topology-image-generator

# 2. Run the installer (installs the plugin + Python dependencies)
./install.sh
```

The installer will:

- Copy `kubectl-pod_topology` to `/usr/local/bin` — falling back to `~/bin`
  if `/usr/local/bin` is not writable
- Install both the `kubectl-pod-topology` and legacy `kubectl-pod_topology` names
- Run `pip install -r requirements.txt`
- Create a `.env` file from `.env.example` if none exists yet
- Warn you if the install directory is missing from `PATH`

---

## Configuration

Copy the example environment file and fill in your keys:

```bash
cp .env.example .env.local
```

Then edit `.env.local`:

```dotenv
OPENAI_API_KEY=sk-...
LUMA_API_KEY=luma-...
# Optional alias, also accepted by the plugin:
# LUMA_API_TOKEN=luma-...
```

The plugin loads environment files in this order (first match wins), checking the
**current working directory** first, then the **plugin directory**:

1. `.env.local`
2. `.env`

Both files are covered by `.gitignore`, so your keys are never committed.

---

## Usage

```bash
# Basic: generate a topology for a pod in a namespace
kubectl pod-topology <pod-name> -n <namespace>

# Choose an explicit output path
kubectl pod-topology nginx-topology-65b47b4648-4nktm -n default -o /tmp/staging-topology.png

# Prefix matching — no need to type the full generated pod name
kubectl pod-topology nginx-topology -n default

# Inspect every namespace at once
kubectl pod-topology nginx-topology -n all
```

> **Note:** the plugin is also installed as `kubectl-pod_topology` for
> backward compatibility, and can be run directly without kubectl.

### Options

| Flag | Short | Default | Description |
| :--- | :---: | :--- | :--- |
| `pod_name` | — | *required* | Target pod name (exact name or prefix). |
| `--namespace` | `-n` | `default` | Namespace to inspect. Use `all` for all namespaces. |
| `--output` | `-o` | `pod-topology.png` | Output path for the generated PNG image. |

---

## Example output

The generated diagram is a wide 16:9 banner on a dark navy background containing:

- A **globe** on the left representing external internet traffic
- **Ingress** resources (teal) with their hostnames and TLS status
- **Services** (blue) with their exposed ports
- **Pods** on the right, each with a colour-coded status badge:

| Badge | Pod status |
| :---: | :--- |
| 🟢 Green | `Running` |
| 🟡 Yellow | `Pending` |
| 🔴 Red | `Failed` |
| 🔴 Bright red | `CrashLoopBackOff` |
| ⚪ Grey | `Unknown` |

---

## Demo manifest

The repo ships with `nginx-topology.yaml`, a self-contained sample that creates a
Deployment, Service and Ingress — handy for testing the plugin end to end:

```bash
kubectl apply -f nginx-topology.yaml
kubectl pod-topology nginx-topology -n default
```

---

## Project layout

```text
.
├── kubectl-pod_topology    # The plugin (Python)
├── install.sh              # Installer
├── nginx-topology.yaml     # Demo Deployment + Service + Ingress
├── requirements.txt        # Python dependencies
├── .env.example            # Template for API keys
└── README.md
```

---

## Troubleshooting

| Problem | Fix |
| :--- | :--- |
| `kubectl: command not found` or a plugin error | Ensure the install directory is on your `PATH`, then restart your shell. |
| `Missing API key` error on startup | Create `.env.local` (or `.env`) with `OPENAI_API_KEY` and `LUMA_API_KEY`. |
| `No resources found` warning | Confirm your kubeconfig context and that the pod name / namespace are correct. |
| `kubectl pod-topology` not recognised | Re-run `./install.sh` and verify `kubectl plugin list` shows the plugin. |

---

## License

Released under the **MIT License**.
