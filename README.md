# AWS
AWS + Terraform (Make sure the Terraform is correctly installed)




- Go to AWS Portal Click on your username and My Security Credentials:

![image](https://user-images.githubusercontent.com/14153822/120091867-18d1b980-c10f-11eb-9baf-fa23981f2293.png)


- Navigate to Access keys (access key ID and secret access key) and copy or create a new access key, the value of both must be added to the variables.tf:

![image](https://user-images.githubusercontent.com/14153822/120091929-a8776800-c10f-11eb-8460-b7791a06dba4.png)



- Generate a SSH Key using PuTTYgen and save both keys, public and private :


![image](https://user-images.githubusercontent.com/14153822/120091683-bdeb9280-c10d-11eb-9d83-55f124060d8c.png)


- Save the public key in the same directory as per your Terraform Code and paste the public key into the variables.tf:

![image](https://user-images.githubusercontent.com/14153822/120092284-0a38d180-c112-11eb-971b-f1f43ddff938.png)


- Run the following commands in the prompt/shell/Powershell:
  - terraform init
  - terraform plan
  - terraform apply

An Apache server will be installed, you can access the hello world page, copying the DNS name on the Load Balancers option in AWS:

![image](https://user-images.githubusercontent.com/14153822/120092494-81bb3080-c113-11eb-8508-4d0950c7acef.png)

You will see a page like this:

![image](https://user-images.githubusercontent.com/14153822/120092499-939cd380-c113-11eb-8107-94a43e612bb4.png)


The terraform script is going to install the stress software on the Ubuntu server. The stress tool is a workload generator that provides CPU, memory, and disk I/O stress tests. 

Use Putty to access the Ubuntu Server (don't forget to import the private key file (see below):


![image](https://user-images.githubusercontent.com/14153822/120092552-102fb200-c114-11eb-919f-d5ae048ccf5e.png)



![image](https://user-images.githubusercontent.com/14153822/120092572-32293480-c114-11eb-8020-958d31e9b031.png)

- Login as Ubuntu:

![image](https://user-images.githubusercontent.com/14153822/120092585-479e5e80-c114-11eb-993c-dd4a766dccb8.png)

Test the stress tool using the following command:

stress --cpu 1024 --timeout 300

![image](https://user-images.githubusercontent.com/14153822/120092635-b5e32100-c114-11eb-8d83-b32852768054.png)


Due to Autoscaling is triggeed after 80% of CPU utilizartion, the number of requested should be high.

When the CPU reaches more than 80%, the Load Balancer will start a new instance on AWS, you can make sure the load balancer is working accessing the aforementioned DNS name. The page will show you the IP from the machine is being accessed at that moment, you will see the IP address changing when refreshing the page.

![image](https://user-images.githubusercontent.com/14153822/120093039-c47f0780-c117-11eb-917f-5249c3b10050.png)



After finishing all the tests and you don't want to keep any instance running on AWS, type the following command:
  - terraform destroy



Feel free to contact me for improvements/feedback.






     




