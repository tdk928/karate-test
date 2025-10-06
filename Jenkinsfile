pipeline {
    agent any
    
    parameters {
        choice(
            name: 'ENVIRONMENT',
            choices: ['dev', 'test'],
            description: 'Target environment for testing'
        )
        booleanParam(
            name: 'SEND_EMAIL',
            defaultValue: false,
            description: 'Send email notifications after build'
        )
        string(
            name: 'EMAIL_RECIPIENTS',
            defaultValue: '',
            description: 'Comma-separated list of email recipients'
        )
    }
    
    environment {
        KARATE_ENV = "${params.ENVIRONMENT}"
        JAVA_HOME = '/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home'
        PATH = "${JAVA_HOME}/bin:${PATH}"
        BUILD_TIMESTAMP = sh(script: 'date +%Y%m%d_%H%M%S', returnStdout: true).trim()
    }
    
    stages {
        stage('Checkout') {
            steps {
                echo "Checking out code from repository..."
                checkout scm
                
                script {
                    env.GIT_COMMIT_SHORT = sh(
                        script: 'git rev-parse --short HEAD',
                        returnStdout: true
                    ).trim()
                    env.BUILD_DISPLAY_NAME = "${BUILD_NUMBER}-${env.GIT_COMMIT_SHORT}-${params.ENVIRONMENT}"
                    currentBuild.displayName = env.BUILD_DISPLAY_NAME
                }
                
                echo "Build: ${env.BUILD_DISPLAY_NAME}"
                echo "Environment: ${params.ENVIRONMENT}"
            }
        }
        
        stage('Environment Setup') {
            steps {
                echo "Setting up environment for ${params.ENVIRONMENT}..."
                
                script {
                    // Verify Java installation
                    sh '''
                        echo "Java Version:"
                        java -version
                        echo ""
                        echo "Maven Version:"
                        mvn -version
                        echo ""
                        echo "Current Directory:"
                        pwd
                        echo ""
                        echo "Directory Contents:"
                        ls -la
                    '''
                }
                
                // Make run script executable
                sh 'chmod +x run-tests.sh'
            }
        }
        
        stage('Dependencies') {
            steps {
                echo "Resolving Maven dependencies..."
                sh 'mvn clean compile test-compile'
            }
        }
        
        stage('Run Tests') {
            steps {
                echo "Running Karate tests for ${params.ENVIRONMENT} environment..."
                
                script {
                    try {
                        // Run the test script with environment parameter
                        sh "./run-tests.sh -Dkarate.env=${params.ENVIRONMENT}"
                        
                        // Archive test results
                        archiveArtifacts artifacts: 'target/karate-reports/**/*', fingerprint: true
                        
                        // HTML reports are available at: target/karate-reports/karate-summary.html
                        echo "HTML test reports available at: target/karate-reports/karate-summary.html"
                        
                        // Set build status
                        env.TEST_STATUS = 'SUCCESS'
                        env.TEST_RESULTS = 'All tests passed successfully'
                        
                    } catch (Exception e) {
                        // Archive test results even on failure
                        archiveArtifacts artifacts: 'target/karate-reports/**/*', fingerprint: true, allowEmptyArchive: true
                        
                        // HTML reports available even on failure
                        echo "HTML test reports available at: target/karate-reports/karate-summary.html"
                        
                        env.TEST_STATUS = 'FAILURE'
                        env.TEST_RESULTS = 'Some tests failed'
                        throw e
                    }
                }
            }
        }
        
        stage('Test Results Analysis') {
            steps {
                echo "Analyzing test results..."
                
                script {
                    // Try to extract test results from Karate summary
                    try {
                        def summaryFile = 'target/karate-reports/karate-summary.html'
                        if (fileExists(summaryFile)) {
                            def summaryContent = readFile summaryFile
                            
                            // Extract basic statistics (this is a simple approach)
                            if (summaryContent.contains('failed')) {
                                env.TEST_FAILURES = 'Yes'
                            } else {
                                env.TEST_FAILURES = 'No'
                            }
                            
                            echo "Test summary available at: ${BUILD_URL}HTML_Report/"
                        } else {
                            echo "Test summary file not found"
                            env.TEST_FAILURES = 'Unknown'
                        }
                    } catch (Exception e) {
                        echo "Could not analyze test results: ${e.getMessage()}"
                        env.TEST_FAILURES = 'Unknown'
                    }
                }
            }
        }
    }
    
    post {
        always {
            echo "Build completed with status: ${currentBuild.result ?: 'SUCCESS'}"
            
            // Archive build artifacts
            archiveArtifacts artifacts: 'target/karate-reports/**/*', fingerprint: true, allowEmptyArchive: true
            archiveArtifacts artifacts: 'target/surefire-reports/**/*', fingerprint: true, allowEmptyArchive: true
            
            // Clean up workspace if needed
            cleanWs()
        }
        
        success {
            echo "✅ Build succeeded!"
            script {
                env.BUILD_STATUS = 'SUCCESS'
                env.BUILD_MESSAGE = "Karate tests passed successfully for ${params.ENVIRONMENT} environment"
            }
        }
        
        failure {
            echo "❌ Build failed!"
            script {
                env.BUILD_STATUS = 'FAILURE'
                env.BUILD_MESSAGE = "Karate tests failed for ${params.ENVIRONMENT} environment"
            }
        }
        
        unstable {
            echo "⚠️ Build unstable!"
            script {
                env.BUILD_STATUS = 'UNSTABLE'
                env.BUILD_MESSAGE = "Karate tests completed with issues for ${params.ENVIRONMENT} environment"
            }
        }
        
        cleanup {
            echo "Cleaning up build workspace..."
        }
    }
}

// Email notification step (empty implementation for now)
def sendEmailNotification(environment, status, recipients) {
    echo "📧 Email notification step (empty implementation)"
    echo "Environment: ${environment}"
    echo "Status: ${status}"
    echo "Recipients: ${recipients}"
    
    // TODO: Implement actual email sending logic here
    // This could include:
    // - Using Email Extension Plugin
    // - Custom SMTP configuration
    // - HTML email templates with test results
    // - Attachment of test reports
    
    echo "Email notification would be sent here..."
}
