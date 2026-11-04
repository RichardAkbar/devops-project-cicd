pipeline {
    agent {
        label 'docker'
    }

    environment {
        IMAGE_NAME = 'devops-portfolio'
        IMAGE_TAG = "build-${BUILD_NUMBER}"
        REGISTRY = 'docker-host:5000'
        NAMESPACE = 'portfolio'
        KUBECTL_VERSION = 'v1.32.0'
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

                    echo "Filesystem security scan passed."
                '''
            }
        }

        stage('Build Docker Image') {
            steps {
                sh '''
                    set -eu

                    docker build \
                        --network=host \
                        -t "${IMAGE_NAME}:${IMAGE_TAG}" \
                        .

                    docker image inspect \
                        "${IMAGE_NAME}:${IMAGE_TAG}" \
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

                    echo "Image security scan passed."
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
                        usernameVariable: 'REGISTRY_USERNAME',
                        passwordVariable: 'REGISTRY_PASSWORD'
                    )
                ]) {
                    sh '''
                        set -eu
                        set +x

                        REGISTRY_IMAGE="${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}"

                        echo "$REGISTRY_PASSWORD" | docker login \
                            "$REGISTRY" \
                            --username "$REGISTRY_USERNAME" \
                            --password-stdin

                        docker tag \
                            "${IMAGE_NAME}:${IMAGE_TAG}" \
                            "$REGISTRY_IMAGE"

                        docker push "$REGISTRY_IMAGE"

                        echo "Image pushed successfully: $REGISTRY_IMAGE"

                        docker logout "$REGISTRY"
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
                    ),
                    usernamePassword(
                        credentialsId: 'docker-registry-creds',
                        usernameVariable: 'REGISTRY_USERNAME',
                        passwordVariable: 'REGISTRY_PASSWORD'
                    )
                ]) {
                    sh '''
                        set -eu
                        set +x

                        export KUBECONFIG="$KUBECONFIG_FILE"

                        echo "=== Preparing kubectl ==="

                        mkdir -p "$WORKSPACE/.bin"

                        curl -fsSLo "$WORKSPACE/.bin/kubectl" \
                            "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"

                        curl -fsSLo "$WORKSPACE/.bin/kubectl.sha256" \
                            "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl.sha256"

                        echo "$(cat "$WORKSPACE/.bin/kubectl.sha256")  $WORKSPACE/.bin/kubectl" \
                            | sha256sum -c -

                        chmod +x "$WORKSPACE/.bin/kubectl"

                        export PATH="$WORKSPACE/.bin:$PATH"

                        kubectl version --client

                        echo "=== Checking Kubernetes connectivity ==="

                        kubectl get nodes

                        kubectl wait \
                            --for=condition=Ready \
                            nodes \
                            --all \
                            --timeout=60s

                        echo "=== Applying Kubernetes namespace ==="

                        kubectl apply -f k8s/namespace.yaml

                        echo "=== Configuring Registry Image Pull Secret ==="

                        kubectl create secret docker-registry registry-credentials \
                            --docker-server="$REGISTRY" \
                            --docker-username="$REGISTRY_USERNAME" \
                            --docker-password="$REGISTRY_PASSWORD" \
                            --namespace="$NAMESPACE" \
                            --dry-run=client \
                            -o yaml | kubectl apply -f -

                        echo "Registry credentials configured successfully."

                        echo "=== Rendering deployment manifest ==="

                        REGISTRY_IMAGE="${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}"

                        sed -E \
                            "s|^([[:space:]]*image: ).*|\\1${REGISTRY_IMAGE}|" \
                            k8s/deployment.yaml > deployment-rendered.yaml

                        trap 'rm -f deployment-rendered.yaml' EXIT

                        echo "=== Applying Kubernetes resources ==="

                        kubectl apply -f deployment-rendered.yaml

                        kubectl apply -f k8s/service.yaml

                        echo "=== Waiting for deployment rollout ==="

                        kubectl rollout status \
                            deployment/portfolio \
                            -n "${NAMESPACE}" \
                            --timeout=180s

                        echo "=== Deployment resources ==="

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
            echo 'CI/CD pipeline completed successfully.'
        }

        failure {
            echo 'Pipeline failed. Check the stage logs.'
        }
    }
}
