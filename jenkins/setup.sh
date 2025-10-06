#!/bin/bash

# Jenkins Setup Script for Karate API Testing Project
# This script helps set up Jenkins with the required plugins and configurations

set -e

echo "🚀 Setting up Jenkins for Karate API Testing..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Check if Jenkins is installed
check_jenkins() {
    if command -v jenkins &> /dev/null; then
        print_status "Jenkins is installed"
        jenkins --version
    elif command -v java &> /dev/null; then
        print_warning "Jenkins not found in PATH, but Java is available"
        print_info "You can install Jenkins using:"
        print_info "  brew install jenkins (on macOS)"
        print_info "  or download from https://jenkins.io/download/"
    else
        print_error "Java not found. Please install Java 17+ first"
        exit 1
    fi
}

# Check Java version
check_java() {
    if command -v java &> /dev/null; then
        JAVA_VERSION=$(java -version 2>&1 | head -n 1 | cut -d'"' -f2 | cut -d'.' -f1)
        if [ "$JAVA_VERSION" -ge 17 ]; then
            print_status "Java version $JAVA_VERSION is compatible"
        else
            print_error "Java 17+ required, found version $JAVA_VERSION"
            exit 1
        fi
    else
        print_error "Java not found"
        exit 1
    fi
}

# Check Maven
check_maven() {
    if command -v mvn &> /dev/null; then
        print_status "Maven is installed"
        mvn --version | head -n 1
    else
        print_warning "Maven not found"
        print_info "Install Maven using: brew install maven (on macOS)"
    fi
}

# Create Jenkins plugins list
create_plugins_list() {
    print_info "Creating Jenkins plugins list..."
    
    cat > jenkins/plugins.txt << EOF
# Required plugins for Karate API Testing
workflow-aggregator
git
github
github-branch-source
maven-plugin
htmlpublisher
email-ext
timestamper
build-timeout
credentials-binding
ws-cleanup
pipeline-stage-view
blueocean
# Optional but recommended
slack
junit
coverage
EOF

    print_status "Created jenkins/plugins.txt with required plugins"
}

# Create Jenkins configuration
create_jenkins_config() {
    print_info "Creating Jenkins configuration..."
    
    cat > jenkins/jenkins.yaml << EOF
jenkins:
  systemMessage: "Karate API Testing Jenkins Instance"
  numExecutors: 2
  scmCheckoutRetryCount: 3
  
  securityRealm:
    local:
      allowsSignup: false
      users:
        - id: "admin"
          password: "admin"

  authorizationStrategy:
    loggedInUsersCanDoAnything:
      allowAnonymousRead: false

  remotingSecurity:
    enabled: true

tool:
  maven:
    installations:
      - name: "Maven-3"
        properties:
          - installSource:
              installers:
                - maven:
                    id: "3.8.6"

  jdk:
    installations:
      - name: "JDK-17"
        properties:
          - installSource:
              installers:
                - zip:
                    url: "https://download.java.net/java/GA/jdk17.0.2/dfd4a8d0985749f896bed50d7138ee7f/8/GPL/openjdk-17.0.2_macos-x64_bin.tar.gz"
                    label: "macOS"

jobs:
  - script: >
      multibranchPipelineJob('karate-api-tests') {
        displayName('Karate API Tests')
        description('Automated API testing with Karate DSL')
        branchSources {
          github {
            id('karate-repo')
            scanCredentialsId('github-credentials')
            repoOwner('tdk928')
            repository('karate-test')
          }
        }
        orphanedItemStrategy {
          discardOldItems {
            numToKeep(10)
          }
        }
      }

credentials:
  system:
    domainCredentials:
      - credentials:
          - basicSSHUserPrivateKey:
              scope: GLOBAL
              id: "github-credentials"
              username: "git"
              description: "GitHub SSH Key"
              privateKeySource:
                directEntry:
                  privateKey: "YOUR_PRIVATE_SSH_KEY_HERE"
EOF

    print_status "Created jenkins/jenkins.yaml configuration"
    print_warning "Update the GitHub token in Jenkins credentials (github-credentials)"
}

# Create GitHub webhook setup instructions
create_webhook_instructions() {
    print_info "Creating GitHub webhook setup instructions..."
    
    cat > jenkins/github-webhook-setup.md << EOF
# GitHub Webhook Setup Instructions

## 1. Configure Webhook in GitHub

1. Go to your GitHub repository
2. Navigate to **Settings** → **Webhooks**
3. Click **Add webhook**
4. Set the following values:
   - **Payload URL**: \`http://your-jenkins-url/github-webhook/\`
   - **Content type**: \`application/json\`
   - **Secret**: (optional, but recommended)
   - **Events**: Select \`Push\` and \`Pull request\`
   - **Active**: ✓

## 2. Test Webhook

1. Make a test commit to your repository
2. Check Jenkins for automatic build trigger
3. Verify the build appears in Jenkins dashboard

## 3. Jenkins GitHub Configuration

1. Go to **Manage Jenkins** → **Configure System**
2. Find **GitHub** section
3. Add GitHub Server:
   - **Name**: \`GitHub\`
   - **API URL**: \`https://api.github.com\`
   - **Credentials**: Add your GitHub token
4. Test connection

## 4. Repository Access

Make sure Jenkins has access to your repository:
- For public repos: No additional setup needed
- For private repos: Add GitHub credentials in Jenkins
EOF

    print_status "Created GitHub webhook setup instructions"
}

# Create email configuration template
create_email_config() {
    print_info "Creating email configuration template..."
    
    cat > jenkins/email-config.xml << EOF
<?xml version='1.1' encoding='UTF-8'?>
<hudson.plugins.emailext.ExtendedEmailPublisher_-DescriptorImpl plugin="email-ext@2.96">
  <smtpServer>smtp.gmail.com</smtpServer>
  <smtpPort>587</smtpPort>
  <charset>UTF-8</charset>
  <defaultSubject>Build \${BUILD_STATUS}: \${PROJECT_NAME} - \${BUILD_NUMBER}</defaultSubject>
  <defaultBody>
    <h2>Build \${BUILD_STATUS}</h2>
    <p>Project: \${PROJECT_NAME}</p>
    <p>Build Number: \${BUILD_NUMBER}</p>
    <p>Environment: \${ENVIRONMENT}</p>
    <p>Git Commit: \${GIT_COMMIT_SHORT}</p>
    <p>Build URL: <a href="\${BUILD_URL}">\${BUILD_URL}</a></p>
    <p>Test Report: <a href="\${BUILD_URL}HTML_Report/">View Test Report</a></p>
    
    <h3>Changes in this build:</h3>
    <ul>
    \${CHANGE_LOG, format="%c", changesFormat="<li>%d [%a] %m</li>"}
    </ul>
    
    <h3>Console Output:</h3>
    <pre>\${BUILD_LOG, maxLines=50}</pre>
  </defaultBody>
  <defaultReplyTo>noreply@yourcompany.com</defaultReplyTo>
  <emergencyReroute></emergencyReroute>
  <defaultRecipients></defaultRecipients>
  <defaultPresendScript></defaultPresendScript>
  <defaultPostsendScript></defaultPostsendScript>
  <defaultClasspath></defaultClasspath>
  <defaultTrigger>
    <email>
      <recipientProviders>
        <hudson.plugins.emailext.plugins.recipients.ListRecipientProvider/>
        <hudson.plugins.emailext.plugins.recipients.DevelopersRecipientProvider/>
        <hudson.plugins.emailext.plugins.recipients.CulpritsRecipientProvider/>
        <hudson.plugins.emailext.plugins.recipients.RequestorRecipientProvider/>
      </recipientProviders>
      <subject>\${DEFAULT_SUBJECT}</subject>
      <body>\${DEFAULT_BODY}</body>
      <recipientList></recipientList>
      <attachmentsPattern></attachmentsPattern>
      <attachBuildLog>false</attachBuildLog>
      <compressBuildLog>false</compressBuildLog>
      <replyTo>\${DEFAULT_REPLYTO}</replyTo>
      <contentType>text/html</contentType>
    </email>
  </defaultTrigger>
  <globalAdminEmail>admin@yourcompany.com</globalAdminEmail>
  <maxAttachmentSize>10</maxAttachmentSize>
  <defaultBodyTemplate></defaultBodyTemplate>
  <maxAttachmentSizeMb>10</maxAttachmentSizeMb>
  <recipientList></recipientList>
  <precedenceBulk>true</precedenceBulk>
  <debugMode>false</debugMode>
  <securityEnabled>false</securityEnabled>
  <useListId>false</useListId>
  <useSsl>true</useSsl>
  <useTls>true</useTls>
  <authentication>
    <userName></userName>
    <password></password>
  </authentication>
</hudson.plugins.emailext.ExtendedEmailPublisher_-DescriptorImpl>
EOF

    print_status "Created email configuration template"
    print_warning "Update SMTP settings and credentials in email-config.xml"
}

# Main setup function
main() {
    echo "🔧 Jenkins Setup for Karate API Testing Project"
    echo "================================================"
    
    # Create jenkins directory if it doesn't exist
    mkdir -p jenkins
    
    # Run checks
    check_java
    check_maven
    check_jenkins
    
    # Create configuration files
    create_plugins_list
    create_jenkins_config
    create_webhook_instructions
    create_email_config
    
    echo ""
    echo "🎉 Jenkins setup files created successfully!"
    echo ""
    echo "📋 Next steps:"
    echo "1. Install Jenkins and required plugins from jenkins/plugins.txt"
    echo "2. Configure Jenkins using jenkins/jenkins.yaml"
    echo "3. Set up GitHub webhook following jenkins/github-webhook-setup.md"
    echo "4. Configure email settings using jenkins/email-config.xml"
    echo "5. Update repository URL in Jenkinsfile and job-config.xml"
    echo ""
    echo "📁 Created files:"
    echo "  - jenkins/plugins.txt"
    echo "  - jenkins/jenkins.yaml"
    echo "  - jenkins/job-config.xml"
    echo "  - jenkins/email-config.xml"
    echo "  - jenkins/github-webhook-setup.md"
    echo ""
    print_info "Don't forget to update the GitHub repository URL and credentials!"
}

# Run main function
main "$@"
