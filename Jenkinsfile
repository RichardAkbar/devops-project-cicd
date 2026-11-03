pipeline {
    agent {
        label 'docker'
    }

    options {
        disableConcurrentBuilds()
    }

    environment {
        IMAGE_NAME = 'devops-portfolio'
        IMAGE_TAG  = "build-${BUILD_NUMBER}"
        REGISTRY   = 'docker-host:5000'
    }

    stages {
        stage('Checkout & Validate') {
            steps {
                sh '''
                    set -eu

                    test -f app/index.html
                    test -f app/css/style.css
                    test -f Dockerfile
                    test -f k8s/namespace.yaml
                    test -f k8s/deployment.yaml
                    test -f k8s/service.yaml

                    echo "Source validation passed."
                    git --version
                    docker --version
                    trivy --version
                '''
            }
        }

        stage('Agent Diagnostics') {
            steps {
                sh '''
                    echo "=== Jenkins Agent Information ==="
                    hostname
                    whoami
                    pwd

                    echo ""
                    echo "=== Available Tools ==="

                    for tool in kubectl docker trivy curl wget; do
                        if command -v "$tool" >/dev/null 2>&1; then
                            echo "$tool: $(command -v "$tool")"
                        else
                            echo "$tool: NOT FOUND"
                        fi
                    done

                    echo ""
                    echo "=== Operating System ==="
                    cat /etc/os-release
                '''
            }
        }

        stage('Trivy Filesystem Scan') {
            steps {
                sh '''
                    set -eu

                    echo "Running Trivy diagnostic scan..."

                    trivy fs \
                        --scanners vuln,secret,misconfig \
                        --severity HIGH,CRITICAL \
                        --exit-code 0 \
                        --format table \
                        .

                    trivy fs \
                        --scanners vuln,secret,misconfig \
                        --severity HIGH,CRITICAL \
                        --exit-code 0 \
                        --format json \
                        --output trivy-fs-report.json \
                        .

                    echo "Filesystem diagnostic scan completed."
                '''
            }
        }

        stage('Build Docker Image') {
            steps {
                sh '''
                    set -eu

                    docker build --network=host \
                        -t "${IMAGE_NAME}:${IMAGE_TAG}" \
                        .

                    docker image inspect "${IMAGE_NAME}:${IMAGE_TAG}" \
                        --format 'Built image: {{.Id}}'
                '''
            }
        }

        stage('Trivy Image Scan') {
            steps {
                sh '''
                    set -eu

                    trivy image \
                        --scanners vuln \
                        --severity HIGH,CRITICAL \
                        --ignore-unfixed \
                        --exit-code 1 \
                        --format json \
                        --output trivy-image-report.json \
                        "${IMAGE_NAME}:${IMAGE_TAG}"

                    echo "Image scan completed."
                '''
            }
        }

        stage('Generate CycloneDX SBOM') {
            steps {
                sh '''
                    set -eu

                    trivy image \
                        --format cyclonedx \
                        --output "sbom-${IMAGE_TAG}.json" \
                        "${IMAGE_NAME}:${IMAGE_TAG}"

                    test -s "sbom-${IMAGE_TAG}.json"

                    echo "SBOM generated successfully."
                '''
            }
        }

        stage('Push to Private Registry') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'docker-registry-creds',
                        usernameVariable: 'REGISTRY_USER',
                        passwordVariable: 'REGISTRY_PASSWORD'
                    )
                ]) {
                    sh '''
                        set -eu
                        set +x

                        REGISTRY_IMAGE="${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}"

                        trap 'docker logout "$REGISTRY" >/dev/null 2>&1 || true' EXIT

                        echo "$REGISTRY_PASSWORD" | docker login "$REGISTRY" \
                            --username "$REGISTRY_USER" \
                            --password-stdin

                        docker tag "${IMAGE_NAME}:${IMAGE_TAG}" "$REGISTRY_IMAGE"
                        docker push "$REGISTRY_IMAGE"

                        echo "Image pushed: $REGISTRY_IMAGE"
                    '''
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                withCredentials([
                    file(
                        credentialsId: 'my-kube-config-credentials',
                        variable: 'KUBECONFIG_FILE'
                    )
                ]) {
                    sh '''
                        set -eu

                        export KUBECONFIG="$KUBECONFIG_FILE"

                        command -v kubectl
                        kubectl version --client
                        kubectl get nodes

                        kubectl wait \
                            --for=condition=Ready \
                            nodes \
                            --all \
                            --timeout=60s

                        REGISTRY_IMAGE="${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}"

                        sed -E \
                            "s|^([[:space:]]*image: ).*|\\1${REGISTRY_IMAGE}|" \
                            k8s/deployment.yaml > deployment-rendered.yaml

                        trap 'rm -f deployment-rendered.yaml' EXIT

                        kubectl apply -f k8s/namespace.yaml
                        kubectl apply -f deployment-rendered.yaml
                        kubectl apply -f k8s/service.yaml

                        kubectl rollout status \
                            deployment/portfolio \
                            -n portfolio \
                            --timeout=180s

                        kubectl get deployment,pods,service -n portfolio
                    '''
                }
            }
        }
    }

    post {
        always {
            archiveArtifacts(
                artifacts: 'sbom-*.json,trivy-*-report.json',
                allowEmptyArchive: true,
                fingerprint: true
            )
        }

        success {
            echo 'CI/CD pipeline completed successfully.'
        }

        failure {
            echo 'Pipeline failed. Check the stage logs.'
        }
    }
}
