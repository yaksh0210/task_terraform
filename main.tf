# Configure the AWS provider

provider "aws" {
  region = "Select Preferable Region"
}

# Create a security group

resource "aws_security_group" "example" {
  name        = "example"
  description = "Allow inbound traffic on port 80 and 22"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] :- #Currently it's open to all but don't forget to assign your ip
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] #Currently it's open to all but don't forget to assign your ip
  }

  egress {
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"] #Currently it's open to all but don't forget to assign your ip
}
}

# Create an EC2 instance

resource "aws_instance" "example" {
  ami = "ami-1234567890"  #Enter Ami image that you want to use
  instance_type = "Enter Preferable Type of Ec2 instance"
  vpc_security_group_ids = [aws_security_group.example.id]
  key_name = "Enter Your key Name"
  tags = {
    Name = "Enter Tag for the instance"
  }
}


resource "null_resource" "ssh_connection" {

  # Copy the Ansible playbook and Dockerfile to the instance
  
  provisioner "file" {
    source      = "playbook.yml"
    destination = "/home/ubuntu/playbook.yml"

    connection {
      type        = "ssh"
      host        = aws_instance.example.public_ip
      user        = "ubuntu"  
      private_key = file("/ path to your pem key")
    }
  }

  provisioner "file" {
    source      = "Dockerfile"
    destination = "/home/ubuntu/Dockerfile"

    connection {
      type = "ssh"
      host = aws_instance.example.public_ip
      user = "ubuntu"
      private_key = file("/path to your pem key")
    }
  }

  # Run the Ansible playbook after creation


  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-add-repository -y ppa:ansible/ansible",
      "sudo apt-get update",
      "sudo apt install -y ansible",
      "sudo apt-get update",
      "sudo apt-get install -y software-properties-common",
      "ansible-playbook -i localhost, -u ubuntu playbook.yml --extra-vars 'ANSIBLE_HOST_KEY_CHECKING=False' --private-key= `Your_key.pem` "
    ]

    connection {
      type = "ssh"
      host = aws_instance.example.public_ip
      user = "ubuntu"
      private_key = file("/path to your pem key")
    }
  }
}