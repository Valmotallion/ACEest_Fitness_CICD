pipeline {
    agent any

    environment {
        DOCKERHUB_CREDENTIALS = credentials('dockerhub-creds')
        SONAR_TOKEN = credentials('sonar-token')
        SONARQUBE_ENV = 'SonarCloud'
        IMAGE_NAME = "valmotallion/aceest_fitness_app"
        IMAGE_TAG = "v1.${BUILD_NUMBER}"
    }

    stages {

        stage('Clean Workspace') {
            steps {
                echo "🧹 Cleaning Jenkins workspace..."
                cleanWs()
            }
        }

        stage('Checkout Source') {
            steps {
                echo "📦 Cloning GitHub repository..."
                git branch: 'main',
                    url: 'https://github.com/Valmotallion/ACEest_Fitness_CICD.git'
            }
        }

        stage('Install Dependencies') {
            steps {
                echo "🐍 Setting up Python virtual environment..."
                sh '''
                # Ensure Python and venv exist
                if ! command -v python3 >/dev/null 2>&1; then
                    echo "⚠️ Python3 not found, installing user-level Python..."
                    pip install --user virtualenv
                fi

                # Create isolated environment (no sudo)
                python3 -m venv venv || python3 -m virtualenv venv
                . venv/bin/activate

                pip install --upgrade pip
                pip install --no-cache-dir flask pytest pytest-cov
                echo "✅ Virtual environment ready and dependencies installed"
                '''
            }
        }

        stage('Run Unit Tests with Pytest') {
            steps {
                echo "🧪 Running Pytest test cases..."
                sh '''
                . venv/bin/activate
                pytest --maxfail=1 --disable-warnings --junitxml=pytest-results.xml --cov=. --cov-report=xml
                '''
            }
            post {
                always {
                    junit 'pytest-results.xml'
                }
            }
        }

        stage('SonarCloud Code Quality Analysis') {
            steps {
                echo "🔍 Running SonarCloud analysis (via Jenkins plugin)..."
                withSonarQubeEnv("${SONARQUBE_ENV}") {
                    sh '''
                    . venv/bin/activate
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

        stage('Wait for SonarCloud Quality Gate') {
            steps {
                timeout(time: 3, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
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
                kubectl apply -f k8s/deployment.yaml || true
                kubectl apply -f k8s/service.yaml || true
                kubectl rollout status deployment/aceest-fitness-deployment
                '''
            }
        }

        stage('Post-Deployment Validation') {
            steps {
                echo "✅ Validating deployment..."
                sh '''
                kubectl get pods -o wide
                kubectl get svc
                '''
            }
        }
    }

    post {
        success {
            echo "🎉 Pipeline executed successfully! Docker image $IMAGE_NAME:$IMAGE_TAG deployed successfully."
        }
        failure {
            echo "❌ Pipeline failed. Check Jenkins logs for detailed errors."
        }
    }
}
