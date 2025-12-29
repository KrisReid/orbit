# Orbit GitOps Setup with ArgoCD

This guide walks through setting up the Orbit project management system on a Kubernetes cluster using a GitOps workflow with Terraform and ArgoCD.

## 1. Prerequisites

Ensure you have the following tools installed:

- `terraform`
- `kubectl`
- `helm`
- `gcloud` CLI (for GKE) or `aws` CLI (for EKS)
- `kubectx` / `kubens` (recommended)

## 2. Provision Infrastructure with Terraform

1.  **Navigate to the Terraform environment:**
    ```bash
    # For Google Kubernetes Engine (GKE)
    cd infrastructure/terraform/environments/gke
    
    # For Amazon Elastic Kubernetes Service (EKS)
    cd infrastructure/terraform/environments/eks
    ```

2.  **Create a `terraform.tfvars` file:**
    Copy the `terraform.tfvars.example` to `terraform.tfvars` and fill in your specific values for project ID, region, etc.

3.  **Initialize and apply Terraform:**
    ```bash
    terraform init
    terraform apply
    ```
    This will provision the VPC, Kubernetes cluster, managed database, and install nginx-ingress and cert-manager.

4.  **Note the Terraform outputs:**
    After the apply completes, Terraform will output the database connection details. You will need these for creating the Kubernetes secret.

## 3. Connect to the Cluster

Use the commands provided by your cloud provider to configure `kubectl` to connect to your new cluster.

-   **For GKE:**
    ```bash
    gcloud container clusters get-credentials CLUSTER_NAME --region REGION
    ```

-   **For EKS:**
    ```bash
    aws eks update-kubeconfig --name CLUSTER_NAME --region REGION
    ```

Verify the connection:
```bash
kubectl get nodes
```

## 4. Verify Addon Installations

After Terraform completes, the following addons will be installed on your cluster:
- NGINX Ingress Controller
- cert-manager
- ArgoCD

You can verify their pods are running:
```bash
# Check NGINX pods in the 'ingress-nginx' namespace
kubectl get pods -n ingress-nginx

# Check cert-manager pods in the 'cert-manager' namespace
kubectl get pods -n cert-manager

# Check ArgoCD pods in the 'argocd' namespace
kubectl get pods -n argocd
```

## 5. Access the ArgoCD UI

1.  **Get the ArgoCD server LoadBalancer IP:**
    The Terraform script configures the ArgoCD server to be exposed via a LoadBalancer. Get its external IP address:
    ```bash
    kubectl get svc -n argocd argocd-server -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
    ```
    It may take a few minutes for the IP to become available.

2.  **Get the initial admin password:**
    ```bash
    kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
    ```

3.  **Log in:**
    Open `https://<YOUR_ARGO_IP>` in your browser (note: you will likely see a certificate warning, which you can safely ignore for now). Log in with the username `admin` and the password you retrieved.

## 6. Bootstrap the GitOps Connection (One-Time Manual Steps)

The following steps are a one-time manual process to securely connect your new infrastructure to your application's configuration in Git. Once this bootstrap is complete, all future application deployments will be fully automated.

### a. Create the Database Secret

The database connection string is a sensitive value. The Terraform setup provides two options for managing the database password:

1.  **Auto-generated password (default):** Terraform will generate a random password and, if enabled, store it in Google Secret Manager for you. The full connection string will be available as a Terraform output.
2.  **Using an existing secret:** For a more secure, production-ready setup, you can pre-create a secret in Google Secret Manager and tell Terraform to use it. To do this, create your secret and then set the `database_password_secret_id` variable in your `.tfvars` file to the secret's ID (e.g., `"my-db-password-secret"`).

Once Terraform has run, create a Kubernetes secret from the resulting connection string. This manual step prevents sensitive credentials from being automatically passed between systems.

1.  **Create a `db-secret.yaml` file:**
    ```yaml
    apiVersion: v1
    kind: Secret
    metadata:
      name: orbit-db-secret
      # The namespace must match the one in the ArgoCD application
      namespace: orbit-production
    type: Opaque
    stringData:
      database-url: "YOUR_DATABASE_URL_FROM_TERRAFORM_OUTPUTS"
    ```
    Replace `YOUR_DATABASE_URL_FROM_TERRAFORM_OUTPUTS` with the actual connection string.

2.  **Apply the secret:**
    ```bash
    kubectl apply -f db-secret.yaml
    ```

### b. Update Repository URLs and Domain

You need to tell ArgoCD where to find your application's configuration.

1.  **Update `infrastructure/argocd/base/application.yaml`:**
    Change `repoURL` to your forked repository URL.

2.  **Update `infrastructure/helm/orbit/values-production.yaml`:**
    -   Update `ingress.host` and `ingress.tls.hosts` to your desired domain.
    -   Update `backend.image.repository` and `frontend.image.repository` to point to your container registry (e.g., `ghcr.io/your-github-username/orbit-backend`).

Commit and push these changes to your `main` branch.

### c. Deploy the ArgoCD Application

This final manual step "points" ArgoCD at your Git repository, closing the GitOps loop. From now on, ArgoCD will automatically manage the application's deployment.

Deploy the Orbit application using Kustomize to apply the production overlay:

```bash
kustomize build infrastructure/argocd/overlays/production | kubectl apply -f -
```

This creates the ArgoCD Application resource. ArgoCD will now take over, automatically syncing and deploying the Orbit Helm chart based on the configuration in your Git repository.

## 7. Verify Deployment

1.  **Check the ArgoCD UI:**
    The `orbit` application should appear in the ArgoCD UI and transition to a `Synced` and `Healthy` state.

2.  **Check the pods:**
    ```bash
    kubectl get pods -n orbit
    ```
    You should see the backend and frontend pods running.

3.  **Access the application:**
    Once DNS has propagated, you should be able to access Orbit at the domain you configured.

## 10. Daily Operations

-   **Deployments:** Pushing a change to the `main` branch will trigger the GitHub Actions workflow. The workflow will build new container images, push them to the registry, and update the image tags in the Helm values. ArgoCD will detect the change in the Git repository and automatically sync the new version to the cluster.
-   **Rollbacks:** To roll back, you can revert the commit that introduced the change in your Git repository. ArgoCD will then sync the previous state. You can also use the ArgoCD UI to roll back to a previous revision.
-   **Logs:** View pod logs using `kubectl logs`:
    ```bash
    kubectl logs -n orbit -l app.kubernetes.io/name=orbit-backend -f
    kubectl logs -n orbit -l app.kubernetes.io/name=orbit-frontend -f
    ```

## 11. Troubleshooting

-   **ImagePullBackOff:** This usually means the Kubernetes cluster cannot pull the container images. Check that the image repository and tag are correct and that the cluster has the necessary permissions to pull from the registry.
-   **CrashLoopBackOff:** The pod is starting and then crashing. Check the pod logs for errors. This is often caused by a misconfiguration, such as an incorrect database URL.
-   **ArgoCD Sync Failures:** Check the ArgoCD UI for sync error messages. These can often point to issues in the Helm chart or values files.
