# Karate Test Project

A Maven project for API testing using Karate DSL with Java 17.

## Prerequisites

- Java 17 (OpenJDK 17)
- Maven 3.6+

## Quick Start

### Option 1: Use the Test Script (Recommended)

```bash
# Run all tests
./run-tests.sh

# Run only login tests
./run-tests.sh -Dkarate.options="--tags @login"

# Run tests for specific environment
./run-tests.sh -Dkarate.env=test
```

### Option 2: Manual Commands

```bash
# Set Java 17 environment
export JAVA_HOME=/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home
export PATH=$JAVA_HOME/bin:$PATH

# Run tests
mvn test

# Run specific tests
mvn test -Dkarate.options="--tags @login"
```

## Project Structure

```
src/test/
├── java/com/example/karate/
│   └── TestRunner.java          # JUnit test runner
└── resources/
    ├── karate-config.js         # Environment configuration
    ├── logback.xml              # Logging configuration
    └── features/
        ├── auth.feature         # Authentication tests
        └── example.feature      # Example tests
```

## Configuration

### Environment Setup (`karate-config.js`)
- `dev`: http://localhost:8082
- `test`: http://localhost:8082  
- `prod`: https://your-prod-api.com (update as needed)

### Test Tags
- `@login`: Login-related tests
- `@auth`: Authentication tests
- `@smoke`: Smoke tests

## Adding New Tests

1. Create new `.feature` files in `src/test/resources/features/`
2. Use Gherkin syntax for test scenarios
3. Add appropriate tags for test organization
4. Update `TestRunner.java` if needed for custom test execution

## Example Test

```gherkin
@auth @login
Feature: User Authentication API

  Scenario: Login with valid credentials
    Given path 'gateway/auth/login'
    And request { "egnOrEik": "9308149045", "password": "9308149045" }
    When method POST
    Then status 200
    And match response.success == true
```

## Troubleshooting

### Java Compatibility Issues
If you get `NoSuchMethodError` or `NoClassDefFoundError`:
1. Ensure you're using Java 17
2. Use the `run-tests.sh` script which sets the correct environment
3. Check that `JAVA_HOME` points to Java 17

### API Connection Issues
1. Verify your API is running on `localhost:8082`
2. Check the `karate-config.js` for correct URLs
3. Ensure network connectivity

## Jenkins CI/CD Integration

This project includes comprehensive Jenkins pipeline configuration for automated testing across dev/test environments.

### Jenkins Pipeline Features

- **Multi-Environment Support**: Dev and Test environment configurations
- **Automated Script Execution**: Runs `./run-tests.sh` with environment-specific parameters
- **HTML Report Publishing**: Automatic test report generation and archiving
- **Email Notifications**: Configurable email alerts (setup required)
- **GitHub Integration**: Automatic builds on code changes via webhooks
- **Build Parameters**: Environment selection and email configuration options

### Quick Jenkins Setup

#### Option 1: Automated Setup (Recommended)
```bash
# Run the Jenkins setup script
./jenkins/setup.sh
```

#### Option 2: Manual Setup

1. **Install Jenkins**:
   ```bash
   # macOS
   brew install jenkins
   
   # Or download from https://jenkins.io/download/
   ```

2. **Install Required Plugins**:
   - Go to **Manage Jenkins** → **Manage Plugins**
   - Install plugins from `jenkins/plugins.txt`:
     - workflow-aggregator
     - git, github, github-branch-source
     - maven-plugin
     - htmlpublisher
     - email-ext
     - timestamper, build-timeout
     - credentials-binding, ws-cleanup

3. **Configure GitHub Integration**:
   - Set up GitHub webhook: `http://your-jenkins-url/github-webhook/`
   - Add GitHub credentials in Jenkins
   - Follow detailed instructions in `jenkins/github-webhook-setup.md`

4. **Create Pipeline Job**:
   - New Item → Pipeline
   - Use `Jenkinsfile` from this repository
   - Configure SCM to point to your GitHub repository

### Jenkins Pipeline Usage

#### Running Builds

```bash
# Trigger build via Jenkins UI
# Select environment: dev or test
# Optionally enable email notifications
```

#### Build Parameters

- **ENVIRONMENT**: Choose between `dev` or `test`
- **SEND_EMAIL**: Enable/disable email notifications
- **EMAIL_RECIPIENTS**: Comma-separated email addresses

#### Build Stages

1. **Checkout**: Git repository checkout with commit info
2. **Environment Setup**: Java/Maven verification and script preparation
3. **Dependencies**: Maven dependency resolution
4. **Run Tests**: Execute Karate tests using `./run-tests.sh`
5. **Test Results Analysis**: Parse and archive test results

### Email Configuration

Email notifications are currently implemented as empty placeholders. To enable:

1. Configure SMTP settings in Jenkins
2. Update `jenkins/email-config.xml` with your email server details
3. Enable email notifications in build parameters

```groovy
// Email step implementation (empty for now)
def sendEmailNotification(environment, status, recipients) {
    echo "📧 Email notification step (empty implementation)"
    // TODO: Implement actual email sending logic
}
```

### Jenkins Files Structure

```
jenkins/
├── setup.sh                    # Automated Jenkins setup script
├── plugins.txt                 # Required Jenkins plugins list
├── jenkins.yaml               # Jenkins configuration as code
├── job-config.xml             # Pipeline job configuration
├── email-config.xml           # Email notification template
└── github-webhook-setup.md    # GitHub webhook setup guide
```

### Environment Configuration

The pipeline supports multiple environments with different configurations:

- **dev**: `http://localhost:8082` (default)
- **test**: `http://localhost:8082` (configurable)

Update environment URLs in `src/test/resources/karate-config.js` as needed.

## Useful Commands

```bash
# Clean and compile
mvn clean compile

# Run specific test by name
mvn test -Dtest=TestRunner#testAll

# Generate test reports
mvn test -Dkarate.options="--tags @login"

# Debug mode
mvn test -Dkarate.options="--tags @login" -X

# Jenkins setup
./jenkins/setup.sh

# Test Jenkins pipeline locally (if Jenkins CLI available)
jenkins-cli build karate-api-tests -p ENVIRONMENT=dev -p SEND_EMAIL=false
```