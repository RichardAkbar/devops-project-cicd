
pipeline {
    agent any

    options {
        timestamps()
        disableConcurrentBuilds()
    }

    environment {
       IMAGE_NAME = 'devops-project-cicd'
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
                    echo "Required files are present."
                    git --version
                    docker --version
                    trivy --version
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
                    docker build \
                      -t ${IMAGE_NAME}:${IMAGE_TAG} \
                      -t ${IMAGE_NAME}:latest \
                      .
                '''
            }
        }
    }

    post {
        success {
            echo 'Pipeline completed successfully.'
        }
        failure {
            echo 'Pipeline failed. Check the stage logs.'
        }
    }
}
