## Task 

#### AIM:  Create a solution using Terraform, Ansible, and Docker so that when we apply the Terraform configuration, it should create an EC2 instance, run an Ansible playbook. The playbook will copy a Dockerfile to the instance, build an image, and run a container from it. The image should have a web server of your choice configured in it along with a custom html page. After the complete execution, we should be able to see the message "Mission successful!" in the browser when we hit the public ip of the instance on 80 port.


### 1. We Will build a Terraform Script

+ Configure the AWS provider

```h
provider "aws" {
  region = "Select Preferable Region"
}
```

+ Create a security group

```h
resource "aws_security_group" "example" {
  name = "example"
  description = "Allow inbound traffic on port 80 and 22"

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"] :- 
    
    //Currently it's open to all but don't forget to assign your ip
 
  }

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  
    //Currently it's open to all but don't forget to assign your ip
 
  }

  egress {
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]   
  
   //Currently it's open to all but don't forget to assign your ip
 
}
}
```
+ Create an EC2 instance

```h
resource "aws_instance" "example" {
  
  ami = "ami-1234567890"  
  
  //Enter Ami image id that you want to use

  instance_type = "Enter Preferable Type of Ec2 instance"

  vpc_security_group_ids = [aws_security_group.example.id]
  
  key_name = "Enter Your key Name"
  
  tags = {
    Name = "Enter Tag for the instance"
  }

}

```

+ Generally the null_resource block in Terraform allows us to define arbitrary actions to be taken on the remote instance after it's created, without representing any real resource in Terraform's state. In this case, we're using it to provision files (playbook.yml and Dockerfile) to the EC2 instance using SSH connection.

+ So for that reason we are going to create one null resource with it 

+ declares a null_resource named ssh_connection. This resource type allows us to define provisioning actions that don't correspond to a physical infrastructure resource managed by Terraform.


```h
resource "null_resource" "ssh_connection" {

  // Copy the Ansible playbook and Dockerfile to the instance
  
  provisioner "file" {
    source = "playbook.yml"
    destination = "/home/ubuntu/playbook.yml"

    connection {
      type = "ssh"
      host = aws_instance.example.public_ip
      user = "ubuntu"  
      private_key = file("/ path to your pem key")
    }
  }

  provisioner "file" {
    source = "Dockerfile"
    destination = "/home/ubuntu/Dockerfile"

    connection {
      type = "ssh"
      host = aws_instance.example.public_ip
      user = "ubuntu"
      private_key = file("/path to your pem key")
    }
  }
}
```
### 2. Now we will also run the Ansible playbook after creation but before that we will create one playbook.yml file first

+ Let's First we define what we are going to do step wise

1. Define Playbook Name and Target Host and also allow the privilege escalation
as it will going to perform installation

```yml
- name: Configure web server
  hosts: localhost
  become: yes
```

2. Define the tasks section as belowed: 

+ install Docker and Python Dependencies:

```yml
tasks:
  - name: Install Docker
    apt:
      name: docker.io
      state: present

  - name: Install Python 3 pip
    apt:
      name: python3-pip
      state: present
    become: yes

  - name: Install Docker Python module
    pip:
      name: docker
      state: present
    become: yes
```
3. Dockerfile Creation:

```yml
- name: Copy Dockerfile
    copy:
      content: |
        FROM ubuntu:latest
        RUN apt-get update && apt-get install -y nginx
        RUN echo "Mission successful!" > /var/www/html/index.html
        EXPOSE 80
        CMD ["nginx", "-g", "daemon off;"]
      dest: /path to your /Dockerfile
```

4. Building and Running Docker Container:

```yml
  - name: Build Docker image
    command: docker build -t my-web-server .

  - name: Run Docker container
    command: docker run -p 80:80 my-web-server
    environment:
       HOST_KEY_CHECKING: "False"
```

+ note : HOST_KEY_CHECKING: "False": Disables SSH host key checking to prevent prompts during the container execution.

### 3. Now before coming to the final part we will create on Dockerfile as well 

+ creating docker file as below:

```Dockerfile
FROM ubuntu:latest

RUN apt-get update && apt-get install -y nginx

RUN echo "Mission successful!" > /var/www/html/index.html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
```

### 4. Now the final part of terraform which will run the ansible and ansible will copy dockerfile which we have made 


```h
provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-add-repository -y ppa:ansible/ansible",
      "sudo apt-get update",
      "sudo apt install -y ansible",
      "sudo apt-get update",
      "sudo apt-get install -y", "software-properties-common",
      "ansible-playbook -i localhost, -u ubuntu playbook.yml"     
     ]

    connection {
      type = "ssh"
      host = aws_instance.example.public_ip
      user = "ubuntu"
      private_key = file("/path to your pem key")
    }
}
```

