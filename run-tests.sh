#!/bin/bash

# Set Java 17 environment
export JAVA_HOME=/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home
export PATH=$JAVA_HOME/bin:$PATH

# Verify Java version
echo "Using Java version:"
java -version

echo ""
echo "Running Karate tests..."

# Run Maven tests with the specified options
if [ $# -eq 0 ]; then
    # No arguments - run all tests
    mvn test
else
    # Pass arguments to Maven
    mvn test "$@"
fi
