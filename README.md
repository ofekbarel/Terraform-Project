In this project we will automatically deploy a machine with a postgres database and another machine that contains our flask application.
A virtual network will be opened, and subnet for each machine. (db-subnet, web-subnet)
We will set private static IP addresses for each machine,

We will define nsg rules that will protect our database! And only computers with IP addresses from the web subnet will be able to access our database.

We will configure our flask application and our database using provisiners, copy and execute postgres.sh , and remote exec to copy app.py and config.py into the web machine.

We will open the 5000 ports for the whole world and take access to our application.





1.  first you should login to your azure account:
    az login

2.  Clone this repostory:
    git clone 

3.   Change some variables:
     (terraform.tfvars)
     
5.  Then you can start   apply your code ! :    
    terraform init
    terraform plan -out=tfplan
    terraform apply "tfplan"


![alt text](https://github.com/ofekbarel/Terraform-Project/blob/main/Azure.png?raw=true)
