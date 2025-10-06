# Quick Jenkins Setup Guide for Karate Pipeline

## 🚀 Jenkins is Ready!
- **URL**: http://localhost:7080
- **Status**: ✅ Running with all plugins installed

## 📋 Step-by-Step Setup:

### Step 1: Create Pipeline Job
1. Go to http://localhost:7080
2. Click **"New Item"**
3. Name: `karate-api-tests`
4. Type: **Pipeline**
5. Click **OK**

### Step 2: Configure Pipeline
1. **General Tab**:
   - ✅ Check "This project is parameterized"
   - Add 3 parameters (see below)

2. **Pipeline Tab**:
   - Definition: **Pipeline script from SCM**
   - SCM: **Git**
   - Repository URL: `https://github.com/tdk928/karate-test.git`
   - Credentials: Add your GitHub token (see below)
   - Script Path: `Jenkinsfile`

3. **Build Triggers Tab**:
   - ✅ GitHub hook trigger for GITScm polling

### Step 3: Add Parameters
Click **"Add Parameter"** → **"Choice Parameter"**:
- **Name**: `ENVIRONMENT`
- **Choices** (one per line):
  ```
  dev
  test
  ```

Click **"Add Parameter"** → **"Boolean Parameter"**:
- **Name**: `SEND_EMAIL`
- **Default Value**: `false`

Click **"Add Parameter"** → **"String Parameter"**:
- **Name**: `EMAIL_RECIPIENTS`
- **Default Value**: (leave empty)

### Step 4: Add GitHub Credentials
1. Click **"Add"** next to Credentials
2. **Kind**: `Secret text`
3. **Secret**: `[Your GitHub Personal Access Token]`
4. **ID**: `github-credentials`
5. **Description**: `GitHub Token for tdk928`
6. Click **Add**

### Step 5: Test the Pipeline
1. Click **"Save"**
2. Click **"Build with Parameters"**
3. Select `ENVIRONMENT = dev`
4. Click **"Build"**
5. Watch the build progress!

## 🎯 Expected Results:
- ✅ Build should start automatically
- ✅ Tests will run using your `./run-tests.sh` script
- ✅ HTML reports will be published
- ✅ Build status will be displayed

## 🔧 Troubleshooting:
- **Build fails**: Check console output for errors
- **GitHub auth fails**: Verify your token has correct permissions
- **Tests fail**: Ensure your API is running on localhost:8082

## 📊 After First Build:
- View test reports in the build page
- Check "HTML Report" link for detailed results
- Configure email notifications if needed

## 🚀 Next Steps:
1. Set up GitHub webhook for automatic builds
2. Configure email notifications
3. Add more test environments if needed
