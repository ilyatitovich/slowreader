#!/bin/bash
# Configures Google Cloud project for Slow Reader deployment.
# Google Cloud settings can be complex. We have this file to not forget them.
# Do not change Google Cloud by web. Always use `gcloud` and update this script.

PROJECT_ID=slowreader-453400
REGION=europe-west1
WORKFLOWS=(
  ".github/actions/deploy/action.yml"
  ".github/workflows/main.yml"
  ".github/workflows/proxy.yml"
  ".github/workflows/server.yml"
  ".github/workflows/preview-deploy.yml"
  ".github/workflows/preview-clean.yml"
)

# Set project as default in CLI
gcloud init --project=$PROJECT_ID

# Create deploy account
gcloud services enable iamcredentials.googleapis.com --project=$PROJECT_ID
gcloud iam service-accounts create "github-deploy" --project=$PROJECT_ID
ACCOUNT_EMAIL="github-deploy@$PROJECT_ID.iam.gserviceaccount.com"
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:$ACCOUNT_EMAIL" \
    --role="roles/iam.serviceAccountUser"
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:$ACCOUNT_EMAIL" \
    --role="roles/run.admin"
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:$ACCOUNT_EMAIL" \
    --role="roles/artifactregistry.admin"
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:$ACCOUNT_EMAIL" \
    --role="roles/storage.objectAdmin"
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:$ACCOUNT_EMAIL" \
    --role="roles/secretmanager.secretAccessor"

# Create repository for Docker images
gcloud services enable artifactregistry.googleapis.com --project=$PROJECT_ID
gcloud artifacts repositories create staging \
    --project=$PROJECT_ID \
    --repository-format=docker \
    --location=$REGION

# Allow safer access to the service account from GitHub Actions
gcloud iam workload-identity-pools create "github" \
  --project=$PROJECT_ID \
  --location="global" \
  --display-name="GitHub Actions Pool"
gcloud iam workload-identity-pools providers create-oidc "hplush" \
  --project=$PROJECT_ID \
  --location="global" \
  --workload-identity-pool="github" \
  --display-name="GitHub hplush Organization" \
  --attribute-mapping="google.subject=assertion.sub,attribute.actor=assertion.actor,attribute.repository=assertion.repository,attribute.repository_owner=assertion.repository_owner" \
  --attribute-condition="assertion.repository_owner == 'hplush'" \
  --issuer-uri="https://token.actions.githubusercontent.com"

# Bind the deploy account to that saver access
WORKLOAD_IDENTITY_POOL_ID=`gcloud iam workload-identity-pools describe "github" \
  --project=$PROJECT_ID \
  --location="global" \
  --format="value(name)"`
gcloud iam service-accounts add-iam-policy-binding "$ACCOUNT_EMAIL" \
  --project=$PROJECT_ID \
  --role="roles/iam.workloadIdentityUser" \
  --member="principalSet://iam.googleapis.com/${WORKLOAD_IDENTITY_POOL_ID}/attribute.repository/hplush/slowreader"

# To save money on prototype state, we will use file for DB
gcloud storage buckets create gs://slowreader-staging-db \
  --project=$PROJECT_ID \
  --location=$REGION
gcloud storage buckets add-iam-policy-binding gs://slowreader-staging-db \
  --member=serviceAccount:$ACCOUNT_EMAIL \
  --role=roles/storage.objectAdmin

# # Create private network for database
# gcloud services enable compute.googleapis.com --project=$PROJECT_ID
# gcloud services enable servicenetworking.googleapis.com --project=$PROJECT_ID
# gcloud compute addresses create google-managed-services-default \
#   --global \
#   --purpose=VPC_PEERING \
#   --prefix-length=20 \
#   --network=projects/$PROJECT_ID/global/networks/default
# gcloud services vpc-peerings connect \
#   --service=servicenetworking.googleapis.com \
#   --ranges=google-managed-services-default \
#   --network=default \
#   --project=$PROJECT_ID

# # Create database
# gcloud services enable sqladmin.googleapis.com --project=$PROJECT_ID
# gcloud sql instances create staging-db-instance \
#   --database-version=POSTGRES_16 \
#   --availability-type=zonal \
#   --edition=enterprise \
#   --tier=db-f1-micro \
#   --network=projects/$PROJECT_ID/global/networks/default \
#   --no-assign-ip \
#   --no-backup \
#   --region=$REGION
# gcloud sql databases create staging --instance=staging-db-instance

# # Create database access
# gcloud services enable vpcaccess.googleapis.com --project=$PROJECT_ID
# STAGING_DB_PASSWORD=$(openssl rand -base64 24)
# gcloud sql users create server \
#   --password=$STAGING_DB_PASSWORD \
#   --instance=staging-db-instance
# NUMBER=$(gcloud projects describe $PROJECT_ID --format='value(projectNumber)')
# gcloud projects add-iam-policy-binding $PROJECT_ID \
#   --member="serviceAccount:$NUMBER-compute@developer.gserviceaccount.com" \
#   --role="roles/cloudsql.client"
# gcloud compute networks vpc-access connectors create db-connector \
#   --region=$REGION \
#   --range=10.8.0.0/28

# # Create database secret
# gcloud services enable secretmanager.googleapis.com --project=$PROJECT_ID
# STAGING_DB_IP=$(gcloud sql instances describe staging-db-instance \
#   --format=json | jq \
#   --raw-output ".ipAddresses[].ipAddress")
# STAGING_DB=postgresql://server:$STAGING_DB_PASSWORD@$STAGING_DB_IP:5432/staging
# echo -n $STAGING_DB | gcloud secrets create staging-db-url \
#   --replication-policy=automatic \
#   --data-file=-
# echo -n "memory://" | gcloud secrets create preview-db-url \
#   --replication-policy=automatic \
#   --data-file=-

# Enable Google Cloud Run
gcloud services enable run.googleapis.com --project=$PROJECT_ID

# Use workload_identity_provider in workflows
IDENTITY=`gcloud iam workload-identity-pools providers describe "hplush" \
  --project=$PROJECT_ID \
  --location="global" \
  --workload-identity-pool="github" \
  --format="value(name)"`
for file in "${WORKFLOWS[@]}"; do
  sed -i "s|identity_provider: .*|identity_provider: $IDENTITY|g" "$file"
  sed -i "s/projectId: .*/projectId: $PROJECT_ID/g" "$file"
  sed -i "s/region: .*/region: $REGION/g" "$file"
done

echo -e "\033[0;33m\033[1mAfter first deploy:\033[0m"
echo ""
echo -e "1. Open https://console.cloud.google.com/run"
echo -e "2. Switch to \033[1m*@hplush.dev\033[0m account"
echo -e "3. Check Cloud Run service internal URL like \033[1m*.run.app\033[0m"
echo -e "4. Set domain in \033[1m.github/workflows/preview-deploy.yml\033[0m"
echo -e "5. Map domains:"
echo ""
echo "gcloud beta run domain-mappings create --service=staging-web --domain=dev.slowreader.app --project=$PROJECT_ID --region=$REGION"
echo ""
echo "gcloud beta run domain-mappings create --service=staging-server --domain=dev-server.slowreader.app --project=$PROJECT_ID --region=$REGION"
echo ""
echo "gcloud beta run domain-mappings create --service=staging-proxy --domain=dev-proxy.slowreader.app --project=$PROJECT_ID --region=$REGION"
