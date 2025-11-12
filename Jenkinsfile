pipeline {
  agent any

  environment {
    S3_BUCKET = 'agentsachin.live'
    AWS_REGION = 'us-east-1'
  }

  stages {
    stage('Checkout') {
      steps { checkout scm }
    }

    stage('Workspace debug') {
      steps {
        // POSIX-compatible debug step
        sh '''
          echo "===== WORKSPACE ====="
          pwd
          ls -la
          echo "===== RECURSIVE ====="
          ls -R
          echo "====================="
        '''
      }
    }

    stage('Preflight checks') {
      steps {
        // invoke bash explicitly to enable pipefail and strict flags
        sh "bash -lc 'set -euo pipefail; if ! command -v aws >/dev/null 2>&1; then echo \"ERROR: aws CLI not installed on this agent\"; exit 2; fi; if ! command -v git >/dev/null 2>&1; then echo \"ERROR: git not installed on this agent\"; exit 2; fi'"
      }
    }

    stage('Sync to S3') {
      steps {
        withCredentials([
          usernamePassword(credentialsId: 'aws-creds', usernameVariable: 'AWS_ACCESS_KEY_ID', passwordVariable: 'AWS_SECRET_ACCESS_KEY')
        ]) {
          sh """
            bash -lc 'set -euo pipefail
            export AWS_ACCESS_KEY_ID=\"${AWS_ACCESS_KEY_ID}\"
            export AWS_SECRET_ACCESS_KEY=\"${AWS_SECRET_ACCESS_KEY}\"
            export AWS_DEFAULT_REGION=\"${AWS_REGION}\"

            echo \"Syncing workspace -> s3://${S3_BUCKET} (private objects)...\"
            aws s3 sync . s3://${S3_BUCKET} --delete --exclude \".git/*\" --acl private

            echo \"Verifying index.html exists in bucket...\"
            if aws s3api head-object --bucket ${S3_BUCKET} --key index.html >/dev/null 2>&1; then
              echo \"Updating cache-control for index.html...\"
              aws s3 cp s3://${S3_BUCKET}/index.html s3://${S3_BUCKET}/index.html --metadata-directive REPLACE --cache-control \"no-cache, no-store, must-revalidate\" --acl private
            else
              echo \"FATAL: index.html not found in bucket after sync\"
              aws s3 ls s3://${S3_BUCKET} --recursive || true
              exit 1
            fi'
          """
        }
      }
    }

    stage('Invalidate CloudFront') {
      steps {
        withCredentials([
          usernamePassword(credentialsId: 'aws-creds', usernameVariable: 'AWS_ACCESS_KEY_ID', passwordVariable: 'AWS_SECRET_ACCESS_KEY'),
          string(credentialsId: 'cloudfront-id', variable: 'CLOUDFRONT_DIST_ID')
        ]) {
          sh "bash -lc 'set -euo pipefail; export AWS_ACCESS_KEY_ID=\"${AWS_ACCESS_KEY_ID}\"; export AWS_SECRET_ACCESS_KEY=\"${AWS_SECRET_ACCESS_KEY}\"; export AWS_DEFAULT_REGION=\"${AWS_REGION}\"; echo \"Creating CloudFront invalidation for distribution: ${CLOUDFRONT_DIST_ID}\"; aws cloudfront create-invalidation --distribution-id ${CLOUDFRONT_DIST_ID} --paths \"/*\"'"
        }
      }
    }
  }

  post {
    success { echo "🎉 Deployment succeeded: https://agentsachin.live" }
    failure { echo "❌ Deployment failed - check console output" }
  }
}
