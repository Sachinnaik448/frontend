pipeline {
  agent any

  environment {
    S3_BUCKET = 'agentsachin.live'       // <- change to your bucket
    CLOUDFRONT_DIST_ID = 'E3DQ4C4JEV7KNU' // <- change
    AWS_REGION = 'us-east-1'
  }

  stages {
    stage('Checkout') {
      steps { checkout scm }
    }

    stage('Debug workspace') {
      steps {
        sh 'pwd && echo "---- files in workspace ----" && ls -la && echo "---- recursive ----" && ls -R'
      }
    }

    stage('Sync to S3') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'aws-creds', usernameVariable: 'AWS_ACCESS_KEY_ID', passwordVariable: 'AWS_SECRET_ACCESS_KEY')]) {
          sh '''
            export AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
            export AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}
            export AWS_DEFAULT_REGION=${AWS_REGION}

            # Sync repo root to S3 (exclude .git). Adjust path if your site is in a subfolder.
            aws s3 sync . s3://${S3_BUCKET} --delete --exclude ".git/*" --acl public-read

            # Ensure index.html is not cached heavily
            if aws s3api head-object --bucket ${S3_BUCKET} --key index.html >/dev/null 2>&1; then
              aws s3 cp s3://${S3_BUCKET}/index.html s3://${S3_BUCKET}/index.html --metadata-directive REPLACE --cache-control "no-cache, no-store, must-revalidate" --acl public-read
            else
              echo "index.html not found in bucket after sync"
            fi
          '''
        }
      }
    }

    stage('CloudFront Invalidate') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'aws-creds', usernameVariable: 'AWS_ACCESS_KEY_ID', passwordVariable: 'AWS_SECRET_ACCESS_KEY')]) {
          sh '''
            export AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
            export AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}
            export AWS_DEFAULT_REGION=${AWS_REGION}
            aws cloudfront create-invalidation --distribution-id ${CLOUDFRONT_DIST_ID} --paths "/*"
          '''
        }
      }
    }
  }

  post {
    success { echo "Deployed to https://www.yourdomain.com" }
    failure { echo "Deployment failed" }
  }
}
