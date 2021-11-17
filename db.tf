resource "aws_db_subnet_group" "backenddb" {
  name                      = "backenddb"
  subnet_ids                = [aws_subnet.Private_subnet_DB[1].id,aws_subnet.Private_subnet_DB[2].id]
  tags = {
    Name = "DB subnet group"
  }
}

resource "aws_db_instance" "backend" {
  identifier                = "backenddb"
  allocated_storage         = 20
  engine                    = "mysql"
  engine_version            = "8.0.23"
  instance_class            = "db.t2.micro"
  name                      = "DB"
  username                  = "user"
  password                  = "password"
  db_subnet_group_name      = aws_db_subnet_group.backenddb.id
  vpc_security_group_ids    = [aws_security_group.DB_sg.id]
  skip_final_snapshot       = true
  final_snapshot_identifier = "Ignore"
}