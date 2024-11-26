pipeline {
    agent any
    
    parameters {
        booleanParam(name: 'PLAN_TERRAFORM', defaultValue: false, description: 'Check to plan Terraform changes')
        booleanParam(name: 'APPLY_TERRAFORM', defaultValue: false, description: 'Check to apply Terraform changes')
        booleanParam(name: 'DESTROY_TERRAFORM', defaultValue: false, description: 'Check to apply Terraform changes')
    }
    
    environment {
        // Define GitHub credentials as environment variables
        GITHUB_CREDENTIALS = credentials('Github-zoorroborrolol')
    }
    
    stages {
        stage('Clone Repository') {
            steps {
                // Use GitHub credentials to access the repo
                git credentialsId: 'Github-zoorroborrolol', url: 'https://github.com/zorroborrolol/devops-qr-code.git'
            }
        }
        
        stage('Install Terraform') {
            steps {
                script {
                    // Install Terraform if not already installed
                    sh 'curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -'
                    sh 'sudo apt-add-repository "deb https://apt.releases.hashicorp.com $(lsb_release -cs) main"'
                    sh 'sudo apt-get update && sudo apt-get install terraform'
                }
            }
        }
        
        stage('Terraform Init') {
            steps {
                script {
                    withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'AWS-access-creds']]) {
                        // Run Terraform init with AWS credentials
                        sh 'terraform init'
                    }
                }
            }
        }
        
        stage('Terraform Validate') {
            steps {
                script {
                    withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'AWS-access-creds']]) {
                        // Run Terraform validate with AWS credentials
                        sh 'terraform validate'
                    }
                }
            }
        }
        
        stage('Terraform Plan') {
            steps {
                script {
                    if (params.PLAN_TERRAFORM) {
                        withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'AWS-access-creds']]) {
                            // Run Terraform plan with AWS credentials
                            sh 'terraform plan -out=tfplan'
                        }
                    }
                }
            }
        }
        
        stage('Terraform Apply') {
            steps {
                script {
                    if (params.APPLY_TERRAFORM) {
                        withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'AWS-access-creds']]) {
                            // Run Terraform apply with AWS credentials
                            sh 'terraform apply -auto-approve tfplan'
                        }
                    }
                }
            }
        }
        
        stage('Terraform Destroy') {
            steps {
                script {
                    if (params.DESTROY_TERRAFORM) {
                        withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'AWS-access-creds']]) {
                            // Run Terraform destroy with AWS credentials
                            sh 'terraform destroy -auto-approve'
                        }
                    }
                }
            }
        }
    }
}


//sudo visudo
/*add this: jenkins ALL=(ALL) NOPASSWD: /usr/bin/apt-get, /usr/bin/curl, /usr/bin/unzip*/
