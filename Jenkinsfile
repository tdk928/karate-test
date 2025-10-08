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
            
            // Send email notification if enabled
            script {
                if (params.SEND_EMAIL && params.EMAIL_RECIPIENTS) {
                    def buildStatus = currentBuild.result ?: 'SUCCESS'
                    sendEmailNotification(params.ENVIRONMENT, buildStatus, params.EMAIL_RECIPIENTS)
                }
            }
            
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

// Send email notification via external service
def sendEmailNotification(environment, status, recipients) {
    echo "📧 Sending email notification via external service..."
    echo "Environment: ${environment}"
    echo "Status: ${status}"
    echo "Recipients: ${recipients}"
    
    try {
        // Parse test results from surefire reports
        def testResults = parseTestResults()
        
        // Build email body with test results
        def emailBody = buildEmailBody(environment, status, testResults)
        
        // Prepare JSON payload for email service
        def payload = groovy.json.JsonOutput.toJson([
            recipients: recipients.split(',').collect { it.trim() },
            subject: "Karate Test Results - ${status} - ${environment.toUpperCase()} - Build #${BUILD_NUMBER}",
            body: emailBody
        ])
        
        // Send HTTP POST request to email service
        def response = sh(
            script: """
                curl -X POST http://your-service/api/send-email \\
                -H 'Content-Type: application/json' \\
                -d '${payload.replace("'", "'\\''")}' \\
                -w '\\n%{http_code}' \\
                -s
            """,
            returnStdout: true
        ).trim()
        
        def lines = response.split('\n')
        def httpCode = lines[-1]
        
        if (httpCode == '200' || httpCode == '201' || httpCode == '204') {
            echo "✅ Email sent successfully! HTTP ${httpCode}"
        } else {
            echo "⚠️ Email service responded with HTTP ${httpCode}"
            echo "Response: ${lines[0..-2].join('\n')}"
        }
        
    } catch (Exception e) {
        echo "❌ Failed to send email notification: ${e.getMessage()}"
        echo "Continuing build despite email failure..."
    }
}

// Parse test results from surefire XML reports
def parseTestResults() {
    def results = [
        total: 0,
        passed: 0,
        failed: 0,
        skipped: 0,
        duration: 0,
        failures: []
    ]
    
    try {
        // Read surefire test results
        def surefireDir = 'target/surefire-reports'
        if (fileExists(surefireDir)) {
            def testFiles = findFiles(glob: "${surefireDir}/TEST-*.xml")
            
            testFiles.each { file ->
                def testXml = readFile(file.path)
                def testsuite = new XmlSlurper().parseText(testXml)
                
                results.total += testsuite.@tests.toInteger()
                results.failed += testsuite.@failures.toInteger()
                results.skipped += testsuite.@skipped.toInteger()
                results.duration += testsuite.@time.toFloat()
                
                // Extract failure details
                testsuite.testcase.each { testcase ->
                    if (testcase.failure.size() > 0) {
                        results.failures << [
                            name: testcase.@name.toString(),
                            classname: testcase.@classname.toString(),
                            message: testcase.failure.@message.toString(),
                            time: testcase.@time.toString()
                        ]
                    }
                }
            }
            
            results.passed = results.total - results.failed - results.skipped
        }
    } catch (Exception e) {
        echo "Warning: Could not parse test results - ${e.getMessage()}"
    }
    
    return results
}

// Build HTML email body with test results
def buildEmailBody(environment, status, testResults) {
    def statusEmoji = status == 'SUCCESS' ? '✅' : (status == 'FAILURE' ? '❌' : '⚠️')
    def statusColor = status == 'SUCCESS' ? '#28a745' : (status == 'FAILURE' ? '#dc3545' : '#ffc107')
    
    def body = """
<!DOCTYPE html>
<html>
<head>
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
        .header { background-color: ${statusColor}; color: white; padding: 20px; border-radius: 5px; }
        .content { padding: 20px; }
        .summary { background-color: #f8f9fa; padding: 15px; border-radius: 5px; margin: 15px 0; }
        .summary-item { display: inline-block; margin: 10px 20px; }
        .summary-label { font-weight: bold; color: #666; }
        .summary-value { font-size: 24px; font-weight: bold; }
        .success { color: #28a745; }
        .failure { color: #dc3545; }
        .skipped { color: #ffc107; }
        .failures { background-color: #fff3cd; padding: 15px; border-left: 4px solid #ffc107; margin: 15px 0; }
        .failure-item { margin: 10px 0; padding: 10px; background-color: #fff; border-radius: 3px; }
        .footer { margin-top: 20px; padding-top: 20px; border-top: 1px solid #ddd; color: #666; font-size: 12px; }
        a { color: #007bff; text-decoration: none; }
    </style>
</head>
<body>
    <div class="header">
        <h1>${statusEmoji} Karate Test Results - ${status}</h1>
        <p>Environment: <strong>${environment.toUpperCase()}</strong> | Build: <strong>#${BUILD_NUMBER}</strong></p>
    </div>
    
    <div class="content">
        <div class="summary">
            <div class="summary-item">
                <div class="summary-label">Total Tests</div>
                <div class="summary-value">${testResults.total}</div>
            </div>
            <div class="summary-item">
                <div class="summary-label">Passed</div>
                <div class="summary-value success">${testResults.passed}</div>
            </div>
            <div class="summary-item">
                <div class="summary-label">Failed</div>
                <div class="summary-value failure">${testResults.failed}</div>
            </div>
            <div class="summary-item">
                <div class="summary-label">Skipped</div>
                <div class="summary-value skipped">${testResults.skipped}</div>
            </div>
            <div class="summary-item">
                <div class="summary-label">Duration</div>
                <div class="summary-value">${String.format('%.2f', testResults.duration)}s</div>
            </div>
        </div>
        
        <h2>Build Information</h2>
        <ul>
            <li><strong>Job:</strong> ${JOB_NAME}</li>
            <li><strong>Build Number:</strong> ${BUILD_NUMBER}</li>
            <li><strong>Build URL:</strong> <a href="${BUILD_URL}">${BUILD_URL}</a></li>
            <li><strong>Git Commit:</strong> ${env.GIT_COMMIT_SHORT ?: 'N/A'}</li>
            <li><strong>Environment:</strong> ${environment}</li>
            <li><strong>Timestamp:</strong> ${env.BUILD_TIMESTAMP}</li>
        </ul>
        
        <h2>Reports</h2>
        <ul>
            <li><a href="${BUILD_URL}artifact/target/karate-reports/karate-summary.html">Karate HTML Report</a></li>
            <li><a href="${BUILD_URL}artifact/target/surefire-reports/">Surefire Reports</a></li>
        </ul>
"""
    
    // Add failure details if any
    if (testResults.failures.size() > 0) {
        body += """
        <div class="failures">
            <h2>❌ Test Failures (${testResults.failures.size()})</h2>
"""
        testResults.failures.each { failure ->
            body += """
            <div class="failure-item">
                <strong>${failure.name}</strong><br>
                <small>${failure.classname}</small><br>
                <code style="color: #dc3545;">${failure.message.replaceAll('<', '&lt;').replaceAll('>', '&gt;')}</code><br>
                <small>Duration: ${failure.time}s</small>
            </div>
"""
        }
        body += """
        </div>
"""
    }
    
    body += """
    </div>
    
    <div class="footer">
        <p>This is an automated message from Jenkins CI/CD Pipeline.</p>
        <p>Jenkins URL: <a href="${JENKINS_URL}">${JENKINS_URL}</a></p>
    </div>
</body>
</html>
"""
    
    return body
}
