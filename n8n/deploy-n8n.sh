#!/usr/bin/env bash
# this script enables APIs creates a cloud sql + user, secrets, and deploy n8n + FastAPI
set -euo  pipefail
# Load variables 
if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs)
else
    echo ".env file not found!"
    exit 1
fi

echo "Enabling required GCP APIs..."
gcloud services enable run.googleapis.com \
    sqladmin.googleapis.com \
    secretmanager.googleapis.com \
    --project $PROJECT_ID

echo "Creating Cloud SQL instance..."
gcloud sql instances create $INSTANCE_NAME \
    --database-version=POSTGRES_14 \
    --tier=db-f1-micro \
    --region=$REGION \
    --instance=$INSTANCE_NAME \
    --project=$PROJECT_ID || echo "Already exists, skipping creation."

echo "Creating database..."
    gcloud sql databases create $DB_NAME \
    --instance=$INSTANCE_NAME \
    --project=$PROJECT_ID || echo "Already exists, skipping creation."


echo "Creating DB user..."
    gcloud sql users create $DB_USER \
    --instance=$INSTANCE_NAME \
    --password=$DB_PASS \
    --project=$PROJECT_ID || echo "Already exists, skipping creation."

echo "Storing DB credentials in Secret Manager..."
    echo -n $DB_PASS | gcloud secrets create n8n-db-pass \
    --replication-policy="automatic" \
    --data-file=- \
    --project=$PROJECT_ID || \
    echo -n "$DB_PASS" | gcloud secrets versions add n8n-db-pass --data-file=- 

echo "Creating service accounts..."
    gcloud iam service-accounts create $SERVICE_ACCOUNT \
    --project=$PROJECT_ID || echo "Already exists, skipping creation."

echo "Granting cloud SQL + secret access..."
    gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:$SERVICE_ACCOUNT@$PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/cloudsql.client" || echo "Already has role, skipping."

    gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:$SERVICE_ACCOUNT@$PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/secretmanager.secretAccessor" || echo "Already has role, skipping."
    
echo "Deploying n8n to Cloud Run..."
    gcloud run deploy $N8N_SERVICE \
    --image=n8nio/n8n \
    --region=$REGION \
    --platform=managed \
    --service-account=$SERVICE_ACCOUNT@$PROJECT_ID.iam.gserviceaccount.com \
    --add-cloudsql-instances=$CONN_NAME \
    --set-secrets=DB_PASS=n8n-db-pass:latest \
    --set-env-vars="DB_TYPE=postgresdb,DB_POSTGRESDB_HOST=/cloudsql/$CONN_NAME,DB_POSTGRESDB_PORT=5432,DB_POSTGRESDB_DATABASE=$DB_NAME,DB_POSTGRESDB_USER=$DB_USER,DB_POSTGRESDB_PASSWORD=\$(DB_PASS)" \
    --allow-unauthenticated 

N8N_URL=$(gcloud run services describe $N8N_SERVICE --platform=managed --region=$REGION --project=$PROJECT_ID --format='value(status.url)')
echo "n8n deployed at: $N8N_URL"

echo "Deploying FastAPI to Cloud Run..."
    gcloud iam service-accounts create $FASTAPI_SERVICE_ACCOUNT \
    --project=$PROJECT_ID || echo "Already exists, skipping creation."

    gcloud run deploy $FASTAPI_SERVICE \
    --source=./app \
    --region=$REGION \
    --platform=managed \
    --project=$PROJECT_ID \
    --service-account=$FASTAPI_SERVICE_ACCOUNT@$PROJECT_ID.iam.gserviceaccount.com \
    --set-env-vars="N8N_URL=$N8N_URL"/webhook \
    --allow-unauthenticated
    
FASTAPI_URL=$(gcloud run services describe $FASTAPI_SERVICE --platform=managed --region=$REGION --project=$PROJECT_ID --format='value(status.url)')
echo "FastAPI deployed at: $FASTAPI_URL"