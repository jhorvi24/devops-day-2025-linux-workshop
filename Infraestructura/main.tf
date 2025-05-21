terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" { // you can configure different providers. In this template the provider is AWS
  region  = "us-east-1"
  profile = "jhorvi-aws"
}


#In the next part I define the services of the infrastructure

//--------------------------------------------------------------------//

#In this part I define the resources of the network infrastructure

resource "aws_vpc" "bookstore-vpc" {
  cidr_block = "192.168.0.0/16"
  enable_dns_hostnames = true
  tags = {
    Name = "bookstore-vpc"
  }
}

//------------------------------------------------------------------------//
#Configure the internet gateway of the network infrastructure

resource "aws_internet_gateway" "igw-bookstore" {

    vpc_id = aws_vpc.bookstore-vpc.id

    tags = {
      Name = "igw"
    }

}

resource "aws_route_table" "rt_igw"{
    vpc_id = aws_vpc.bookstore-vpc.id
    depends_on = [aws_internet_gateway.igw-bookstore]
    route {
      cidr_block = "0.0.0.0/0"
      gateway_id = aws_internet_gateway.igw-bookstore.id
    }

    tags = {
      Name = "rt_igw"
    }

}



#Associate the route table with the public subnet

resource "aws_route_table_association" "rt_igw_association" {
    subnet_id = aws_subnet.subnet-public-A.id
    route_table_id = aws_route_table.rt_igw.id
}




//------------------------------------------------------------------------//
#Configure the subnets of the network infrastructure

resource "aws_subnet" "subnet-public-A" {
  vpc_id     = aws_vpc.bookstore-vpc.id
  cidr_block = "192.168.1.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "subnet-public-A"
  }
}


resource "aws_subnet" "subnet-private-A" {
  vpc_id     = aws_vpc.bookstore-vpc.id
  cidr_block = "192.168.2.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "subnet-private-A"
  }
}

resource "aws_subnet" "subnet-private-B" {
  vpc_id     = aws_vpc.bookstore-vpc.id
  cidr_block = "192.168.3.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "subnet-private-B"
  }
}



//------------------------------------------------------------------------//

#Configure the security group of the network infrastructure

resource "aws_security_group" "web-server-sg" {
    name = "web-server-sg"
    description = "Allow inbound traffic from internet"
    vpc_id = aws_vpc.bookstore-vpc.id
    ingress {
      description = "Allow HTTP traffic"
      from_port = 80
      to_port = 80
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
     ingress {
      description = "Allow ssh traffic"
      from_port = 22
      to_port = 22
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }

  ingress {
      description = "Allow ssh traffic"
      from_port = 443
      to_port = 443
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"  #-1 mean all protocols
    cidr_blocks      = ["0.0.0.0/0"]

  }


    tags = {
      Name = "web-server-sg"
    }

}


resource "aws_security_group" "databases-sg" {

    name = "databases-sg"
    description = "Allow inbound traffic from web server"
    vpc_id = aws_vpc.bookstore-vpc.id

    ingress {
      description = "Allow traffic from webserver"
      from_port = 3306
      to_port = 3306
      protocol = "tcp"
      security_groups = [aws_security_group.web-server-sg.id]
    }

    egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"  #-1 mean all protocols
    cidr_blocks      = ["0.0.0.0/0"]

  }

}



#Configure the ec2 instance



resource "aws_instance" "bookstore-app_server" {
  ami           = "ami-084568db4383264d4"
  instance_type = "t2.micro"
  iam_instance_profile = "EC2s3"
  vpc_security_group_ids = [aws_security_group.web-server-sg.id]
  subnet_id = aws_subnet.subnet-public-A.id
  key_name = "serverKey"
  associate_public_ip_address = true
  depends_on = [ aws_db_instance.bookstore_db ]  #After created the RDS instance, create the ec2 instance
  user_data = base64encode(
    <<EOF
#!/bin/bash
sudo apt update
sudo apt upgrade -y
sudo apt install python3-pip -y
sudo apt install python3-virtualenv -y
sudo apt install mariadb-server -y
git clone https://github.com/jhorvi24/bookstore-python-flask.git
echo "Cloning repository"
DB_PATH="/bookstore-python-flask/databases"
echo 'export DB_PATH="/bookstore-python-flask/databases"' >> /home/ubuntu/.bashrc
source /home/ubuntu/.bashrc


if [ -d "bookstore-python-flask" ]; then

  echo "Cloned successfully"

  sudo chmod +x DB_PATH/*.sh

  if [ -f "DB_PATH/set-root-user.sh" ]; then

    sudo DB_PATH/set-root-user.sh
  else

    echo "No file set-root-user.sh found."
    exit 1
  fi

  if [ -f "DB_PATH/createdb.sh" ]; then

    sudo DB_PATH/createdb.sh

  else
    echo "No file createdb.sh found."
  fi

  DB_PASSWORD=$(aws ssm get-parameter --name "/bookstore/password" --with-decryption --query "Parameter.Value" --output text --region "us-east-1")
  sudo mysqldump --databases bookstore_db -u root -p$DB_PASSWORD > BookDbDump.sql
  rds_endpoint=${aws_db_instance.bookstore_db.address}
  echo $rds_endpoint
  mysql -u root -p$DB_PASSWORD --host ${aws_db_instance.bookstore_db.address} < BookDbDump.sql


else
  echo "Repository not found."
  exit 1
fi

EOF
  )

  tags = {
    Name = "bookstore-web-server"
  }
}

//------------------------------------------------------------------------//
#Configure the databases
#The password is saved in AWS System Manager Parameter Store

data "aws_ssm_parameter" "rds_password"{
    name = "/bookstore/password"
}

data "aws_ssm_parameter" "rds_username"{
    name = "/bookstore/user"
}



resource "aws_db_instance" "bookstore_db" {
    allocated_storage = 20
    identifier = "bookstore-db"
    storage_type = "gp2"
    engine = "mariadb"
    engine_version = "10.11.11"
    instance_class = "db.t3.micro"
    username = data.aws_ssm_parameter.rds_username.value
    password = data.aws_ssm_parameter.rds_password.value
    skip_final_snapshot = true
    db_subnet_group_name = aws_db_subnet_group.db-subnetGroup.id
    vpc_security_group_ids = [aws_security_group.databases-sg.id]
    tags = {
      Name = "bookstore-db"
    }

}

#Configure the database subnet group

resource "aws_db_subnet_group" "db-subnetGroup" {
    name = "bookstore-db-subnet-group"
    subnet_ids = [aws_subnet.subnet-private-A.id, aws_subnet.subnet-private-B.id]

    tags = {
      "Name" = "db-subnet-group"
    }

}

#After the DB is created, I update the RDS endpoint in AWS System Manager

resource "aws_ssm_parameter" "rds_endpoint" {
    name = "/bookstore/host"
    type = "String"
    value = aws_db_instance.bookstore_db.endpoint
    depends_on = [ aws_db_instance.bookstore_db ]
    overwrite = true

}