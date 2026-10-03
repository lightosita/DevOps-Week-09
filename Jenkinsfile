pipeline {
  agent any

  environment {
    IMAGE_NAME = 'lightosita/week9-app'
    IMAGE_TAG  = "${env.BUILD_NUMBER}"
    CREDS      = credentials('dockerhub-creds')
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Build') {
      steps {
        sh 'python3 -m py_compile app.py'
      }
    }

    stage('Test') {
      steps {
        sh '''
          docker run --rm -v "$WORKSPACE":/app -w /app \
            -e PYTHONDONTWRITEBYTECODE=1 -e PIP_ROOT_USER_ACTION=ignore \
            python:3.12-slim \
            sh -c "pip install -q -r requirements-dev.txt && pytest -v -p no:cacheprovider"
        '''
      }
    }

    stage('Package') {
      steps {
        sh 'docker build --build-arg APP_VERSION=$IMAGE_TAG -t $IMAGE_NAME:$IMAGE_TAG -t $IMAGE_NAME:latest .'
      }
    }

    stage('Push') {
      steps {
        sh 'echo $CREDS_PSW | docker login -u $CREDS_USR --password-stdin'
        sh 'docker push $IMAGE_NAME:$IMAGE_TAG'
        sh 'docker push $IMAGE_NAME:latest'
      }
    }
  }

  post {
    always {
      sh 'docker logout || true'
    }
  }
}
