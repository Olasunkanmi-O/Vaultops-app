pipeline {
    agent any

    environment {
        // Vault address
        VAULT_ADDR = "https://vault.alasoasiko.co.uk:8200"

        // Nexus repositories
        NEXUS_MAVEN_REPO = "https://nexus.alasoasiko.co.uk:8085/repository/maven-releases/"
        NEXUS_DOCKER_REGISTRY = "nexus.alasoasiko.co.uk:8085"
        APPLICATION_NAME = "petclinic-app"
    }

    parameters {
        string(
            name: 'APP_VERSION', 
            defaultValue: '1.0.0', 
            description: 'Application version/tag'
        )
    }

    stages {

        stage('Checkout Code') {
            steps {
                checkout([
                    $class: 'GitSCM',
                    branches: [[name: '*/main']],
                    userRemoteConfigs: [[
                        credentialsId: 'github-cred',
                        url: 'https://github.com/your-org/your-repo.git'
                    ]]
                ])
            }
        }

        stage('SonarQube Scan') {
            steps {
                withSonarQubeEnv('SonarQube') {
                    sh "mvn clean verify sonar:sonar -Dspring.profiles.active=mysql -DskipTests"
                }
            }
        }

        stage('Build & Push WAR to Nexus') {
            steps {
                withCredentials([
                    usernamePassword(credentialsId: 'nexus-maven-cred', usernameVariable: 'NEXUS_USER', passwordVariable: 'NEXUS_PASS')
                ]) {
                    sh """
                        # Override pom.xml version with Jenkins parameter
                        mvn versions:set -DnewVersion=${params.APP_VERSION}

                        # Build
                        mvn clean package -Dspring.profiles.active=mysql -DskipTests

                        # Verify what was built
                        ls -lh target/

                        # Upload with correct name
                        curl -v -u $NEXUS_USER:$NEXUS_PASS \
                        --upload-file target/spring-petclinic-${params.APP_VERSION}.war \
                        ${NEXUS_MAVEN_REPO}spring-petclinic-${params.APP_VERSION}.war
                    """
                }
            }
        }


        stage('Build & Scan Docker Image') {
            steps {
                script {
                    docker.build("${APPLICATION_NAME}:${params.APP_VERSION}", ".")
                    sh "trivy image --exit-code 1 --severity HIGH,CRITICAL ${APPLICATION_NAME}:${params.APP_VERSION} || true"
                }
            }
        }

        stage('Push Docker Image to Nexus') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'nexus-docker-cred', passwordVariable: 'NEXUS_PASS', usernameVariable: 'NEXUS_USER')]) {
                    sh """
                        echo $NEXUS_PASS | docker login ${NEXUS_DOCKER_REGISTRY} -u $NEXUS_USER --password-stdin
                        docker tag ${APPLICATION_NAME}:${params.APP_VERSION} ${NEXUS_DOCKER_REGISTRY}/${APPLICATION_NAME}:${params.APP_VERSION}
                        docker push ${NEXUS_DOCKER_REGISTRY}/${APPLICATION_NAME}:${params.APP_VERSION}
                    """
                }
            }
        }

        stage('Deploy via Ansible') {
            steps {
                ansiblePlaybook(
                    playbook: 'ansible/playbooks/deploy_application.yml',
                    inventory: 'ansible/inventory/aws_ec2.yml',
                    extras: "-e APP_VERSION=${params.APP_VERSION}"
                )
            }
        }
    }

    post {
        success {
            slackSend(
                channel: SLACKCHANNEL,
                color: 'good',
                message: "Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]' Deployed successfully. Check console output at ${env.BUILD_URL}."
            )
        }
        failure {
            slackSend(
                channel: SLACKCHANNEL,
                color: 'danger',
                message: "Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]' has failed. Check console output at ${env.BUILD_URL}."
            )
        }
    }
}
