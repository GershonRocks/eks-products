# Security Configuration Guide

## Important Security Notice

This repository's scripts have been updated to use environment variables for sensitive credentials. **Never commit passwords or secrets to version control.**

## Jenkins Scripts Configuration

All Jenkins automation scripts now require the `JENKINS_PASSWORD` environment variable to be set before running.

### Setting Jenkins Password

Before running any Jenkins script, export the password:

```bash
export JENKINS_PASSWORD="your-actual-jenkins-password"
export JENKINS_USER="admin"  # Optional, defaults to 'admin'
```

### Affected Scripts

The following scripts now require environment variables:
- `jenkins-plugin-installer.sh`
- `verify-plugins.sh`
- `remote-plugin-installer.sh`
- `install-plugins-api.sh`
- `install-plugins-direct.sh`
- `setup-basic-pipeline.sh`

### Running Scripts Securely

Example usage:
```bash
# Set credentials
export JENKINS_PASSWORD="your-secure-password"

# Run the script
./jenkins-plugin-installer.sh
```

## Other Credentials to Secure

### 1. Redis Password
Currently hardcoded in `.env` file. Should be moved to environment variables:
```bash
export REDIS_PASSWORD="your-redis-password"
```

### 2. AWS Credentials
Use AWS CLI configuration or IAM roles:
```bash
aws configure
# Or use environment variables
export AWS_ACCESS_KEY_ID="your-key"
export AWS_SECRET_ACCESS_KEY="your-secret"
```

### 3. Terraform Variables
Update `terraform.tfvars` to use environment variables:
```bash
export TF_VAR_jenkins_admin_password="your-password"
```

## Security Best Practices

1. **Never commit credentials** to version control
2. **Use environment variables** for all sensitive data
3. **Rotate passwords regularly**
4. **Use secrets management tools** (AWS Secrets Manager, HashiCorp Vault)
5. **Add sensitive files to .gitignore**:
   ```
   .env
   *.tfvars
   terraform.tfstate*
   ```

## Git History Cleanup

If credentials were previously committed, clean git history:

```bash
# Using BFG Repo-Cleaner (recommended)
bfg --replace-text passwords.txt repo.git

# Or using git filter-branch
git filter-branch --force --index-filter \
  "git rm --cached --ignore-unmatch .env" \
  --prune-empty --tag-name-filter cat -- --all
```

## Credential Rotation Checklist

- [ ] Change Jenkins admin password
- [ ] Update Redis password
- [ ] Rotate AWS access keys
- [ ] Update any API tokens
- [ ] Clear git history of old credentials
- [ ] Update all team members with new access methods

## Support

For questions about security configuration, please consult your security team or DevOps lead.