# PrimaLabs DevOps Assignment

## Objectives

The objective of this project was to build a production-oriented local DevOps platform for deploying and operating a containerized FastAPI application using modern Infrastructure as Code (IaC), Kubernetes, observability, and CI practices.

The implementation focuses on reproducibility, automation, security, and operational best practices while remaining completely local, without relying on any public cloud infrastructure.

### Project Goals

The project was designed to achieve the following objectives:

- Build a **production-ready Docker image** using a multi-stage build, pinned base image, non-root user, Docker HEALTHCHECK, and optimized layer caching.
- Provision the local infrastructure declaratively using **Terraform**, leveraging the Kind, Kubernetes, and Helm providers.
- Deploy the application on a **Kind Kubernetes cluster** using production-shaped Kubernetes manifests.
- Configure **Horizontal Pod Autoscaling (HPA)**, **Pod Disruption Budget (PDB)**, and **ServiceMonitor** to improve scalability, availability, and observability.
- Deploy a complete monitoring stack consisting of **Prometheus**, **Grafana**, **Alertmanager**, and **Metrics Server** using the `kube-prometheus-stack` Helm chart.
- Implement **Dashboard as Code** by storing Grafana dashboards within the repository to ensure monitoring configuration remains version-controlled.
- Build a **GitHub Actions Continuous Integration (CI)** pipeline that automatically validates Terraform, builds the Docker image, performs vulnerability scanning using **Trivy**, and generates a **CycloneDX Software Bill of Materials (SBOM)** on every Pull Request and push.
- Follow clean Git workflows using **feature branches**, **Pull Requests**, **conventional commits**, and **tagged releases**.
- Keep every component reproducible so that another engineer can clone the repository and recreate the complete environment with minimal manual effort.

### Scope

This repository intentionally focuses on **Continuous Integration (CI)** rather than Continuous Deployment (CD).

Infrastructure provisioning and Kubernetes application deployment remain manual steps using:

- `terraform apply`
- `kubectl apply -f kubernetes/`

This separation keeps infrastructure changes explicit while demonstrating a production-style CI pipeline. A GitOps-based Continuous Deployment implementation using **Argo CD** is discussed later under **Future Improvements**.

# System Architecture

The project follows a layered DevOps architecture where infrastructure provisioning, application deployment, observability, and Continuous Integration are intentionally separated into independent responsibilities.

The complete platform is fully reproducible on a local machine using **Kind**, **Terraform**, **Helm**, and **Kubernetes**, without requiring any public cloud infrastructure.

The following diagram illustrates the complete end-to-end workflow implemented in this repository.

<img width="1536" height="1024" alt="arch-diagram-2" src="https://github.com/user-attachments/assets/7a317451-2d18-4fd1-bd96-932101600511" />


---

## Architecture Walkthrough

The platform can be understood as five independent layers that work together to provision, deploy, monitor, and validate the application.

### 1. Source Control & Continuous Integration

The lifecycle begins when a developer pushes code to GitHub or opens a Pull Request.

Every push to the `main` branch and every Pull Request automatically triggers the GitHub Actions workflow.

Unlike a traditional CI/CD pipeline, this project intentionally implements **Continuous Integration (CI)** only. No infrastructure changes or application deployments are performed automatically.

The CI workflow executes the following validation stages:

- Terraform formatting validation (`terraform fmt -check`)
- Terraform configuration validation (`terraform validate`)
- Docker image build
- Trivy container vulnerability scan
- CycloneDX Software Bill of Materials (SBOM) generation

At the end of the workflow GitHub produces:

- A validated Infrastructure as Code configuration.
- A successfully built Docker image.
- A container vulnerability scan report.
- A Software Bill of Materials (SBOM) artifact.

This ensures that every commit is validated before infrastructure changes are applied.

---

### 2. Infrastructure Provisioning

Infrastructure provisioning is performed manually using Terraform.

```bash
terraform init
terraform plan
terraform apply
```

Terraform acts as the infrastructure provisioning layer and communicates directly with the local Kubernetes cluster through the Kubernetes and Helm providers.

Running Terraform provisions the platform components required by the application.

Resources created by Terraform include:

| Component | Purpose |
|----------|---------|
| Kubernetes Namespace | Logical isolation of project resources |
| Metrics Server | Provides CPU and memory metrics required by the Horizontal Pod Autoscaler |
| kube-prometheus-stack | Installs the complete monitoring platform using Helm |
| Prometheus | Collects and stores application metrics |
| Grafana | Visualizes metrics through dashboards |
| Alertmanager | Receives alerts from Prometheus (ready for future alert rules) |
| Node Exporter | Collects host-level metrics |
| kube-state-metrics | Exposes Kubernetes object metrics |

Terraform provisions the platform only.

It intentionally **does not deploy the application**, allowing infrastructure and application deployments to remain independent.

---

### 3. Kubernetes Application Deployment

After the platform has been provisioned, the application is deployed using Kubernetes manifests.

```bash
kubectl apply -f kubernetes/
```

The following production-oriented Kubernetes resources are created.

| Resource | Responsibility |
|----------|----------------|
| Deployment | Runs the FastAPI application |
| Service | Exposes Pods internally using ClusterIP |
| Horizontal Pod Autoscaler | Automatically scales Pods based on CPU utilization |
| Pod Disruption Budget | Maintains application availability during voluntary disruptions |
| ServiceMonitor | Enables Prometheus Operator to discover and scrape application metrics |

The Deployment itself incorporates several production best practices including:

- Rolling Updates
- Startup Probes
- Readiness Probes
- Liveness Probes
- Resource Requests
- Resource Limits
- Non-root container execution
- Linux capability dropping
- Security Context configuration

Together these configurations ensure the application remains secure, resilient, and production-ready.

---

### 4. Metrics Collection & Observability

Once the application is deployed, Prometheus automatically begins collecting metrics.

The metrics flow implemented in this project is:

```
FastAPI Application
        │
        ▼
Kubernetes Service
        │
        ▼
ServiceMonitor
        │
        ▼
Prometheus
        │
        ▼
Grafana Dashboard
```

The FastAPI application exposes Prometheus metrics through the `/metrics` endpoint.

The Prometheus Operator continuously watches the cluster for `ServiceMonitor` resources.

Once the `ServiceMonitor` is created, Prometheus automatically discovers the Kubernetes Service and begins scraping metrics without requiring any manual Prometheus configuration.

Collected metrics are stored in Prometheus and visualized through Grafana dashboards.

The dashboard implemented in this project includes:

- Total Requests
- Requests per Second (RPS)
- P95 Response Time
- CPU Usage
- Memory Usage
- Request Distribution by Endpoint

This provides a single operational view of application health.

---

### 5. Continuous Integration Workflow

Continuous Integration is implemented using GitHub Actions.

The workflow executes automatically for every Pull Request and push to the `main` branch.

The pipeline validates both infrastructure and application changes before they can be merged.

The implemented workflow performs the following stages:

1. Checkout Repository
2. Terraform Format Check
3. Terraform Validation
4. Docker Image Build
5. Trivy Vulnerability Scan
6. CycloneDX SBOM Generation
7. Upload SBOM Artifact

This pipeline intentionally stops after validation.

Infrastructure deployment remains a manual operation.

This separation keeps validation independent from deployment and mirrors environments where infrastructure changes require manual approval.

---

## End-to-End Flow

The complete workflow implemented in this repository can be summarized as follows:

```
Developer
      │
git push / Pull Request
      │
      ▼
GitHub Actions
      │
      ├── terraform fmt -check
      ├── terraform validate
      ├── docker build
      ├── Trivy Scan
      └── Generate SBOM
              │
              ▼
      Manual Deployment
      │
      ├── terraform apply
      └── kubectl apply -f kubernetes/
              │
              ▼
Kind Kubernetes Cluster
      │
      ├── Monitoring Stack
      │      ├── Prometheus
      │      ├── Grafana
      │      ├── Alertmanager
      │      └── Metrics Server
      │
      └── FastAPI Application
              │
              ▼
Prometheus scrapes /metrics
              │
              ▼
Grafana visualizes service health
```

This separation of **CI**, **Infrastructure Provisioning**, **Application Deployment**, and **Observability** keeps each layer independently reproducible, easier to maintain, and closely aligned with production DevOps practices.



## End-to-End Workflow

The project follows a layered workflow where each stage has a clearly defined responsibility. Infrastructure provisioning, application deployment, monitoring, and Continuous Integration remain independent, making the platform easier to understand, maintain, and reproduce.

### Step 1 – Source Control

Development begins with a Git commit followed by a push to GitHub or the creation of a Pull Request.

```
Developer
    │
git push / Pull Request
```

---

### Step 2 – Continuous Integration

GitHub Actions automatically validates every change by executing the following pipeline:

```
GitHub Actions
    │
    ├── terraform fmt -check
    ├── terraform validate
    ├── docker build
    ├── Trivy vulnerability scan
    └── Generate CycloneDX SBOM
```

At this stage, the workflow **only validates and builds** the project. No infrastructure or application deployment occurs.

---

### Step 3 – Infrastructure Provisioning

Infrastructure is provisioned manually using Terraform.

```
terraform apply
        │
        ▼
Terraform
        │
        ├── Namespace
        ├── Metrics Server
        └── kube-prometheus-stack
```

This creates the Kubernetes platform and monitoring components required to run the application.

---

### Step 4 – Application Deployment

Once the infrastructure is available, the application is deployed using Kubernetes manifests.

```
kubectl apply -f kubernetes/
        │
        ▼
Deployment
Service
HPA
PDB
ServiceMonitor
```

The application is now running inside the Kind Kubernetes cluster.

---

### Step 5 – Monitoring & Observability

The deployed application exposes metrics through the `/metrics` endpoint.

```
FastAPI
    │
    ▼
Service
    │
    ▼
ServiceMonitor
    │
    ▼
Prometheus
    │
    ▼
Grafana
```

Prometheus automatically discovers the application through the `ServiceMonitor` resource and continuously scrapes metrics, which are visualized in Grafana dashboards.

---

### Summary

```
Developer
      │
      ▼
GitHub Actions (CI)
      │
      ▼
terraform apply
      │
      ▼
kubectl apply -f kubernetes/
      │
      ▼
FastAPI Application
      │
      ▼
Prometheus
      │
      ▼
Grafana Dashboard
```

This separation between **CI**, **Infrastructure Provisioning**, **Application Deployment**, and **Observability** keeps the platform modular, reproducible, and aligned with production DevOps practices.


# Repository Structure

The repository is organized to separate infrastructure provisioning, Kubernetes resources, monitoring configuration, and Continuous Integration. Each directory has a single responsibility, making the project easier to understand, maintain, and extend.

```text
primalabs-devops-assignment
├── .github/
│   └── workflows/
│       └── ci.yml
│
├── app/
│   ├── app.py
│   └── requirements.txt
│
├── Dockerfile
│
├── grafana/
│   ├── dashboards/
│   │   └── app-dashboard.json
│   └── provisioning/
│
├── kubernetes/
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── hpa.yaml
│   ├── pdb.yaml
│   └── servicemonitor.yaml
│
├── terraform/
│   ├── monitoring/
│   ├── providers.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── main.tf
│
├── Dockerfile
├── .dockerignore
└── README.md
```

## Directory Overview

| Directory / File | Purpose |
|------------------|---------|
| `.github/workflows/` | Contains the GitHub Actions Continuous Integration workflow responsible for Terraform validation, Docker image build, Trivy vulnerability scanning, and SBOM generation. |
| `app/` | Contains the FastAPI application source code and Python dependencies. The application exposes `/`, `/health`, `/work`, and `/metrics` endpoints. |
| `grafana/` | Stores Grafana dashboards and provisioning configuration as code, allowing monitoring resources to be version controlled. |
| `kubernetes/` | Contains all Kubernetes manifests required to deploy the application, including Deployment, Service, HPA, PDB, and ServiceMonitor resources. |
| `terraform/` | Defines the Infrastructure as Code used to provision the Kubernetes platform and monitoring stack using the Kubernetes and Helm providers. |
| `Dockerfile` | Defines the production container image using a multi-stage build and hardened runtime configuration. |
| `.dockerignore` | Reduces Docker build context and improves build performance by excluding unnecessary files. |
| `README.md` | Primary project documentation describing architecture, deployment, monitoring, and design decisions. |

## Project Organization

The repository follows a layered structure where each technology is isolated into its own directory:

- **Application** (`app/`) contains only the FastAPI service.
- **Infrastructure** (`terraform/`) provisions the Kubernetes platform and monitoring stack.
- **Deployment** (`kubernetes/`) defines how the application runs inside Kubernetes.
- **Observability** (`grafana/`) stores dashboards and provisioning configuration.
- **Automation** (`.github/workflows/`) contains the CI pipeline responsible for validating every change before deployment.

This separation keeps concerns isolated, simplifies maintenance, and allows each layer to evolve independently without impacting the others.

# Technology Stack

| Category | Technology |
|----------|------------|
| Programming Language | Python 3.12 |
| Application Framework | FastAPI |
| Containerization | Docker |
| Container Orchestration | Kubernetes (Kind) |
| Infrastructure as Code | Terraform |
| Package Manager | Helm |
| Monitoring | Prometheus |
| Visualization | Grafana |
| Autoscaling | Kubernetes HPA + Metrics Server |
| Continuous Integration | GitHub Actions |
| Security | Trivy |
| SBOM | CycloneDX |
| Version Control | Git & GitHub |

---

# Prerequisites

Ensure the following tools are installed before setting up the project.

| Tool | Version (Recommended) |
|------|------------------------|
| Git | Latest |
| Docker | 24+ |
| Kind | Latest |
| kubectl | Compatible with your Kind cluster |
| Terraform | 1.13.0 |
| Helm | 3.x |

Verify the installation using:

```bash
git --version
docker --version
kind version
kubectl version --client
terraform version
helm version
```








# Complete Setup Guide

This section describes the complete process for provisioning the local infrastructure, deploying the application, and accessing the monitoring stack.

---

## Step 1 – Clone the Repository

```bash
git clone https://github.com/<your-username>/primalabs-devops-assignment.git

cd primalabs-devops-assignment
```

---

## Step 2 – Create the Kind Kubernetes Cluster

Create a local Kubernetes cluster.

```bash
kind create cluster --name primalabs
```

Verify the cluster.

```bash
kubectl cluster-info

kubectl get nodes
```

---

## Step 3 – Build the Docker Image

Build the production Docker image.

```bash
docker build -t primalabs-app:v1 .
```

Load the image into the Kind cluster.

```bash
kind load docker-image primalabs-app:v1 --name primalabs
```

---

## Step 4 – Provision Infrastructure using Terraform

Navigate to the Terraform directory.

```bash
cd terraform
```

Initialize Terraform.

```bash
terraform init
```

Validate the configuration.

```bash
terraform validate
```

Review the execution plan.

```bash
terraform plan
```

Provision the infrastructure.

```bash
terraform apply
```

Terraform creates:

- Monitoring Namespace
- Metrics Server
- kube-prometheus-stack
- Prometheus
- Grafana
- Alertmanager
- Node Exporter
- kube-state-metrics

Return to the project root.

```bash
cd ..
```

<img width="1052" height="1050" alt="tf-1st-apply" src="https://github.com/user-attachments/assets/71eb874d-83ce-4061-8845-ef7ed2617956" />


---

## Step 5 – Deploy the Application

Deploy the Kubernetes resources.

```bash
kubectl apply -f kubernetes/
```

Resources created:

- Deployment
- Service
- Horizontal Pod Autoscaler
- Pod Disruption Budget
- ServiceMonitor

Verify the deployment.

```bash
kubectl get pods -n primalabs

kubectl get svc -n primalabs

kubectl get deployment -n primalabs
```

---

## Step 6 – Verify the Monitoring Stack

Confirm the monitoring components are running.

```bash
kubectl get pods -n monitoring

kubectl get pods -n kube-system
```

Verify Metrics Server.

```bash
kubectl top nodes

kubectl top pods -n primalabs
```

---

## Step 7 – Access Prometheus

Port-forward the Prometheus service.

```bash
kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090
```

Open:

```
http://localhost:9090
```

Navigate to **Status → Targets** to verify that the FastAPI application is being scraped successfully.

<img width="1724" height="938" alt="Screenshot 2026-07-20 at 9 25 03 PM" src="https://github.com/user-attachments/assets/21177bee-562e-4d4d-b851-5c800039b619" />

---

## Step 8 – Access Grafana

Port-forward the Grafana service.

```bash
kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80
```

Retrieve the Grafana administrator password.

```bash
kubectl get secret -n monitoring kube-prometheus-stack-grafana \
-o jsonpath="{.data.admin-password}" | base64 --decode
```

Login using:

| Username | Password |
|----------|----------|
| admin | Output of the command above |

Open Grafana:

```
http://localhost:3000
```

The application dashboard should now be available and display:

- Total Requests
- Requests per Second
- P95 Response Time
- CPU Usage
- Memory Usage
- Requests by Endpoint

<img width="1920" height="1080" alt="grafana-dashboard" src="https://github.com/user-attachments/assets/57a7f6a8-4755-42be-ab16-48e9e2a64f4d" />


---

## Step 9 – Verify Horizontal Pod Autoscaling

Check the HPA status.

```bash
kubectl get hpa -n primalabs
```

Monitor scaling events.

```bash
kubectl get hpa -n primalabs -w
```

Generate load against the application.

```bash
while true; do
  curl http://localhost:8080/work > /dev/null
done
```

Observe the HPA increasing the number of replicas based on CPU utilization.

<img width="1523" height="1043" alt="hpa" src="https://github.com/user-attachments/assets/01f1560f-a2e7-48bd-a7f5-86ffa53dc78c" />

<img width="1512" height="256" alt="hpa-imple" src="https://github.com/user-attachments/assets/df4b7773-2973-4cea-896e-9a77a0461fa3" />


---

## Deployment Complete

At this stage, the complete local platform is operational.

The deployment consists of:

- A FastAPI application running on Kind Kubernetes.
- Production-oriented Kubernetes manifests with health probes, resource requests/limits, HPA, PDB, and security contexts.
- Prometheus automatically scraping application metrics through the ServiceMonitor.
- Grafana visualizing service health through a version-controlled dashboard.
- Infrastructure provisioned using Terraform and Helm.
- Continuous Integration configured through GitHub Actions for validation, Docker builds, vulnerability scanning, and SBOM generation.

# CI Pipeline

The project implements a GitHub Actions based Continuous Integration (CI) workflow that executes automatically for every push to the `main` branch and every Pull Request.

The pipeline is responsible for validating infrastructure and application changes before deployment. It intentionally **does not perform infrastructure or application deployment**, keeping validation independent from release.

### Pipeline Stages

1. Checkout repository
2. Terraform format validation (`terraform fmt -check`)
3. Terraform configuration validation (`terraform validate`)
4. Docker image build
5. Trivy vulnerability scan
6. CycloneDX SBOM generation
7. Upload SBOM artifact

```
Developer
      │
git push / Pull Request
      │
      ▼
GitHub Actions
      │
      ├── terraform fmt -check
      ├── terraform validate
      ├── docker build
      ├── Trivy Scan
      └── Generate CycloneDX SBOM
```

The generated SBOM is uploaded as a GitHub Actions artifact and can be downloaded directly from the workflow run.

<img width="1690" height="882" alt="ci-final" src="https://github.com/user-attachments/assets/2b1bf3c9-698e-4426-a11b-f00e526dfce9" />

<img width="1616" height="885" alt="all-workflow" src="https://github.com/user-attachments/assets/0909f8a3-5359-4c0d-b62a-a560356a1903" />

# Requirement Coverage

The implementation satisfies all mandatory requirements defined in the assignment while also incorporating several optional enhancements.

| Requirement | Status |
|-------------|:------:|
| Production Docker image (multi-stage, non-root, HEALTHCHECK, `.dockerignore`) | ✅ |
| Terraform provisioning (Kind, Helm, Kubernetes) | ✅ |
| Kubernetes Deployment, Service, HPA, PDB & ServiceMonitor | ✅ |
| Production-ready Deployment (probes, resources, securityContext) | ✅ |
| Prometheus & Grafana monitoring | ✅ |
| Dashboard as Code | ✅ |
| GitHub Actions CI | ✅ |
| Terraform validation | ✅ |
| Docker image build | ✅ |
| Trivy vulnerability scanning | ✅ |
| CycloneDX SBOM generation | ✅ |
| README with architecture and setup instructions | ✅ |


# Bonus Features

The following optional improvements were implemented in addition to the mandatory requirements.

| Feature | Status |
|---------|:------:|
| Feature Branch Workflow | ✅ |
| Pull Request | ✅ |
| Tagged Release (`v1.0.0`) | ✅ |
| Trivy Image Vulnerability Scan | ✅ |
| CycloneDX SBOM Generation | ✅ |
| HPA Demonstration Under Load | ✅ |

<img width="1595" height="466" alt="tagged-release" src="https://github.com/user-attachments/assets/a8a5f728-6a4a-47eb-bfb7-8b688dacd50c" />
<img width="1168" height="803" alt="merge-pr" src="https://github.com/user-attachments/assets/b7cd8bd2-cb85-46e7-af64-a4f7942147e6" />
<img width="1648" height="896" alt="compare-and-pull" src="https://github.com/user-attachments/assets/46c693cc-b149-4550-8ad2-2b45da4f5050" />


## Not implemented for now

The following optional enhancements were intentionally left out to keep the implementation focused on the core assignment:

- Kind cluster creation and smoke testing inside GitHub Actions.
- Grafana alert rules as code.
- Canary / Blue-Green deployment strategy.
- Multi-architecture Docker image builds.

# Design Decisions

Several implementation decisions were made to keep the project modular, reproducible, and aligned with production DevOps practices.

- **Terraform** is responsible for infrastructure provisioning, while Kubernetes manifests manage application deployment.
- **Kind** was selected to provide a lightweight and reproducible local Kubernetes environment without relying on cloud infrastructure.
- **Helm** simplifies deployment and lifecycle management of the complete monitoring stack.
- **GitHub Actions** performs validation only, keeping deployment independent from Continuous Integration.
- **Grafana dashboards** are maintained as code to ensure monitoring configuration remains version controlled.
- **Security best practices** such as non-root containers, health probes, resource limits, and hardened security contexts were implemented throughout the deployment.

# Trade-offs

To keep the implementation focused on the assignment objectives, a few deliberate trade-offs were made.

- Continuous Deployment was intentionally excluded; infrastructure and application deployment remain manual.
- The Grafana dashboard is stored within the repository as code. Automatic dashboard provisioning through the Helm chart was explored but not fully integrated to avoid unnecessary complexity for the assignment.
- The solution targets a local Kind cluster rather than a managed Kubernetes service such as EKS or GKE.
- Alerting rules and progressive deployment strategies were deferred in favor of completing the core infrastructure, monitoring, and CI requirements.

# Future Improvements

Although the current implementation satisfies the assignment requirements, several enhancements would make the platform closer to a production deployment.

### Kind Cluster inside CI

Instead of validating only Terraform and Docker, GitHub Actions could create a temporary Kind cluster, provision the infrastructure, deploy the application, execute smoke tests, and destroy the cluster after completion.

```
GitHub Actions
        │
Create Kind Cluster
        │
terraform apply
        │
kubectl apply
        │
Smoke Tests
        │
Destroy Cluster
```

This would provide end-to-end infrastructure validation for every Pull Request.

---

### GitOps Continuous Deployment with Argo CD

A production implementation would separate CI and CD using a GitOps workflow.

```
Developer
      │
git push
      │
      ▼
GitHub Actions
      │
Build Docker Image
      │
Push Image
      │
Update Helm Values
      │
Commit to GitOps Repository
      │
      ▼
Argo CD
      │
Synchronize Cluster
      │
Rolling Update
```

With this approach:

- Git becomes the single source of truth.
- Deployments occur automatically after approval.
- Rollbacks can be performed by reverting Git commits.
- Manual `kubectl apply` commands are no longer required.
