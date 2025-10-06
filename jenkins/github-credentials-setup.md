# GitHub Credentials Setup for tdk928

## Your Repository Configuration

- **GitHub Username**: `tdk928`
- **Repository**: `https://github.com/tdk928/karate-test`
- **Credentials ID**: `github-credentials` (used in Jenkins configuration)

## GitHub Token Configuration

### Step 1: Create GitHub Personal Access Token

1. Go to: https://github.com/settings/tokens
2. Click **Generate new token** → **Generate new token (classic)**
3. Configure the token:
   - **Note**: `Jenkins CI/CD for Karate Project`
   - **Expiration**: Choose appropriate expiration (recommend 1 year)
   - **Select scopes**:
     - ✅ `repo` (Full control of private repositories)
     - ✅ `admin:repo_hook` (Full control of repository hooks)
     - ✅ `read:user` (Read user profile data)

4. Click **Generate token**
5. **Copy the token immediately** (you won't be able to see it again)

### Step 2: Configure Jenkins Credentials

1. **Open Jenkins** → **Manage Jenkins** → **Manage Credentials**
2. **Select Domain**: `Global (unrestricted)`
3. **Click**: `Add Credentials`
4. **Choose Kind**: `Secret text`
5. **Fill in the form**:
   - **Secret**: `[PASTE_YOUR_GITHUB_TOKEN_HERE]`
   - **ID**: `github-credentials`
   - **Description**: `GitHub Personal Access Token for tdk928`
6. **Click**: `OK`

### Step 3: Verify Configuration

1. **Go to**: **Manage Jenkins** → **Configure System**
2. **Find**: `GitHub` section
3. **Add GitHub Server**:
   - **Name**: `GitHub`
   - **API URL**: `https://api.github.com`
   - **Credentials**: Select `github-credentials` from dropdown
4. **Click**: `Test connection`
5. **Verify**: You see "Credentials verified for user tdk928"

## Security Notes

- **Never commit your token** to version control
- **Use environment variables** for sensitive data in production
- **Rotate tokens regularly** for security
- **Use minimal required permissions** for the token

## Alternative: SSH Key Authentication

If you prefer SSH over HTTPS:

1. **Generate SSH key** (if you don't have one):
   ```bash
   ssh-keygen -t ed25519 -C "jenkins@yourcompany.com"
   ```

2. **Add public key to GitHub**:
   - Go to https://github.com/settings/ssh/new
   - Paste your public key content
   - Title: `Jenkins CI/CD`

3. **Configure Jenkins** to use SSH key instead of token

## Testing the Setup

After configuration, test with:

1. **Manual build**: Trigger a build in Jenkins
2. **Webhook test**: Push a commit to your repository
3. **Check logs**: Verify GitHub authentication in build logs

## Troubleshooting

### Token Issues
- Verify token has correct scopes
- Check token hasn't expired
- Ensure credentials ID matches configuration

### Repository Access
- Verify token has access to `tdk928/karate-test`
- Check repository is not private (or token has private repo access)
- Test GitHub API access manually

### Jenkins Connection
- Check Jenkins can reach GitHub API
- Verify firewall/proxy settings
- Check Jenkins logs for authentication errors
