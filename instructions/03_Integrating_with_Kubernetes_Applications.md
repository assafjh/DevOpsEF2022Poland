# Workshop guide: __Step 3__ Integrating with Kubernetes Applications

By default, a Pod is associated with a service account, and a credential (token) for that service account is placed into the filesystem tree of each container in that Pod. At this exercise will use this token to authenticate against Conjur without exposing [Secret Zero](https://www.conjur.org/blog/secret-zero-eliminating-the-ultimate-secret/)

All work in this guide will be under the **kuberneties-jwt** folder of this repo.

 ## Pre-Requisites
 Step 2 outcome and will include:
-   Conjur Instance up and running
-   Client successfully up and running

## Defining root branch policies

### 1. Login to Conjur using the CLI
- The admin user password is in the admin_data file generated earlier on
```Bash
conjur login -i admin
```

### 2. Examine the policies/01-base.yml file and load it
```Bash
conjur policy update -b root -f policies/01-base.yml | tee -a 01-base.log
```

### 3. Examine the 01-base.log file and logout
```Bash
conjur logout
```
## Defining kubernetes branch policies

### 1. Login as user k8s-manager01
- Use the API key as a password from the 01-base.log file for the user k8s-manager01
```bash
conjur login -i k8s-manager01
```
### 2. Examine the policies/02-define-kubernetes-branch.yml file and load it
```Bash
conjur policy update -b kubernetes -f policies/02-define-kubernetes-branch.yml | tee -a 02-define-kubernetes-branch.log
```
### 3. Examine the policies/02-define-kubernetes-branch.log file and logout
```Bash
conjur logout
```
## Defining JWT Authn policy

### 1. Login as user admin01
 - Use the API key as a password from the 01-base.log file for the user admin01
```bash
conjur login -i admin01
```
### 2. Examine the policies/03-define-jwt-auth.yml file and load it
```Bash
conjur policy update -b root -f policies/03-define-jwt-auth.yml | tee -a 03-define-jwt-auth.log
```
### 3. Examine the policies/03-define-jwt-auth.log file

### 4. Populcate the secrets and JWT authenticator variables
```Bash
scripts/01_populate_variables.sh | tee -a 01_populate_variables.log
```

### 5. Examine the policies/01_populate_variables.log file and logout
```Bash
conjur logout
```

## Creating infra for our deployments
### 1. Review manifests/01_create_infra.yml file and load it
```bash
kubectl apply -f manifests/01_create_infra.yml
```
### 2. Check that the NS conjur was created
```bash
kubectl get ns
```
## Deploying manifest - REST API application
### 1. Review and modify manifests/02_consumer_jwt_appliation.yml file
At lines #12 and #13, change <conjur-host> to your conjur host.
### Deploy Manifest
```bash
kubectl apply -f manifests/02_consumer_jwt_appliation.yml
```
### 2. Connect to the container
```bash
kubectl get pods -n conjur | grep k8s-jwt-app1
kubectl exec -i -t -n conjur <pod_name> -c k8s-jwt-app -- sh -c "bash"
```
### 3. Inside the container, consume a secret by running the script
```bash
/scripts/retrieve.sh
```
## Deploying manifest - Sidecar - push to file method
### 1. Review and modify manifests/03_push_to_file_jwt.yml file
 - At line #20, replace $CONJOR_PUBLIC_KEY with the public key that can be found at : $HOME/conjur-server.pem
 - At lines 15,16 - change <conjur-host> to your conjur host.

### Deploy Manifest
```bash
kubectl apply -f manifests/03_push_to_file_jwt.yml
```
### 2. Connect to the demo-application container
```bash
kubectl get pods -n conjur | grep kubectl get pods -n conjur | grep demo-sidecar-push-to-file-jwt
kubectl exec -i -t -n conjur <pod_name> -c demo-application -- sh -c "bash"
```
### 3. Inside the container, check that the secrets were pushed to file
```bash
cat /opt/secrets/conjur/credentials.yaml
```
### 4. Optional: If you'll update secret3 or secret7, after a minute the file will be updated
To update secret3, for example, use the below:
```bash
conjur variable set -i kubernetes/applications/safe/secret3 -v "new value"
```
Wait for a minute and recheck the file at the container.
