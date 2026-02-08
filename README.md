## 🚀 Technical Challenges & Solutions

### 1. IAM Task Execution Role & Secrets Access
**Challenge:** Containers were failing to start because they couldn't retrieve the RDS credentials from AWS Secrets Manager.
**Solution:** Identified a missing `secretsmanager:GetSecretValue` permission in the ECS Task Execution Role. Refactored the IAM policy to follow the Principle of Least Privilege, granting access only to the specific DB secret ARN.

### 2. Networking & Fargate Public Connectivity
**Challenge:** Services in the Public Subnet were unreachable despite having a valid Security Group.
**Solution:** Debugged the VPC Route Table to ensure an active route to the Internet Gateway and enabled `AssignPublicIp` in the ECS Service configuration to allow external health checks to pass.

### 3. Database Persistence
**Challenge:** Connecting the containerized FastAPI service to an external RDS Postgres instance.
**Solution:** Orchestrated a secure connection using environment variables injected via ECS Task Definitions, ensuring the Orders service could perform full CRUD operations on the production database.
