# Azure Terraform Project ! 🌥️


**In this project we will use different resources in the azure cloud, in order to deploy our application and a postgres database automatically with the help of terraform !.**



---
## Prerequisites:

- **Azure subscription**
- **Azure CLI**
- **Terraform is installed**
  
---

## steps: 🔨

 ### 1. Create Python App
First of all, we created a web application in Python using flask.
Therefore, first of all we created app.py, and the file config.py which is used as a file that defines the connection to our database.
In this application, the application accesses the database through a connection that we defined, and will return us an html page with the results from the postrges database


### 2. Create providers.tf
In order to configure the azure cloud and which version



### 3. add main.tf:
The next step is to create **main.tf**, inside this file we will define all the resources we want to create in Azure,
Among the resources we will create will be: a **virtual network**, which will contain **web-subnet** and **db-subnet**.
For each subnet we will define **nsg rules** in order to maintain security especially in our database, and thus it is determined that only ip addresses from the web-subnet have access into the db-subnet.
We will create **public ip addresses**, and also **staric private ip addresses**.
After that we will create two **virtual machines**, one inside each subnet.
We will install and configure postgres sql inside the machine with the help of a script that will be copied and executed inside the machine.
We will install and copy the relevant files in order to run our python application to the second machine and run the application.


### 4. Create variables.tf / terraform.tfvars
We will create the files that contain the values ​​we want to insert in the main.tf file, usually we will not want to push the terraform.tfvars file to git because in our case it contains sensitive information.
Compared to variables.tf which does not contain sensitive information and there is no problem pushing it to git.



### 5. Create postgres.sh
We will create the file that installs and configures our postrges.
Then we will copy the file with the help of a provisioner which will copy the script into the virtual machine, and then we will use another provisioner which will confirm the script.




---

![alt text](https://github.com/ofekbarel/Terraform-Project/blob/main/Azure.png?raw=true)
