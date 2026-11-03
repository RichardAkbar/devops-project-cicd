pipeline {
    agent {
        label 'docker'
    }

    options {
        disableConcurrentBuilds()
        timestamps()
    }

    environment {
        IMAGE_NAME = 'devops-portfolio'
        IMAGE_TAG  = "build-${BUILD_NUMBER}"
        REGISTRY   = 'docker-host:5000'
        NAMESPACE  = 'portfolio'
    }

    stages {
        stage('Checkout & Validate') {
            steps {
                echo 'Validating portfolio source files...'

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

        stage('Trivy Filesystem Scan') {
            steps {
                sh '''
                    set -eu

                    trivy fs \
                        --scanners vuln,secret,misconfig \
                        --severity HIGH,CRITICAL \
                        --exit-code 1 \
                        --format json \
                        --output trivy-fs-report.json \
                        .

                    echo "Filesystem scan completed."
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
                    ls -lh "sbom-${IMAGE_TAG}.json"
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

                        docker tag \
                            "${IMAGE_NAME}:${IMAGE_TAG}" \
                            "$REGISTRY_IMAGE"

                        docker push "$REGISTRY_IMAGE"

                        echo "Image pushed successfully: $REGISTRY_IMAGE"
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

                        echo "Checking kubectl..."
                        command -v kubectl
                        kubectl version --client

                        echo "Checking Kubernetes connectivity..."
                        kubectl get nodes

                        echo "Checking cluster node readiness..."
                        kubectl wait \
                            --for=condition=Ready \
                            nodes \
                            --all \
                            --timeout=60s

                        REGISTRY_IMAGE="${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}"

                        echo "Rendering deployment manifest..."
                        sed -E \
                            "s|^([[:space:]]*image: ).*|\\1${REGISTRY_IMAGE}|" \
                            k8s/deployment.yaml > deployment-rendered.yaml

                        trap 'rm -f deployment-rendered.yaml' EXIT

                        echo "Applying namespace..."
                        kubectl apply -f k8s/namespace.yaml

                        echo "Applying deployment..."
                        kubectl apply -f deployment-rendered.yaml

                        echo "Applying service..."
                        kubectl apply -f k8s/service.yaml

                        echo "Waiting for rollout..."
                        kubectl rollout status \
                            deployment/portfolio \
                            -n "${NAMESPACE}" \
                            --timeout=180s

                        echo "Checking deployed resources..."
                        kubectl get deployment,pods,service \
                            -n "${NAMESPACE}"

                        echo "Kubernetes deployment completed."
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
            echo 'CI/CD pipeline completed successfully: security scans passed, SBOM generated, image pushed, and Kubernetes deployment completed.'
        }

        failure {
            echo 'Pipeline failed. Check the stage logs.'
        }
    }
}
