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

                    echo "Source validation passed."
                    echo "Git version:"
                    git --version

                    echo "Docker version:"
                    docker --version

                    echo "Trivy version:"
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
                        --exit-code 0 \
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
                        --exit-code 0 \
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
            echo 'CI pipeline completed: source validated, security scans executed, SBOM generated, and image pushed.'
        }

        failure {
            echo 'Pipeline failed. Check the stage logs.'
        }
    }
}
