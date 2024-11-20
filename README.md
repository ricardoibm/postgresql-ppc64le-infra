# PostgreSQL PPC64LE Infrastructure on IBM Cloud

This project automates the deployment and configuration of a PostgreSQL infrastructure optimized for `ppc64le` architecture on IBM Cloud. It uses Terraform for cloud resource provisioning and Ansible for PostgreSQL setup and performance tuning on the deployed servers.

## Table of Contents

- [Overview](#overview)
- [Requirements](#requirements)
- [Deployment on IBM Cloud (Terraform)](#deployment-on-ibm-cloud-terraform)
- [Server Configuration (Ansible)](#server-configuration-ansible)
- [Contributing](#contributing)
- [License](#license)

## Overview

This project simplifies the deployment of PostgreSQL on IBM Cloud for `ppc64le` architecture with IBM Power, providing configurations tailored for IBM Power’s high performance.

## Requirements

- **IBM Cloud Account**: Required to create and manage cloud resources.
- **Terraform**: For automated resource provisioning.
- **Ansible**: For server configuration and PostgreSQL management.
- **Git**: To clone the repository.

## Deployment on IBM Cloud (Terraform)

1. **Configure IBM Cloud Credentials**:
   - Ensure your IBM Cloud API credentials are set up.

2. **Initialize Terraform**:
   - In the `terraform` folder, run:
     ```bash
     terraform init
     ```

3. **Review config terrafor**:
   - check variable key ssh in file main.tf, you do need this variable from IBM Cloud dashboard.

4. **Review the Deployment Plan**:
  - Preview the resources to be created:
    ```bash
    terraform plan
    ```

5. **Apply the Deployment**:
   - Deploy the resources in IBM Cloud:
     ```bash
     terraform apply
     ```

   This creates the servers and other resources for PostgreSQL infrastructure.

## Server Configuration (Ansible)

1. **Configure Ansible Inventory**:
   - Ensure the servers created with Terraform are listed in the Ansible inventory file located in `ansible/ansible_hosts.ini`.

2. **Run the Playbook**:
   - In the `ansible` directory, execute:
     ```bash
     ansible-playbook -i ansible_hosts.ini install_postgresql.yml
     ansible-playbook -i ansible_hosts.ini install_app.yml
     ```

   This playbook configures PostgreSQL with optimizations for `ppc64le`.

3. **Verify Configuration**:
   - Confirm PostgreSQL is operational on each server.


4.  **Modify Configuration Variables**:
     - Update variables in the `ansible/postgres_vars.yml` file as needed for your PostgreSQL deployment (e.g., tuning parameters, paths, and user credentials).

## Contributing

Contributions are welcome! To improve deployment or configuration, fork the repository, create a feature branch, and submit a pull request.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
