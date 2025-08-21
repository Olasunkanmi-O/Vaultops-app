pipeline {
    agent any
    tools {
        maven 'maven'  // your Jenkins Maven tool name
    }
    parameters {
        string(name: 'APP_VERSION', defaultValue: '2.4.2', description: 'Application version/tag')
    }
    environment {
        APPLICATION_NAME = 'spring-petclinic'
        NEXUS_MAVEN_REPO = 'https://nexus.alasoasiko.co.uk:8085/repository/maven-releases/'
        NEXUS_DOCKER_REGISTRY = 'nexus.alasoasiko.co.uk:8085'
        SLACK_CHANNEL = '#devops-alerts'
    }

    stages {
        stage('Build & Push WAR to Nexus') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'nexus-maven-cred', usernameVariable: 'NEXUS_USER', passwordVariable: 'NEXUS_PASS')]) {
                    sh """
                        # Build WAR with Maven, skipping tests
                        mvn clean package -Dspring.profiles.active=mysql -DskipTests -DfinalName=${APPLICATION_NAME}-${params.APP_VERSION}

                        # Upload WAR to Nexus
                        curl -v -u $NEXUS_USER:$NEXUS_PASS --upload-file target/${APPLICATION_NAME}-${params.APP_VERSION}.war \
                        ${NEXUS_MAVEN_REPO}${APPLICATION_NAME}-${params.APP_VERSION}.war
                    """
                }
            }
        }

        stage('Prepare WAR for Docker') {
            steps {
                sh """
                # Copy/rename WAR to ROOT.war for Tomcat
                cp target/${APPLICATION_NAME}-${params.APP_VERSION}.war target/ROOT.war
                """
            }
        }

        stage('Build & Scan Docker Image') {
            steps {
                script {
                    // Build Docker image using the prepared ROOT.war
                    docker.build("${APPLICATION_NAME}:${params.APP_VERSION}", ".")

                    // Scan Docker image with Trivy
                    sh "trivy image --exit-code 1 --severity HIGH,CRITICAL ${APPLICATION_NAME}:${params.APP_VERSION} || true"
                }
            }
        }

        stage('Push Docker Image to Nexus') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'nexus-docker-cred', usernameVariable: 'NEXUS_USER', passwordVariable: 'NEXUS_PASS')]) {
                    sh """
                        # Login to Nexus Docker registry
                        echo $NEXUS_PASS | docker login ${NEXUS_DOCKER_REGISTRY} -u $NEXUS_USER --password-stdin

                        # Tag and push Docker image
                        docker tag ${APPLICATION_NAME}:${params.APP_VERSION} ${NEXUS_DOCKER_REGISTRY}/${APPLICATION_NAME}:${params.APP_VERSION}
                        docker push ${NEXUS_DOCKER_REGISTRY}/${APPLICATION_NAME}:${params.APP_VERSION}
                    """
                }
            }
        }
    }

    post {
        always {
            // Slack notification for build result
            slackSend (
                channel: "${SLACK_CHANNEL}",
                color: currentBuild.currentResult == 'SUCCESS' ? 'good' : 'danger',
                message: "Job *${env.JOB_NAME}* #${env.BUILD_NUMBER} finished with *${currentBuild.currentResult}*. WAR version: ${params.APP_VERSION}"
            )
        }
    }
}
