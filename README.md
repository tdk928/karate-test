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
```