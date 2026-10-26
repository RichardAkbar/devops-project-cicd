pipeline {
    agent any

    options {
        disableConcurrentBuilds()
    }

    environment {
        IMAGE_NAME = 'devops-project-cicd'
        REGISTRY   = 'docker-host:5000'
        IMAGE_TAG  = "build-${BUILD_NUMBER}"
    }

    stages {
        stage('Checkout & Validate') {
            steps {
                echo 'Validating portfolio source files...'
                sh '''
                    set -eu
                    test -f index.html
                    test -f style.css
                    test -f Dockerfile
                    test -f Jenkinsfile

                    git --version
                    docker --version
                    trivy --version

                    echo "Source validation passed."
                '''
            }
        }

        stage('Trivy Filesystem Scan') {
            steps {
                sh '''
                    trivy fs \
                      --scanners vuln,secret,misconfig \
                      --severity HIGH,CRITICAL \
                      --exit-code 0 \
                      .
                '''
            }
        }

        stage('Build Docker Image') {
            steps {
                sh '''
                    set -eu

                    docker build \
                      -t "${IMAGE_NAME}:${IMAGE_TAG}" \
                      -t "${IMAGE_NAME}:latest" \
                      .

                    docker image inspect "${IMAGE_NAME}:${IMAGE_TAG}" \
                      --format 'Built image: {{.Id}}'
                '''
            }
        }

        stage('Trivy Image Scan') {
            steps {
                sh """
                    set -eu

                    trivy image \\
                      --scanners vuln \\
                      --severity HIGH,CRITICAL \\
                      --ignore-unfixed \\
                      --exit-code 1 \\
                      "${IMAGE_NAME}:${IMAGE_TAG}"
                """
            }
        }

        stage('Push to Registry') {
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

                        echo "$REGISTRY_PASSWORD" | docker login "$REGISTRY" \
                          --username "$REGISTRY_USER" \
                          --password-stdin

                        docker tag \
                          "${IMAGE_NAME}:${IMAGE_TAG}" \
                          "${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}"

                        docker push "${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}"

                        docker logout "$REGISTRY"
                    '''
                }
            }
        }
        stage('Deploy to Kubernetes') {
            steps {
                sh """
                    set -eu
                    export KUBECONFIG=/var/lib/jenkins/.kube/config

                    kubectl set image deployment/devops-project-cicd \
                      web="\${REGISTRY}/\${IMAGE_NAME}:\${IMAGE_TAG}"

                    kubectl rollout status deployment/devops-project-cicd \
                      --timeout=120s

                    kubectl exec deployment/devops-project-cicd -- \
                      wget -q -O /dev/null http://127.0.0.1:8080/

                    echo "Kubernetes deployment and HTTP health check passed."
                """
            }
        }
    }

    post {
        success {
            echo 'CI pipeline completed: security scan passed, image pushed, and Kubernetes deployment verified.'
        }
        failure {
            echo 'Pipeline failed. Check the stage logs.'
        }
    }
}
