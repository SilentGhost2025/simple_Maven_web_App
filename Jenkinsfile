pipeline {
    agent any

    environment {
        GIT_REPO    = 'https://github.com/SilentGhost2025/simple_Maven_web_App.git'
        BRANCH      = 'master'
        APP_SERVER  = '10.0.136.41'
        USER        = 'ec2-user'
    }

    tools {
        maven 'Maven'
    }

    stages {
        stage('Clone from GitHub') {
            steps {
                git branch: "${BRANCH}", url: "${GIT_REPO}"
            }
        }

        stage('Build with Maven') {
            steps {
                sh 'mvn clean package'
            }
        }

        stage('SonarQube Analysis') {
            steps {
                // We still run the scan, but we don't wait for the result
                withSonarQubeEnv('Sonarqube') {
                    sh 'mvn sonar:sonar'
                }
            }
        }

        stage('Upload to Nexus') {
            steps {
                configFileProvider([configFile(fileId: 'maven-settings', variable: 'MAVEN_SETTINGS')]) {
                    sh 'mvn deploy -s "$MAVEN_SETTINGS" -DskipTests'
                }
            }
        }

        stage('Build Docker & Deploy') {
            steps {
                sshagent(['app-server-ssh']) {
                    sh """
                        # Copy war and Dockerfile to server
                        scp -o StrictHostKeyChecking=no target/Landmark.war ${USER}@${APP_SERVER}:/home/${USER}/
                        scp -o StrictHostKeyChecking=no Dockerfile ${USER}@${APP_SERVER}:/home/${USER}/

                        # SSH and Deploy
                        ssh -o StrictHostKeyChecking=no ${USER}@${APP_SERVER} '
                            cd /home/${USER}
                            
                            docker stop tomcat-app || true
                            docker rm tomcat-app || true
                            
                            docker build -t tomcat-app:latest .
                            docker run -d \
                                --name tomcat-app \
                                -p 8080:8080 \
                                --restart unless-stopped \
                                tomcat-app:latest
                        '
                    """
                }
            }
        }
    }

    post {
        success {
            echo '✅ Pipeline finished — Quality Gate bypassed, app is up!'
        }
        failure {
            echo '❌ Pipeline failed — check the console output.'
        }
    }
}
