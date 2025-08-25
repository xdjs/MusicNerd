
# ✅ Xcode Cloud Setup Checklist (Music Nerd iOS)

## 1. Pre-Setup
- [x] You’re enrolled in the **Apple Developer Program**
- [ ] Your project is under **source control (Git)**, hosted on:
  - [x] GitHub
  - [ ] Bitbucket
  - [ ] GitLab
  - [ ] Custom Git (URL with SSH or HTTPS)
- [ ] Your repository is linked to your **Apple Developer account**

## 2. Enable Xcode Cloud
- [ ] Open your Xcode project
- [ ] Go to **Product → Build with Xcode Cloud**
- [ ] Choose your **team** and **repo**
- [ ] Select the right **branch** (e.g. `main`)
- [ ] Confirm **Xcode Cloud is enabled** in the Apple Developer portal

## 3. Configure the Workflow
- [ ] Select your **scheme** (e.g. `MusicNerd`)
- [ ] Choose your **platform + device type** (e.g. iOS 18, iPhone 15)
- [ ] Enable:
  - [ ] `Build`
  - [ ] `Analyze` (optional)
  - [ ] `Test`
  - [ ] `Archive` (for TestFlight builds)
- [ ] Add **Test Actions**:
  - [ ] Unit tests (run in parallel)
  - [ ] UI tests (sequential – optional nightly or release)
- [ ] Define **Triggers**:
  - [ ] On commit to `main`
  - [ ] Nightly schedule
  - [ ] Manual runs
  - [ ] Tag-based (e.g. `release/*`)

## 4. Environment and Secrets
- [ ] Set up any required **Environment Variables**
- [ ] Add **Code Signing Certificates and Profiles** (usually handled automatically)
- [ ] Optionally set **Build Arguments**, like test filters

## 5. Notifications and Reports
- [ ] Enable email or Slack notifications (optional)
- [ ] Choose test result visibility (developer only or whole team)

## 6. Run and Monitor
- [ ] Run a manual build to test the pipeline
- [ ] Confirm results:
  - [ ] Build success
  - [ ] Unit test results
  - [ ] UI test screenshots/logs
- [ ] Review **build logs**, timing, and any failures
