pipeline {
    agent any

    environment {
        AWS_DEFAULT_REGION = 'us-east-1'
        S3_BUCKET = 'agentsachin.live'
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/Sachinnaik448/frontend',
                    credentialsId: 'aws-creds'
            }
        }

        stage('Build React') {
            steps {
                sh 'chmod +x build.sh'
                sh './build.sh'
            }
        }

        stage('Deploy to S3 & Invalidate CloudFront') {
            steps {
                withAWS(credentials: 'aws-creds', region: 'us-east-1') {
                    sh 'aws s3 sync build/ s3://$S3_BUCKET --delete'
                    sh 'aws cloudfront create-invalidation --cloudfront-id E3DQ4C4JEV7KNU --paths "/*"'
                }
            }
        }
    }
}
