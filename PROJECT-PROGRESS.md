# DevSecOps CI/CD Portfolio Project — Progress

## Project Information

- Project: End-to-End DevSecOps CI/CD Pipeline
- Owner: Richard Jabarul Akbar
- Role: DevOps Engineer
- Application: Static Portfolio Website
- Repository: https://github.com/RichardAkbar/devops-project-cicd
- Branch: main
- Learning Environment: KodeKloud CI/CD Playground

## Project Objective

Build an end-to-end DevSecOps CI/CD pipeline for a static portfolio website using Jenkins, Docker, security scanning, SBOM generation, a private container registry, Kubernetes, and monitoring tools.

The project is developed incrementally in KodeKloud Playground. GitHub is the persistent source of truth for application source code, pipeline definitions, infrastructure configuration, and documentation.

## Technology Stack

| Component | Technology | Status |
|---|---|---|
| Source Control | GitHub | Completed |
| Application | HTML, CSS | Completed |
| Web Server | Nginx | Completed |
| Containerization | Docker | Completed |
| CI/CD | Jenkins | Pipeline from SCM working |
| Security Scanning | Trivy | Integrated |
| SBOM | CycloneDX | Integrated |
| Container Registry | Private Docker Registry | Push/pull tested |
| Code Quality | SonarQube | Pending installation |
| Deployment | Kubernetes | Pending |
| Monitoring | Prometheus, Grafana | Pending |

## Repository Structure

```text
devops-project-cicd/
├── app/
│   ├── index.html
│   └── css/
│       └── style.css
├── docs/
│   ├── 02-application-development/
│   ├── 03-dockerization/
│   ├── 04-private-registry/
│   └── 10-recovery-guide/
├── evidence/
├── Dockerfile
├── Jenkinsfile
└── PROJECT-PROGRESS.md
```

## Completed Milestones

### 1. Portfolio Website

- Created static portfolio using HTML and CSS.
- Added hero, About, Skills, Projects, and Contact sections.
- Tested website rendering using Python HTTP server.
- Committed and pushed source code to GitHub.

### 2. Dockerization

- Created Dockerfile using `nginx:stable-alpine`.
- Configured Nginx to listen on port 8080.
- Configured Nginx to run as non-root user `nginx`.
- Redirected Nginx access and error logs to stdout/stderr.
- Configured writable temporary directories under `/tmp`.
- Built and tested the Docker image.

Image:
- Local name: `devops-portfolio:v1`
- Runtime user: `nginx` (UID 101)

Environment note:
- Docker build required `--network=host` because of sandbox bridge DNS behavior.
- Runtime application uses Docker bridge networking.
- Sandbox port 8080 was occupied by `ttyd`; host port 8082 was used for Docker port mapping. Access through the sandbox routing layer was not fully verified.

### 3. Private Docker Registry

- Registry endpoint: `docker-host:5000`
- Authenticated using Jenkins-compatible registry credentials.
- Successfully pushed the portfolio image.
- Removed the local registry tag and pulled the image again.
- Verified the pulled image ID and non-root runtime user.
- Successfully tested a container created from the pulled image.

### 4. Jenkins CI Pipeline

Jenkins job:
- Name: `devops-portfolio-agent-test`
- Pipeline type: Pipeline script from SCM
- SCM: Git
- Repository: `https://github.com/RichardAkbar/devops-project-cicd.git`
- Branch: `main`
- Script path: `Jenkinsfile`
- Agent label: `docker`

The Jenkinsfile is stored in GitHub and successfully executed from SCM.

### 5. Security Scanning and SBOM

Integrated stages:
- Source validation
- Trivy filesystem scan
- Docker image build
- Trivy image vulnerability scan
- CycloneDX SBOM generation
- Archive SBOM and Trivy JSON reports
- Push image to private registry

Trivy version observed on Docker Host:
- `0.76.1`

Latest successful pipeline:
- Jenkins build: `#14`
- Git commit: `24b2052661ae2440509485e257b2fc5a549f74f4`
- Commit message: `fix: remove unsupported Jenkins pipeline option`
- Image: `docker-host:5000/devops-portfolio:build-14`
- Registry digest: `sha256:12a0f059b92751a317de633e4edbf9e02eb6893cec1869bb0f56fdc6432fd83d`
- SBOM and Trivy reports were archived by Jenkins.
- Result: `SUCCESS`

Important security limitation:
- Current Trivy commands use `--exit-code 0`.
- Findings therefore do not fail the pipeline yet.
- Image scan currently selects HIGH and CRITICAL vulnerabilities and uses `--ignore-unfixed`.
- A proper security gate still needs to be designed and tested.

## Jenkins Credentials and Environment

Credential IDs observed in Jenkins:
- `docker-host-ssh-creds`
- `my-kube-config-credentials` (Secret file)
- `docker-registry-creds`

Do not commit credential values, passwords, tokens, private keys, or kubeconfig contents to Git.

The credentials above belong to the current playground and may need to be recreated in a new playground.

Jenkins agent:
- Node: `docker-host`
- Label: `docker`
- User: `admin`
- Java: OpenJDK 17
- Docker CLI and Engine available
- Maven available
- Trivy available
- kubectl client available, but Kubernetes access from the agent had not yet been verified.

## Current SonarQube Status

- Jenkins SonarQube Scanner plugin version `2.19.0` is installed and enabled.
- SonarQube server was not detected on jump-host ports 9000, 9001, or 9090.
- No SonarQube container was found on jump-host.
- Sandbox resource check showed approximately:
  - 61 GiB total RAM
  - 42 GiB available RAM
  - 16 vCPU
  - 264 GB available disk
- Docker Compose version: `v2.35.1`

SonarQube server installation and Jenkins integration are still pending.
Before starting SonarQube, check Elasticsearch kernel requirements and confirm Docker host resource and port availability.

## Next Tasks

Continue in this order:

1. Complete SonarQube server setup and verify access from Jenkins agent.
2. Configure SonarQube server in Jenkins.
3. Create SonarQube project and configure scanner integration.
4. Integrate SonarQube analysis and Quality Gate into Jenkinsfile.
5. Design and test Trivy security gates.
6. Verify Jenkins Kubernetes credential `my-kube-config-credentials`.
7. Inspect Kubernetes cluster and create application manifests.
8. Integrate automated Kubernetes deployment into Jenkins.
9. Set up Prometheus and Grafana monitoring.
10. Perform end-to-end positive and negative testing.
11. Complete portfolio documentation and evidence.

## Working Rules

- Work incrementally and verify each step before proceeding.
- Do not assume tools or services are installed; check first.
- Do not expose credentials in terminal output, Jenkins logs, or Git.
- Store all reusable source/configuration/documentation in GitHub.
- Keep playground-specific recovery instructions in `docs/10-recovery-guide/`.
- Record successful tests and actual outputs; do not mark untested stages as completed.

## Latest Checkpoint

The project is currently at the SonarQube setup stage.

The last confirmed successful Jenkins pipeline was build #14, which checked out the Jenkinsfile from GitHub, built the Docker image, ran Trivy scans, generated and archived CycloneDX SBOM and Trivy reports, and pushed the image to the playground private registry.

Resume from SonarQube setup. Do not rebuild the portfolio application or repeat the already verified Docker and Jenkins stages unless the new playground requires environment recovery.
