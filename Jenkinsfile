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
    }

    post {
        success {
            echo 'CI pipeline completed and image pushed to registry.'
        }
        failure {
            echo 'Pipeline failed. Check the stage logs.'
        }
    }
}
