# StartupTech Backend Deployment Assessment

This project provisions AWS infrastructure using Terraform and containerizes a Golang backend API (MuchToDo) using Docker, deployed against a MongoDB database.

---

## Architecture Diagram
Internet
![Architecture Diagram](path/to/image.png)

---

## Prerequisites

Make sure you have the following installed and configured:

- [Terraform](https://developer.hashicorp.com/terraform/install) v1.0+
- [AWS CLI](https://aws.amazon.com/cli/) configured with valid credentials
- [Docker](https://docs.docker.com/get-docker/)
- [Docker Compose](https://docs.docker.com/compose/install/) v2+
- [Git](https://git-scm.com/)
- An AWS account with IAM permissions for EC2, VPC, ALB, and related services
- A Docker Hub account

---

## Project Structure
backend-deployment-assessment/

├── terraform/

│   ├── main.tf                    # All AWS resources

│   ├── variables.tf               # Input variables

│   ├── outputs.tf                 # Output values

│   ├── terraform.tfvars.example   # Example variable values

│   └── user_data/

│       ├── backend_setup.sh       # Installs Docker on backend EC2

│       └── mongodb_setup.sh       # Installs MongoDB on MongoDB EC2

├── Server/                        # Go application source code

├── Dockerfile                     # Multi-stage Docker build

├── docker-compose.yml             # Backend + MongoDB services

├── .dockerignore                  # Files excluded from Docker build

├── evidence/                      # Screenshots of deployment

└── README.md                      # This file

---

## Phase 1 — Infrastructure Provisioning (Terraform)

### Step 1 — Clone the Repository

```bash
git clone https://github.com/OchigboDaniel/altschool_3_semester_assesment.git
cd altschool_3_semester_assesment/backend-deployment-assessment/terraform
```

### Step 2 — Configure AWS Credentials

```bash
aws configure
```

Enter your AWS Access Key ID, Secret Access Key, region (`us-east-1`), and output format (`json`).

Verify:

```bash
aws sts get-caller-identity
```

### Step 3 — Create AWS Key Pair

```bash
aws ec2 create-key-pair \
  --key-name startuptech-key \
  --query 'KeyMaterial' \
  --output text > startuptech-key.pem

chmod 400 startuptech-key.pem
```

### Step 4 — Create terraform.tfvars

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your values:

```hcl
aws_region    = "us-east-1"
instance_type = "t3.micro"
project_name  = "startuptech"
key_pair_name = "startuptech-key"
my_ip         = "YOUR_PUBLIC_IP/32"  # run: curl ifconfig.me
```

> ⚠️ Never commit `terraform.tfvars` to Git — it contains your IP address.

### Step 5 — Initialize Terraform

```bash
terraform init
```

### Step 6 — Preview Infrastructure

```bash
terraform plan
```

This shows all 26 resources that will be created. No changes are made yet.

### Step 7 — Provision Infrastructure

```bash
terraform apply
```

Type `yes` when prompted. This takes approximately 3-5 minutes.

### Step 8 — Note the Outputs

```bash
terraform output
```

You will see:
alb_dns_name       = "StartupTech-alb-xxxxxxxxxx.us-east-1.elb.amazonaws.com"

backend_private_ip = "10.0.3.x"

bastion_public_ip  = "xx.xx.xx.xx"

mongodb_private_ip = "10.0.4.x"

vpc_id             = "vpc-xxxxxxxxxx"

---

## Phase 2 — Docker Setup and Deployment

### Step 1 — Build and Push Docker Image

From your local machine:

```bash
cd backend-deployment-assessment

docker login -u YOUR_DOCKERHUB_USERNAME

docker build -t YOUR_DOCKERHUB_USERNAME/muchtodo-backend:latest .

docker push YOUR_DOCKERHUB_USERNAME/muchtodo-backend:latest
```

### Step 2 — SSH into Backend EC2 via Bastion

```bash
# Start SSH agent and add key
eval $(ssh-agent -s)
ssh-add startuptech-key.pem

# SSH into Bastion with agent forwarding
ssh -A -i startuptech-key.pem ec2-user@<bastion_public_ip>

# From Bastion, hop to Backend
ssh ec2-user@<backend_private_ip>
```

### Step 3 — Clone Repository on Backend EC2

```bash
git clone https://github.com/OchigboDaniel/altschool_3_semester_assesment.git
cd altschool_3_semester_assesment/backend-deployment-assessment
```

### Step 4 — Start the Application

```bash
docker compose pull
docker compose up -d
```

### Step 5 — Verify the Application

Check containers are running:

```bash
docker compose ps
```

Test health endpoint locally:

```bash
curl http://localhost:8080/health
```

Expected response:

```json
{"cache":"disabled","database":"ok"}
```

Test via ALB DNS name (from your local machine):

```bash
curl http://<alb_dns_name>/health
```

---

## Infrastructure Details

### Resources Created

| Resource | Count | Description |
|---|---|---|
| VPC | 1 | 10.0.0.0/16 with DNS enabled |
| Public Subnets | 2 | us-east-1a and us-east-1b |
| Private Subnets | 2 | us-east-1a and us-east-1b |
| Internet Gateway | 1 | VPC internet access |
| NAT Gateway | 1 | Private subnet outbound access |
| Elastic IPs | 2 | NAT Gateway + Bastion |
| Security Groups | 4 | ALB, Bastion, Backend, MongoDB |
| EC2 Instances | 3 | Bastion, Backend, MongoDB |
| Application Load Balancer | 1 | Public facing, port 80 |
| Target Group | 1 | Backend port 8080 |
| Route Tables | 2 | Public and private |

### Security Group Rules

| Security Group | Inbound | Source |
|---|---|---|
| ALB | 80, 443 | 0.0.0.0/0 |
| Bastion | 22 | Your IP only |
| Backend | 8080 | ALB SG only |
| Backend | 22 | Bastion SG only |
| MongoDB | 27017 | Backend SG only |

---

## Teardown and Cleanup

To avoid AWS charges, destroy all resources when done:

```bash
cd backend-deployment-assessment/terraform
terraform destroy
```

Type `yes` when prompted. All 26 resources will be deleted.

> ⚠️ This is irreversible. Make sure you have taken all required screenshots before destroying.

To recreate everything later:

```bash
terraform apply
```

---

## Troubleshooting

**SSH connection timeout to Bastion**
- Your IP may have changed. Update `my_ip` in `terraform.tfvars` and run `terraform apply`.

**Backend container restarting**
- Check logs: `docker compose logs backend`
- Verify MongoDB is healthy: `docker compose ps`

**ALB not responding**
- Wait 2-3 minutes after deployment for health checks to pass
- Verify backend is running: `curl http://localhost:8080/health` from EC2

**Terraform key pair error**
- Recreate key pair: `aws ec2 create-key-pair --key-name startuptech-key ...`
- Destroy and reapply: `terraform destroy && terraform apply`

