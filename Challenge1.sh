Create and Manage Cloud Resources: Challenge Lab (GSP313)


Task 1: Create a project jumphost instance
Run command:

# Please replace instance_name, zone, boot_image with the allocated names in the project 

gcloud compute instances create instance_name \
          --network nucleus-vpc \
          --zone zone  \
          --machine-type machine_type  \
          --image-family boot_image  \
          --image-project debian-cloud \
          --scopes cloud-platform \
          --no-address

          
Task 2: Create a Kubernetes service cluster
Run command:

# Please replace the region with the allocated values in the project 
# If it's a zonal cluster, please use --zone=zone_name instead of --region

gcloud container clusters create nucleus-backend \
          --num-nodes 1 \
          --network nucleus-vpc \
          --region region 

# This is to authenticate and configure the local Kubernetes configuration (kubeconfig) file to connect to a GKE cluster.

gcloud container clusters get-credentials nucleus-backend \
          --region region

kubectl create deployment hello-server \
          --image=gcr.io/google-samples/hello-app:2.0

kubectl expose deployment hello-server \
          --type=LoadBalancer \
          --port 8080


Task 3: Set up an HTTP load balancer
Run command:

cat << EOF > startup.sh
#! /bin/bash
apt-get update
apt-get install -y nginx
service nginx start
sed -i -- 's/nginx/Google Cloud Platform - '"\$HOSTNAME"'/' /var/www/html/index.nginx-debian.html
EOF

# Please replace machine_type and region with the allocated values in the project

gcloud compute instance-templates create web-template \
          --metadata-from-file startup-script=startup.sh \
          --network nucleus-vpc \
          --machine-type machine_type \
          --region region


gcloud compute instance-groups managed create web-server-group \
          --base-instance-name web-server \
          --size 2 \
          --template web-template \
          --region region


gcloud compute firewall-rules create web-server-firewall \
          --allow tcp:80 \
          --network nucleus-vpc
          
          
gcloud compute http-health-checks create http-basic-check

gcloud compute instance-groups managed \
          set-named-ports web-server-group \
          --named-ports http:80 \
          --region region


gcloud compute backend-services create web-server-backend \
          --protocol HTTP \
          --http-health-checks http-basic-check \
          --global
          
gcloud compute backend-services add-backend web-server-backend \
          --instance-group web-server-group \
          --instance-group-region region \
          --global


gcloud compute url-maps create web-server-map \
          --default-service web-server-backend
          
gcloud compute target-http-proxies create http-lb-proxy \
          --url-map web-server-map


gcloud compute forwarding-rules create http-content-rule \
        --global \
        --target-http-proxy http-lb-proxy \
        --ports 80
        
gcloud compute forwarding-rules list # Double-check by listing the available forward rules in the project 

# If you have any error whilst verifying the task, please check if you have set the NAMES allocated by the project correctly.