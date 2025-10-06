#!/bin/bash

# Jenkins Installation Script for Port 7080
# This script installs Jenkins and configures it to run on port 7080

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Check if running on macOS
check_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        print_status "macOS detected"
        return 0
    else
        print_error "This script is designed for macOS. Please adapt for your OS."
        exit 1
    fi
}

# Check if Homebrew is installed
check_homebrew() {
    if command -v brew &> /dev/null; then
        print_status "Homebrew is installed"
    else
        print_error "Homebrew not found. Please install Homebrew first:"
        echo "  /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        exit 1
    fi
}

# Check Java 17
check_java() {
    if command -v java &> /dev/null; then
        JAVA_VERSION=$(java -version 2>&1 | head -n 1 | cut -d'"' -f2 | cut -d'.' -f1)
        if [ "$JAVA_VERSION" -ge 17 ]; then
            print_status "Java $JAVA_VERSION is compatible"
        else
            print_warning "Java 17+ recommended, found version $JAVA_VERSION"
        fi
    else
        print_warning "Java not found. Installing OpenJDK 17..."
        brew install openjdk@17
        echo 'export PATH="/opt/homebrew/opt/openjdk@17/bin:$PATH"' >> ~/.zshrc
        source ~/.zshrc
    fi
}

# Install Jenkins
install_jenkins() {
    print_info "Installing Jenkins..."
    
    if command -v jenkins &> /dev/null; then
        print_status "Jenkins is already installed"
        jenkins --version
    else
        print_info "Installing Jenkins via Homebrew..."
        brew install jenkins
        
        if [ $? -eq 0 ]; then
            print_status "Jenkins installed successfully"
        else
            print_error "Failed to install Jenkins"
            exit 1
        fi
    fi
}

# Configure Jenkins for port 7080
configure_jenkins_port() {
    print_info "Configuring Jenkins to run on port 7080..."
    
    # Create Jenkins configuration directory if it doesn't exist
    JENKINS_HOME="$HOME/.jenkins"
    mkdir -p "$JENKINS_HOME"
    
    # Set Jenkins port environment variable
    cat > "$HOME/.jenkins/jenkins.properties" << EOF
# Jenkins Configuration for Port 7080
jenkins.model.Jenkins.instance.setSlaveAgentPort(7081)
EOF

    # Create Jenkins startup script with port 7080
    cat > "$HOME/.jenkins/start-jenkins.sh" << EOF
#!/bin/bash

# Set Java environment
export JAVA_HOME=/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home
export PATH=\$JAVA_HOME/bin:\$PATH

# Set Jenkins home
export JENKINS_HOME=\$HOME/.jenkins

# Start Jenkins on port 7080
print_info "Starting Jenkins on port 7080..."
jenkins --httpPort=7080 --prefix=/jenkins
EOF

    chmod +x "$HOME/.jenkins/start-jenkins.sh"
    print_status "Created Jenkins startup script: $HOME/.jenkins/start-jenkins.sh"
}

# Create Jenkins service configuration
create_jenkins_service() {
    print_info "Creating Jenkins service configuration..."
    
    # Create plist file for macOS service
    cat > "$HOME/Library/LaunchAgents/com.jenkins.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.jenkins</string>
    <key>ProgramArguments</key>
    <array>
        <string>$HOME/.jenkins/start-jenkins.sh</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>$HOME/.jenkins/jenkins.log</string>
    <key>StandardErrorPath</key>
    <string>$HOME/.jenkins/jenkins-error.log</string>
    <key>EnvironmentVariables</key>
    <dict>
        <key>JAVA_HOME</key>
        <string>/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home</string>
        <key>JENKINS_HOME</key>
        <string>$HOME/.jenkins</string>
        <key>PATH</key>
        <string>/opt/homebrew/opt/openjdk@17/bin:/usr/local/bin:/usr/bin:/bin</string>
    </dict>
</dict>
</plist>
EOF

    print_status "Created Jenkins service configuration"
}

# Start Jenkins service
start_jenkins() {
    print_info "Starting Jenkins service..."
    
    # Load the service
    launchctl load "$HOME/Library/LaunchAgents/com.jenkins.plist"
    
    # Start the service
    launchctl start com.jenkins
    
    print_status "Jenkins service started"
    
    # Wait a moment for Jenkins to start
    sleep 5
    
    # Check if Jenkins is running
    if curl -s http://localhost:7080 > /dev/null; then
        print_status "Jenkins is running on http://localhost:7080"
    else
        print_warning "Jenkins might still be starting up. Check logs at: $HOME/.jenkins/jenkins.log"
    fi
}

# Create Jenkins management scripts
create_management_scripts() {
    print_info "Creating Jenkins management scripts..."
    
    # Start script
    cat > "$HOME/.jenkins/jenkins-start.sh" << 'EOF'
#!/bin/bash
echo "🚀 Starting Jenkins on port 7080..."
launchctl start com.jenkins
sleep 3
echo "✅ Jenkins should be running at: http://localhost:7080"
echo "📋 Check status with: launchctl list | grep jenkins"
EOF

    # Stop script
    cat > "$HOME/.jenkins/jenkins-stop.sh" << 'EOF'
#!/bin/bash
echo "🛑 Stopping Jenkins..."
launchctl stop com.jenkins
echo "✅ Jenkins stopped"
EOF

    # Status script
    cat > "$HOME/.jenkins/jenkins-status.sh" << 'EOF'
#!/bin/bash
echo "📊 Jenkins Service Status:"
launchctl list | grep jenkins || echo "Jenkins service not found"

echo ""
echo "🌐 Jenkins Web Interface:"
if curl -s http://localhost:7080 > /dev/null; then
    echo "✅ Jenkins is running at: http://localhost:7080"
else
    echo "❌ Jenkins is not responding on port 7080"
fi

echo ""
echo "📋 Jenkins Logs:"
echo "Main log: $HOME/.jenkins/jenkins.log"
echo "Error log: $HOME/.jenkins/jenkins-error.log"
EOF

    # Restart script
    cat > "$HOME/.jenkins/jenkins-restart.sh" << 'EOF'
#!/bin/bash
echo "🔄 Restarting Jenkins..."
launchctl stop com.jenkins
sleep 2
launchctl start com.jenkins
sleep 3
echo "✅ Jenkins restarted"
echo "🌐 Access at: http://localhost:7080"
EOF

    # Make scripts executable
    chmod +x "$HOME/.jenkins/jenkins-start.sh"
    chmod +x "$HOME/.jenkins/jenkins-stop.sh"
    chmod +x "$HOME/.jenkins/jenkins-status.sh"
    chmod +x "$HOME/.jenkins/jenkins-restart.sh"

    print_status "Created management scripts in $HOME/.jenkins/"
}

# Update webhook configuration
update_webhook_config() {
    print_info "Updating webhook configuration for port 7080..."
    
    # Update the webhook setup guide
    sed -i '' 's/your-jenkins-url\/github-webhook\//localhost:7080\/jenkins\/github-webhook\//g' jenkins/github-webhook-setup.md
    
    print_status "Updated webhook configuration for port 7080"
}

# Display final instructions
show_final_instructions() {
    echo ""
    echo "🎉 Jenkins Installation Complete!"
    echo "================================"
    echo ""
    print_info "Jenkins is configured to run on port 7080"
    echo ""
    echo "🌐 Access Jenkins at:"
    echo "   http://localhost:7080"
    echo ""
    echo "🔧 Management Commands:"
    echo "   Start:   $HOME/.jenkins/jenkins-start.sh"
    echo "   Stop:    $HOME/.jenkins/jenkins-stop.sh"
    echo "   Status:  $HOME/.jenkins/jenkins-status.sh"
    echo "   Restart: $HOME/.jenkins/jenkins-restart.sh"
    echo ""
    echo "📋 Initial Setup:"
    echo "1. Open http://localhost:7080 in your browser"
    echo "2. Get initial admin password:"
    echo "   cat $HOME/.jenkins/secrets/initialAdminPassword"
    echo "3. Install suggested plugins"
    echo "4. Create admin user"
    echo "5. Configure GitHub integration"
    echo ""
    echo "🔗 GitHub Webhook URL:"
    echo "   http://localhost:7080/jenkins/github-webhook/"
    echo ""
    echo "📁 Jenkins Home:"
    echo "   $HOME/.jenkins"
    echo ""
    echo "📄 Logs:"
    echo "   Main:   $HOME/.jenkins/jenkins.log"
    echo "   Errors: $HOME/.jenkins/jenkins-error.log"
    echo ""
}

# Main installation function
main() {
    echo "🚀 Jenkins Installation for Port 7080"
    echo "====================================="
    echo ""
    
    check_os
    check_homebrew
    check_java
    install_jenkins
    configure_jenkins_port
    create_jenkins_service
    start_jenkins
    create_management_scripts
    update_webhook_config
    show_final_instructions
}

# Run main function
main "$@"
