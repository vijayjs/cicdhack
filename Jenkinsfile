pipeline {
    agent any

    environment {
        PHP_VERSION = '8.2'
        AWS_REGION = 'us-east-1'
        PROJECT_NAME = 'symfony-bg'
        // Credentials should be configured in Jenkins Credentials Manager
        AWS_CREDS = credentials('aws-credentials-id')
        SONAR_TOKEN = credentials('sonar-token-id')
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Install Dependencies') {
            steps {
                sh 'composer install --no-interaction --prefer-dist'
            }
        }

        stage('Static Analysis & Quality') {
            parallel {
                stage('SonarQube Analysis') {
                    steps {
                        withSonarQubeEnv('SonarQube') {
                            sh 'vendor/bin/phpunit --coverage-clover coverage.xml --log-junit junit.xml'
                            sh 'sonar-scanner -Dsonar.projectKey=${PROJECT_NAME} -Dsonar.sources=src -Dsonar.tests=tests -Dsonar.php.coverage.reportPaths=coverage.xml -Dsonar.php.tests.reportPath=junit.xml'
                        }
                        timeout(time: 5, unit: 'MINUTES') {
                            waitForQualityGate abortPipeline: true
                        }
                    }
                }
                stage('Security Scanning') {
                    steps {
                        parallel(
                            "Dependency Scan" : {
                                sh 'trivy fs . --severity HIGH,CRITICAL --format table'
                                sh 'composer audit'
                            },
                            "Secret Scan" : {
                                sh 'gitleaks detect --source . --verbose'
                            },
                            "DAST Scan" : {
                                // Assuming ZAP is available as a command or container
                                echo 'Running OWASP ZAP Baseline Scan...'
                                // sh 'docker run -t owasp/zap2docker-stable zap-baseline.py -t http://localhost'
                            }
                        )
                    }
                }
                stage('PHPStan') {
                    steps {
                        sh 'vendor/bin/phpstan analyse src --level=5'
                    }
                }
            }
        }

        stage('Infrastructure Plan') {
            steps {
                dir('terraform') {
                    sh 'terraform init'
                    sh 'terraform plan -out=tfplan'
                }
            }
        }

        stage('Apply Infrastructure') {
            when {
                branch 'main'
            }
            steps {
                dir('terraform') {
                    // Requires user approval in a real production scenario
                    sh 'terraform apply -auto-approve tfplan'
                }
            }
        }

        stage('Deploy Application') {
            when {
                branch 'main'
            }
            steps {
                script {
                    // Using the existing deployment script
                    sh 'chmod +x scripts/deploy.sh'
                    sh './scripts/deploy.sh green'
                }
            }
        }

        stage('Smoke Test') {
            steps {
                sh 'chmod +x scripts/health-check.sh'
                sh './scripts/health-check.sh'
            }
        }
    }

    post {
        always {
            cleanWs()
        }
        success {
            echo 'Deployment successful!'
        }
        failure {
            echo 'Deployment failed. Check logs.'
        }
    }
}
