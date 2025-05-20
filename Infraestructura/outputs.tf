output "instance_id" {
    description = "ID of the EC2 instance"
    value = aws_instance.bookstore-app_server.id
}

output "instance_public_ip" {
    description = "Public IP address of the EC2 instance"
    value = aws_instance.bookstore-app_server.public_ip

}

output "rds_endpoint" {

    description = "Endpoint of the RDS instance"
    value = aws_db_instance.bookstore_db.endpoint

}
