# KodeKloud Playground Recovery Guide

## Purpose

This guide explains how to resume the DevSecOps CI/CD portfolio project after the previous KodeKloud Playground session expires or is reset.

GitHub is the persistent source of truth. KodeKloud Playground is a temporary execution environment.

Repository:
https://github.com/RichardAkbar/devops-project-cicd

## Important: Persistent vs Temporary Data

### Stored in GitHub

- Application source code
- Dockerfile
- Jenkinsfile
- Kubernetes manifests committed to the repository
- Docker Compose files committed to the repository
- Documentation
- Git history and project progress

### May Be Lost When Playground Resets

- Jenkins jobs and build history
- Jenkins credentials and configuration
- Docker containers and local images
- Private registry contents
- SonarQube server and database
- Kubernetes resources
- Installed packages and Linux configuration
- Files that were not committed and pushed to GitHub
- Temporary Jenkins workspace and archived artifacts

Do not assume that a new playground preserves the old environment.

## Step 1 — Start a New KodeKloud Playground

1. Open KodeKloud.
2. Start the CI/CD Playground.
3. Wait until the environment is ready.
4. Read the new playground task instructions.
5. Identify the current credentials, hostnames, ports, and available services.

Important:
- Playground credentials may change between sessions.
- Do not reuse old passwords without checking the new task instructions.
- Do not store playground passwords in this repository.

## Step 2 — Clone the GitHub Repository

On the new jump-host:

```bash
git clone https://github.com/RichardAkbar/devops-project-cicd.git
cd devops-project-cicd
```

Check the repository:

```bash
git status
git log -5 --oneline
find . -maxdepth 4 -type f | sort
```

Read these files first:

```bash
cat PROJECT-PROGRESS.md
cat docs/10-recovery-guide/PLAYGROUND-RECOVERY.md
```

If the repository is private in the future, authenticate using a secure Git credential method. Never put a GitHub token directly in a clone URL or commit it to Git.

## Step 3 — Verify the New Playground

Do not assume that the previous playground's services and tools still exist.

Run:

```bash
echo "===== HOST ====="
hostname
whoami

echo "===== OS ====="
cat /etc/os-release

echo "===== RESOURCES ====="
free -h
nproc
df -h /

echo "===== GIT ====="
git --version

echo "===== DOCKER ====="
docker --version
docker info

echo "===== DOCKER COMPOSE ====="
docker compose version

echo "===== KUBECTL ====="
kubectl version --client 2>/dev/null || true

echo "===== TRIVY ====="
trivy --version 2>/dev/null || true

echo "===== JAVA ====="
java -version 2>&1 || true

echo "===== MAVEN ====="
mvn -version 2>/dev/null || true
```

Record which tools are installed and which need to be installed.

## Step 4 — Verify Docker Host and Registry

Read the new playground instructions to identify the Docker Host and registry.

If the task provides SSH access to `docker-host`, test it using the credentials shown in the new playground instructions:

```bash
ssh -l admin docker-host
```

After connecting:

```bash
hostname
whoami
docker --version
docker info
java -version
mvn -version
trivy --version 2>/dev/null || true
kubectl version --client 2>/dev/null || true
```

Check registry connectivity using the registry hostname and port supplied by the new playground:

```bash
getent hosts docker-host
curl -k -sS -o /dev/null -w 'HTTP %{http_code}\n' \
  https://docker-host:5000/v2/
```

An HTTP 401 response without authentication can be expected for a private registry. It indicates that the endpoint responds and requires authentication; it does not prove that credentials work.

Do not assume the old registry still contains the previous image.

## Step 5 — Restore Jenkins Configuration

The Jenkins server may be preconfigured in a new playground, but its jobs, plugins, and credentials must be inspected.

1. Open the Jenkins UI using the URL provided by the new playground.
2. Log in using the current playground credentials.
3. Check whether the Git plugin and Pipeline plugins are installed.
4. Check whether the SonarQube Scanner plugin is installed.
5. Inspect the available Jenkins nodes and labels.
6. Verify that the `docker` agent label exists and that the agent can access Docker.

Configure the project job:

- Job name: `devops-portfolio-agent-test`
- Type: Pipeline
- Definition: Pipeline script from SCM
- SCM: Git
- Repository URL: `https://github.com/RichardAkbar/devops-project-cicd.git`
- Branch: `*/main`
- Script Path: `Jenkinsfile`

Use the repository's Jenkinsfile rather than copying a temporary pipeline script into the Jenkins UI.

## Step 6 — Recreate Jenkins Credentials

Inspect the current Jenkins credentials before creating anything.

The previous playground used these credential IDs:

| Credential ID | Previous purpose |
|---|---|
| `docker-host-ssh-creds` | SSH access to Docker Host |
| `my-kube-config-credentials` | Kubernetes kubeconfig Secret file |
| `docker-registry-creds` | Private registry username/password |

These IDs are historical references. A new playground may have different credentials or may already contain equivalent credentials.

Create or update credentials only after verifying the new playground's requirements.

Never:
- Commit passwords or tokens to Git.
- Put credentials directly in Jenkinsfile.
- Print secrets in build logs.
- Copy old kubeconfig or private keys into the repository.

## Step 7 — Restore the CI Pipeline

Before running the pipeline, verify:

```bash
test -f app/index.html
test -f app/css/style.css
test -f Dockerfile
test -f Jenkinsfile
```

On the Jenkins agent, verify:

```bash
git --version
docker --version
trivy --version
```

Check that the registry hostname is resolvable and reachable from the agent.

Then run the Jenkins job and inspect each stage.

The repository Jenkinsfile currently includes:

1. Checkout and source validation
2. Trivy filesystem scan
3. Docker image build
4. Trivy image scan
5. CycloneDX SBOM generation
6. Push to private registry
7. Archive SBOM and Trivy JSON reports

The current pipeline assumes:
- Jenkins agent label `docker`
- Registry endpoint `docker-host:5000`
- Jenkins credential ID `docker-registry-creds`

If these differ in the new playground, update the Jenkins configuration or Jenkinsfile deliberately and commit the changes.

## Step 8 — Restore SonarQube

SonarQube server was not installed in the previous playground.

When resuming:

1. Check whether a SonarQube server is already provided.
2. Check Docker host resources and port availability.
3. Verify Elasticsearch kernel requirements.
4. Select a compatible SonarQube deployment method.
5. Persist SonarQube database and data if the playground supports persistent storage.
6. Configure Jenkins SonarQube server and credentials.
7. Test scanner connectivity from the Jenkins agent.
8. Integrate analysis and Quality Gate into Jenkinsfile.

Do not assume that a SonarQube container or database from the previous session still exists.

## Step 9 — Restore Kubernetes

The previous playground had a single-node Kubernetes cluster.

The Jenkins credential `my-kube-config-credentials` was present, but Kubernetes access from the Docker Host agent had not yet been verified.

When resuming:

1. Inspect the cluster using the access method provided by the new playground.
2. Verify the Jenkins kubeconfig credential.
3. Test Kubernetes API connectivity from the Jenkins pipeline.
4. Inspect namespaces and existing resources.
5. Create or restore application manifests from GitHub.
6. Deploy the portfolio application.
7. Verify rollout and HTTP health.

Never commit kubeconfig contents, certificates, or cluster tokens to Git.

## Step 10 — Restore Monitoring

Prometheus and Grafana are pending.

When implementing:

1. Verify whether the new playground already provides monitoring components.
2. Store reusable configuration and manifests in GitHub.
3. Deploy Prometheus.
4. Configure scrape targets.
5. Deploy Grafana.
6. Create and version-control dashboard definitions.
7. Verify metrics collection and dashboards.

## Recovery Completion Checklist

- [ ] New playground started.
- [ ] GitHub repository cloned.
- [ ] Project progress reviewed.
- [ ] Playground tools verified.
- [ ] Docker Host connectivity verified.
- [ ] Private registry connectivity verified.
- [ ] Jenkins UI accessible.
- [ ] Jenkins agent verified.
- [ ] Jenkins credentials inspected or recreated.
- [ ] Pipeline from SCM configured.
- [ ] Jenkins pipeline executed successfully.
- [ ] SonarQube restored or installation started.
- [ ] Kubernetes access verified.
- [ ] Monitoring setup resumed.

## Resume Point

Always read `PROJECT-PROGRESS.md` for the latest verified project state.

The last confirmed checkpoint in the previous playground:

- Jenkins build: #14
- Git commit: `24b2052661ae2440509485e257b2fc5a549f74f4`
- Pipeline result: SUCCESS
- SonarQube server: Not installed
- Kubernetes deployment: Not completed
- Prometheus/Grafana: Not completed

Resume from the first incomplete task in `PROJECT-PROGRESS.md`.

Do not repeat completed implementation steps unless the new playground requires environment recovery or re-verification.
