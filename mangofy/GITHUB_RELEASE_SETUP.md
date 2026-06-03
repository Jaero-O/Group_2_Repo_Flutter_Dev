# GitHub Release Setup Guide

This guide explains how to set up GitHub Secrets and create your first automated release.

## Prerequisites

✅ Keystore file already created at `android/release-key.keystore`  
✅ GitHub Actions workflow configured at `.github/workflows/release.yml`

## Step 1: Add GitHub Secrets

GitHub Secrets store sensitive data (passwords, tokens) securely without exposing them in logs or code.

### Android Keystore Password

1. Go to: **GitHub → Settings → Secrets and variables → Actions**
2. Click **New repository secret**
3. Create a secret with:
   - **Name:** `KEYSTORE_PASSWORD`
   - **Value:** `mangofy@release` (the password from keystore generation)
4. Click **Add secret**

### iOS Signing (Optional - for later when setting up Apple Developer)

When you set up iOS signing, add these secrets:

- **Name:** `APPLE_TEAM_ID` → **Value:** `<Your Apple Team ID>`
- **Name:** `APPLE_ID` → **Value:** `<Your Apple Developer email>`

## Step 2: Commit and Push Keystore to Repository

The keystore file needs to be in the repository for GitHub Actions to access it during builds.

```bash
cd c:\Users\alleiah\Downloads\_dp1\Group_2_Repo_Flutter_Dev\mangofy
git add android/release-key.keystore
git commit -m "Add Android signing keystore"
git push origin main
```

⚠️ **Security Note:** The keystore file is now in your repo (visible to anyone with access). For production apps:
- Store keystore in GitHub Secrets as base64
- Or: Use secure key management (AWS KMS, HashiCorp Vault, etc.)

## Step 3: Create Your First Release

### Option A: Command Line (Recommended)

```bash
# Update version in pubspec.yaml
# Example: 1.0.0 → 1.0.1

# Stage and commit
git add pubspec.yaml
git commit -m "Bump version to 1.0.1"

# Create a release tag
git tag v1.0.1

# Push commits and tags to GitHub
git push origin main
git push origin v1.0.1
```

### Option B: GitHub Web UI

1. Go to your repo → **Releases** tab
2. Click **Create a new release**
3. Set **Tag version** to `v1.0.1`
4. Fill in title and description
5. Click **Publish release**

## Step 4: Monitor Build Progress

1. Go to your repo → **Actions** tab
2. You should see a workflow running named "Build and Release"
3. Watch the progress as it builds APK and IPA
4. Once complete, go to **Releases** tab to download artifacts

## Release Naming Convention

Use semantic versioning for tags:
- `v1.0.0` — Initial release
- `v1.0.1` — Bug fixes
- `v1.1.0` — New features
- `v2.0.0` — Major breaking changes

## Workflow Steps Explained

### Android Build Job (Ubuntu Runner)
1. Checks out code
2. Installs Flutter SDK
3. Gets dependencies
4. Builds APK with: `flutter build apk --release --no-tree-shake-icons`
5. Uploads APK as artifact

### iOS Build Job (macOS Runner)
1. Checks out code
2. Installs Flutter SDK
3. Gets dependencies
4. Builds IPA with: `flutter build ios --release`
5. Packages IPA as artifact

### Release Job (Ubuntu Runner)
1. Downloads APK and IPA artifacts
2. Creates GitHub Release
3. Attaches both files for download
4. Adds auto-generated release notes

## Troubleshooting

### Build Fails: "Keystore file not found"
- **Fix:** Ensure `android/release-key.keystore` is committed to git
- Run: `git add android/release-key.keystore && git push origin main`

### Build Fails: "KEYSTORE_PASSWORD not set"
- **Fix:** Ensure `KEYSTORE_PASSWORD` secret is added in GitHub Settings → Secrets
- The secret value must be: `mangofy@release`

### iOS Build Fails (Expected for now)
- iOS build requires macOS runner and Apple Developer signing
- Set up Apple Developer account first, then add iOS secrets
- For now, Android APK builds should work

### Release Not Created
- Check Actions tab for workflow errors
- Ensure tag format is `v*` (e.g., `v1.0.1`)
- Latest workflow log shows detailed error messages

## Next Steps

1. ✅ Set GitHub Secrets (KEYSTORE_PASSWORD)
2. ✅ Commit keystore to repo
3. ✅ Create release tag: `git tag v1.0.0`
4. ✅ Push: `git push origin main --tags`
5. ✅ Monitor build in Actions tab
6. ✅ Download from Releases page

## For iOS (Later)

Once you set up Apple Developer account:
1. Add iOS signing secrets to GitHub
2. Update workflow to configure iOS signing
3. Next release will include IPA file

---

**Questions?** Check GitHub Actions logs for detailed error messages.
