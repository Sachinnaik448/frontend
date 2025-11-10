pipeline {
  agent any
  environment {
    S3_BUCKET = 'amzn-github'
    CF_DIST_ID = 'E2N8V6NKVIOBWW''   // optional
  }
  stages {
    stage('Checkout') {
      steps { checkout scm }
    }
    stage('Install & Build') {
      steps {
        sh 'npm ci'                 // change to your build setup
        sh 'npm run build'          // outputs to build/ (change if needed)
      }
    }
    stage('Upload to S3') {
      steps {
        withCredentials([[
          $class: 'AmazonWebServicesCredentialsBinding',
          credentialsId: 'aws-creds'
        ]]) {
          sh """
            aws s3 sync build/ s3://$S3_BUCKET/ --delete
          """
        }
      }
    }
    stage('Invalidate CloudFront') {
      when { expression { env.CF_DIST_ID != null && env.CF_DIST_ID != '' } }
      steps {
        withCredentials([[
          $class: 'AmazonWebServicesCredentialsBinding',
          credentialsId: 'aws-creds'
        ]]) {
          sh "aws cloudfront create-invalidation --distribution-id $CF_DIST_ID --paths '/*'"
        }
      }
    }
  }
  post {
    success { echo 'Static site deployed to S3 ✅' }
    failure { echo 'Build or deploy failed ❌' }
  }
}
