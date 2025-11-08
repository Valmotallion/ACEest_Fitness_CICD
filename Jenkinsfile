pipeline {
    agent any

    environment {
        // Credentials
        DOCKERHUB_CREDENTIALS = credentials('dockerhub-creds')
        SONAR_TOKEN = credentials('sonar-token')

        // SonarCloud configuration
        SONARQUBE_ENV = 'SonarCloud'

        // Docker image configuration
        IMAGE_NAME = "valmotallion/aceest_fitness_app"
        IMAGE_TAG = "v1.${BUILD_NUMBER}"
    }

    stages {

        stage('Checkout Source') {
            steps {
                echo "📦 Cloning GitHub repository..."
                git branch: 'main',
                    url: 'https://github.com/Valmotallion/ACEest_Fitness_CICD.git'
            }
        }

        stage('Install Dependencies') {
            steps {
                echo "🐍 Setting up Python environment..."
                sh '''
                    apt-get update -y
                    apt-get install -y python3 python3-pip
                    pip3 install --upgrade pip
                    pip3 install flask pytest pytest-cov sonar-scanner
                '''
            }
        }

        stage('Run Unit Tests with Pytest') {
            steps {
                echo "🧪 Running Pytest test cases..."
                sh '''
                    pytest --maxfail=1 --disable-warnings -q --cov=. --cov-report=xml
                '''
            }
            post {
                always {
                    junit '**/pytest*.xml'
                }
            }
        }

        stage('SonarCloud Code Quality Analysis') {
            steps {
                echo "🔍 Running SonarCloud Analysis..."
                withSonarQubeEnv("${SONARQUBE_ENV}") {
                    sh '''
                        sonar-scanner \
                          -Dsonar.organization=valmotallion \
                          -Dsonar.projectKey=Valmotallion_ACEest_Fitness_CICD \
                          -Dsonar.sources=. \
                          -Dsonar.python.coverage.reportPaths=coverage.xml \
                          -Dsonar.host.url=https://sonarcloud.io \
                          -Dsonar.login=${SONAR_TOKEN}
                    '''
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                echo "🐳 Building Docker image..."
                sh '''
                    docker build -t $IMAGE_NAME:$IMAGE_TAG .
                    docker tag $IMAGE_NAME:$IMAGE_TAG $IMAGE_NAME:latest
                '''
            }
        }

        stage('Push to Docker Hub') {
            steps {
                echo "📤 Pushing Docker image to Docker Hub..."
                sh '''
                    echo "${DOCKERHUB_CREDENTIALS_PSW}" | docker login -u "${DOCKERHUB_CREDENTIALS_USR}" --password-stdin
                    docker push $IMAGE_NAME:$IMAGE_TAG
                    docker push $IMAGE_NAME:latest
                '''
            }
        }

        stage('Deploy to Minikube') {
            steps {
                echo "🚀 Deploying to Minikube cluster..."
                sh '''
                    kubectl set image deployment/aceest-fitness-deployment aceest-fitness-container=$IMAGE_NAME:$IMAGE_TAG --record || true
                    kubectl apply -f k8s/deployment.yaml
                    kubectl apply -f k8s/service.yaml
                    kubectl rollout status deployment/aceest-fitness-deployment
                '''
            }
        }

        stage('Post-Deployment Validation') {
            steps {
                echo "✅ Validating deployment..."
                sh 'kubectl get pods -o wide'
                sh 'kubectl get svc'
            }
        }
    }

    post {
        success {
            echo "🎉 Pipeline executed successfully! Docker image $IMAGE_NAME:$IMAGE_TAG deployed."
        }
        failure {
            echo "❌ Pipeline failed. Check the Jenkins console logs for errors."
        }
    }
}
