resource "aws_key_pair" "ssh" {
  key_name                    = "ssh-key"
  public_key                  = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDA8/yN1BjsvLjTh8lu3IVPuxsEsfz6eKjPTkv3vka9iBiVO+FgC5Q53/ZPzNoblPoVNEvCZH43RlIZzBLBzFhGH89uKPG84F5fY2jp3tvUWikTxMAJR0bdFNPdr2k9720ZLhwj7yfUwEUQGy50cpvIG2gkpocTMs6R7Dxf2tNnaWTtIT4PZNuzGR082th51dWmptWs+mFihhP7+cEg671aHMHUJCto/YfQDqVYfufeBgL86in3gz6ZFCX8FAOvZ8I3a9ofb86g3udh/EUhK5j1x/rsYnA4VuhFIK3I9EzUL9dXNJDfWLO4/eXer597YULU02+gjpm5kkwp7khA4KsN root@LAPTOP-O6577UA5"
}
resource "aws_instance" "Frontend" {
  ami                         = "ami-09e67e426f25ce0d7"
  key_name                    =  aws_key_pair.ssh.key_name
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.Private_subnet_Front[1].id
  vpc_security_group_ids      = [aws_security_group.frontend_sg.id]
tags = {
    Name = "Frontend"
  }
}
resource "aws_instance" "Backend" {
  ami                         = "ami-09e67e426f25ce0d7"
  key_name                    =  aws_key_pair.ssh.key_name
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.Private_subnet_Back[1].id
  vpc_security_group_ids      = [aws_security_group.backend_sg.id]
tags = {
    Name = "Backend"
  }
}
resource "aws_instance" "bastion" {
  depends_on = [
     aws_instance.Frontend,
     aws_instance.Backend
  ]
  ami                         = "ami-09e67e426f25ce0d7"
  key_name                    =  aws_key_pair.ssh.key_name
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.Public_subnet[1].id
  vpc_security_group_ids      = [aws_security_group.bastion_sg.id]
  associate_public_ip_address = true
  tags = {
    Name = "bastion"
  }
}