pipeline {
  agent any

  environment {
    IMAGE_NAME = 'lightosita/week9-app'
    IMAGE_TAG  = "${env.BUILD_NUMBER}"
    CREDS      = credentials('dockerhub-creds')
    STACK      = 'week9'
    SERVICE    = 'week9_web'
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

    stage('Deploy') {
      steps {
        script {
          env.PREVIOUS_TAG = sh(
            returnStdout: true,
            script: "docker service inspect $SERVICE --format '{{.Spec.TaskTemplate.ContainerSpec.Image}}' 2>/dev/null | sed 's/@.*//; s/.*://' || true"
          ).trim()
          echo "Previous version: ${env.PREVIOUS_TAG}"
        }
        sh 'docker stack deploy -c docker-stack.yml $STACK'
      }
    }

    stage('Verify') {
      steps {
        sh '''
          HOST_IP=$(hostname -I | awk '{print $1}')
          for i in $(seq 1 36); do
            OK=0
            for j in 1 2 3 4 5 6; do
              curl -s --max-time 5 http://$HOST_IP:8090/health | grep -q "version.:.$IMAGE_TAG.}" && OK=$((OK+1))
            done
            echo "attempt $i: $OK/6 responses are on version $IMAGE_TAG"
            [ "$OK" -eq 6 ] && exit 0
            sleep 5
          done
          echo "Verification failed: version $IMAGE_TAG is not serving traffic"
          exit 1
        '''
      }
    }

stage('Controlled Failure') {
  steps {
    echo 'Simulating a deployment failure for rollback testing'
    sh 'exit 1'
  }
}
  }

  post {
    failure {
      script {
        if (env.PREVIOUS_TAG?.trim()) {
          echo "Deployment failed. Rolling back to version ${env.PREVIOUS_TAG}"
          sh 'IMAGE_TAG=$PREVIOUS_TAG docker stack deploy -c docker-stack.yml $STACK'
        } else {
          echo 'Failure happened before deployment, so there is nothing to roll back.'
        }
      }
    }
    always {
      sh 'docker logout || true'
    }
  }
}
