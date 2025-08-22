pipeline {
    agent any

    environment {
        // Nexus Docker Registry URL (with port)
        DOCKER_REGISTRY = 'nexus.alasoasiko.co.uk:8085'
        DOCKER_IMAGE_NAME = 'petclinicapps'
        DOCKER_CREDENTIAL_ID = 'nexus-docker'
        
        // Paths to Ansible
        ANSIBLE_PLAYBOOK = 'ansible/playbooks/deploy_application.yml'
        ANSIBLE_INVENTORY = 'ansible/inventory/aws_ec2.yml'
        
        // DB info - passed as extra-vars to playbook
        DB_HOST = 'petclinic.chc40k2yklya.us-east-2.rds.amazonaws.com'
        DB_PORT = '3306'
    }

    stages {
        stage('Checkout Source Code') {
            steps {
                git branch: 'main', url: 'https://github.com/your-username/petclinic.git'
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('SonarQube') { // Replace 'SonarQube' with your Jenkins SonarQube installation name
                    sh 'mvn clean verify sonar:sonar'
                }
            }
        }

        stage('Build WAR & Docker Image') {
            steps {
                script {
                    // Build WAR
                    sh 'mvn clean package -DskipTests'

                    // Docker image tag based on Jenkins build number
                    env.IMAGE_TAG = "${env.BUILD_NUMBER}"
                    def fullImageName = "${DOCKER_REGISTRY}/${DOCKER_IMAGE_NAME}:${env.IMAGE_TAG}"

                    // Build Docker image
                    sh "docker build -t ${fullImageName} ."

                    // Login & push to Nexus Docker repo
                    withCredentials([usernamePassword(credentialsId: env.DOCKER_CREDENTIAL_ID,
                                                      usernameVariable: 'DOCKER_USER',
                                                      passwordVariable: 'DOCKER_PASS')]) {
                        sh "docker login -u ${DOCKER_USER} -p ${DOCKER_PASS} ${DOCKER_REGISTRY}"
                        sh "docker push ${fullImageName}"
                    }

                    echo "Docker image pushed: ${fullImageName}"
                }
            }
        }

        stage('Deploy to Staging') {
            steps {
                script {
                    sh """
                    ansible-playbook -i ${ANSIBLE_INVENTORY} ${ANSIBLE_PLAYBOOK} \
                        --extra-vars "APP_VERSION=${env.IMAGE_TAG} db_host=${DB_HOST} db_port=${DB_PORT}"
                    """
                }
            }
        }

        stage('Approval for Production') {
            steps {
                input message: "Deploy to Production?", ok: "Deploy"
                script {
                    sh """
                    ansible-playbook -i ${ANSIBLE_INVENTORY} ${ANSIBLE_PLAYBOOK} \
                        --extra-vars "APP_VERSION=${env.IMAGE_TAG} db_host=${DB_HOST} db_port=${DB_PORT} env=prod"
                    """
                }
            }
        }
    }
}
