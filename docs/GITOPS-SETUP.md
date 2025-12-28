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

## 4. Install ArgoCD

1.  **Install the ArgoCD CLI:**
    Follow the [official ArgoCD documentation](https://argo-cd.readthedocs.io/en/stable/cli_installation/) to install the CLI.

2.  **Install ArgoCD on the cluster:**
    ```bash
    kubectl create namespace argocd
    kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
    ```

## 5. Access the ArgoCD UI

1.  **Port-forward to the ArgoCD server:**
    ```bash
    kubectl port-forward svc/argocd-server -n argocd 8080:443
    ```

2.  **Get the initial admin password:**
    ```bash
    argocd admin initial-password -n argocd
    ```

3.  **Log in:**
    Open `https://localhost:8080` in your browser, and log in with the username `admin` and the password you retrieved.

## 6. Create the Database Secret

Create a Kubernetes secret to hold the database connection string.

1.  **Create a `db-secret.yaml` file:**
    ```yaml
    apiVersion: v1
    kind: Secret
    metadata:
      name: orbit-db-secret
      namespace: orbit
    type: Opaque
    stringData:
      database-url: "YOUR_DATABASE_URL_FROM_TERRAFORM_OUTPUTS"
    ```
    Replace `YOUR_DATABASE_URL_FROM_TERRAFORM_OUTPUTS` with the actual connection string.

2.  **Apply the secret:**
    ```bash
    kubectl apply -f db-secret.yaml
    ```

## 7. Update Repository URLs and Domain

Before deploying the application, you need to update the repository URL in the ArgoCD Application and the domain in the Helm values.

1.  **Update `infrastructure/argocd/base/application.yaml`:**
    Change `repoURL` to your forked repository.

2.  **Update `infrastructure/helm/orbit/values-production.yaml`:**
    -   Update `ingress.hosts.host` and `ingress.tls.hosts` to your desired domain.
    -   Update `backend.image.repository` and `frontend.image.repository` to point to your container registry.

Commit and push these changes to your `main` branch.

## 8. Deploy the ArgoCD Application

Deploy the Orbit application using Kustomize to apply the production overlay.

```bash
kustomize build infrastructure/argocd/overlays/production | kubectl apply -f -
```

This will create the ArgoCD Application resource, which will then automatically sync and deploy the Orbit Helm chart.

## 9. Verify Deployment

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
