#!/bin/bash
# LOCATION: Place this file in the root directory of your Next.js application
# Exit on any error
set -e

# Full path to gcloud command
GCLOUD="/home/abreham/Downloads/google-cloud-sdk/bin/gcloud"

# Configuration - CHANGE THESE VALUES
PROJECT_ID="ninth-arena-450804-u2"  # Your GCP project ID
REGION="us-central1"  # The region to deploy to
SERVICE_NAME="volunteer-manager"  # The name of your Cloud Run service
REPO_NAME="volunteer-repo"  # Your Artifact Registry repository name

# Derived variables
REPO_PATH="$REGION-docker.pkg.dev/$PROJECT_ID/$REPO_NAME"
IMAGE_NAME="$REPO_PATH/$SERVICE_NAME:latest"

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "Error: Docker not found. Please install Docker."
    exit 1
fi

# Ensure we're logged in and using the correct project
echo "🔐 Verifying authentication and project configuration..."
$GCLOUD auth print-access-token > /dev/null
$GCLOUD config set project $PROJECT_ID

# Make sure required APIs are enabled
echo "🔌 Ensuring required APIs are enabled..."
$GCLOUD services enable cloudbuild.googleapis.com run.googleapis.com artifactregistry.googleapis.com

# Make sure the Artifact Registry repository exists
echo "📦 Checking Artifact Registry repository..."
if ! $GCLOUD artifacts repositories describe $REPO_NAME --location=$REGION &> /dev/null; then
    echo "Creating Artifact Registry repository '$REPO_NAME'..."
    $GCLOUD artifacts repositories create $REPO_NAME \
        --repository-format=docker \
        --location=$REGION \
        --description="Repository for $SERVICE_NAME"
fi

# Build the Docker image
echo "🔨 Building Docker image: $IMAGE_NAME"
docker build -t $IMAGE_NAME .

# Push the image to Artifact Registry
echo "⬆️ Pushing image to Artifact Registry..."
docker push $IMAGE_NAME

# Deploy to Cloud Run
echo "🚀 Deploying to Cloud Run..."
$GCLOUD run deploy $SERVICE_NAME \
  --image $IMAGE_NAME \
  --platform managed \
  --region $REGION \
  --allow-unauthenticated \
  --memory 512Mi

# Get the deployed URL
SERVICE_URL=$($GCLOUD run services describe $SERVICE_NAME --platform managed --region $REGION --format "value(status.url)")
echo "✅ Deployment complete! Your application is available at: $SERVICE_URL"
echo ""
echo "🔗 Make sure to update your WordPress iframe to point to this URL:"
echo "<iframe src=\"$SERVICE_URL\" width=\"100%\" height=\"100%\" frameborder=\"0\"></iframe>"