# Creating the digital-twin-deployer IAM User

Learn IAM by creating the user manually first, then codify with Terraform.

---

## Part 1: Manual Creation (Learning)

### Step 1: Open IAM Console

1. Go to https://console.aws.amazon.com/iam/
2. Click **Users** in the left sidebar
3. Click **Create user**

### Step 2: User Details

- **User name**: `digital-twin-deployer`
- Click **Next**

### Step 3: Set Permissions

1. Select **Attach policies directly**
2. Search and check these policies:
   - ✅ `AmazonEC2ContainerRegistryFullAccess`
   - ✅ `AWSAppRunnerFullAccess`
   - ✅ `AmazonS3FullAccess`
   - ✅ `CloudFrontFullAccess`
   - ✅ `SecretsManagerReadWrite`
3. Click **Next** → **Create user**

### Step 4: Create Access Key

1. Click on the new user `digital-twin-deployer`
2. Go to **Security credentials** tab
3. Click **Create access key**
4. Select **Application running outside AWS**
5. Click **Create access key**
6. **Download .csv file** (you won't see the secret again!)

### Step 5: Add to GitHub Secrets

1. Go to your GitHub repo → **Settings** → **Secrets and variables** → **Actions**
2. Add these secrets:
   - `AWS_ACCESS_KEY_ID` → from CSV
   - `AWS_SECRET_ACCESS_KEY` → from CSV

---

## Part 2: Terraform (Infrastructure as Code)

After learning manually, delete the user and recreate with Terraform:

```bash
cd infra
terraform init
terraform plan
terraform apply
```

This ensures your IAM setup is:

- ✅ Version controlled
- ✅ Reproducible
- ✅ Documented in code

---

## Clean Up (After Manual Learning)

Before running Terraform, delete the manually created user:

1. IAM Console → Users → `digital-twin-deployer`
2. Delete user (including access keys)
