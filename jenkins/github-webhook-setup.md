# GitHub Webhook Setup Instructions

## 1. Configure Webhook in GitHub

1. Go to your GitHub repository: https://github.com/tdk928/karate-test
2. Navigate to **Settings** → **Webhooks**
3. Click **Add webhook**
4. Set the following values:
   - **Payload URL**: `http://localhost:7080/jenkins/github-webhook/`
   - **Content type**: `application/json`
   - **Secret**: (optional, but recommended)
   - **Events**: Select `Push` and `Pull request`
   - **Active**: ✓

## 2. Test Webhook

1. Make a test commit to your repository
2. Check Jenkins for automatic build trigger
3. Verify the build appears in Jenkins dashboard

## 3. Jenkins GitHub Configuration

1. Go to **Manage Jenkins** → **Configure System**
2. Find **GitHub** section
3. Add GitHub Server:
   - **Name**: `GitHub`
   - **API URL**: `https://api.github.com`
   - **Credentials**: Add your GitHub token (see section below)
4. Test connection

## 4. GitHub Token Setup

### Create GitHub Personal Access Token

1. Go to GitHub → **Settings** → **Developer settings** → **Personal access tokens** → **Tokens (classic)**
2. Click **Generate new token (classic)**
3. Select scopes:
   - `repo` (full repository access)
   - `admin:repo_hook` (for webhooks)
   - `read:user` (for user information)
4. Copy the generated token

### Configure Jenkins Credentials

1. In Jenkins, go to **Manage Jenkins** → **Manage Credentials**
2. Select **System** → **Global credentials**
3. Click **Add Credentials**
4. Choose **Secret text**
5. Fill in:
   - **Secret**: Paste your GitHub token
   - **ID**: `github-credentials` (this must match the ID in job-config.xml)
   - **Description**: `GitHub Personal Access Token for tdk928`
6. Click **OK**

## 5. Repository Access

Your repository https://github.com/tdk928/karate-test is now configured for:
- Automatic builds on push/PR events
- Test execution in dev/test environments
- HTML report publishing
- Email notifications (when configured)

## 6. Test the Integration

1. Make a small change to your repository
2. Push the changes
3. Check Jenkins for automatic build trigger
4. Verify the build completes successfully
5. Check the test reports are published

## Troubleshooting

### Webhook Not Triggering
- Verify webhook URL is accessible from GitHub
- Check Jenkins logs for webhook delivery attempts
- Ensure Jenkins GitHub plugin is installed

### Authentication Issues
- Verify GitHub token has correct permissions
- Check credentials ID matches in configuration
- Test GitHub connection in Jenkins system configuration

### Build Failures
- Check Java 17 is available on Jenkins agent
- Verify Maven is installed
- Check `run-tests.sh` script permissions
