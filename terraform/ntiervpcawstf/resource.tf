resource "aws_vpc" "ntier"{

    cidr_block = var.vpccidr

    tags =    {
        Name = "ntiervpc"
    }
}


resource "aws_subnet" "subnet"{
count = length(local.subnetnames)

    vpc_id = aws_vpc.ntier.id
    cidr_block = cidrsubnet(var.vpccidr,8,count.index)
    availability_zone = "${var.region}${count.index%2 == 0? "a": "b"}"
    tags =    {
        Name = local.subnetnames[count.index]
    }
    depends_on = [
        aws_vpc.ntier
    ]
    }



resource "aws_internet_gateway" "ntierigw" {
  vpc_id = aws_vpc.ntier.id

  tags = {
    Name = local.igw_name
  }
    depends_on = [
        aws_vpc.ntier
    ]
}


resource "aws_route_table" "publicrt" {
  vpc_id = aws_vpc.ntier.id
   tags = {

    Name = "publicrttf"
  }

  route  {
      cidr_block = local.anywhere
      gateway_id = aws_internet_gateway.ntierigw.id
       }
       
   
    depends_on = [
        aws_vpc.ntier,
        aws_subnet.subnet[0],
        aws_subnet.subnet[1],
        aws_internet_gateway.ntierigw
    ]
}

resource "aws_route_table_association" "webassociation" {
  count = 2
  subnet_id      = aws_subnet.subnet[count.index].id

  route_table_id = aws_route_table.publicrt.id

    depends_on = [
       aws_subnet.subnet[0],
        aws_subnet.subnet[1],
        aws_route_table.publicrt
    ]
}




resource "aws_route_table" "privatert" {
  vpc_id = aws_vpc.ntier.id
   tags = {

    Name = "privaterttf"
  }     
   
    depends_on = [
        aws_vpc.ntier,
        aws_subnet.subnet[2],
        aws_subnet.subnet[3],
        aws_subnet.subnet[4],
        aws_subnet.subnet[5],
       
    ]
}






resource "aws_route_table_association" "appassociation" {
  count = 4
  subnet_id      = aws_subnet.subnet[count.index+2].id

  route_table_id = aws_route_table.privatert.id

    depends_on = [
       aws_subnet.subnet[2],
        aws_subnet.subnet[3],
        aws_subnet.subnet[4],
        aws_subnet.subnet[5],
        aws_route_table.privatert
    ]
}

resource "aws_security_group" "websg" {
  name        = "websg"
  description = "allow ports 22 and 80 from all"
  vpc_id      = aws_vpc.ntier.id

  ingress     {
      description      = "allow all"
      from_port        = local.ssh
      to_port          = local.ssh
      protocol         = local.tcp
      cidr_blocks      = [local.anywhere]
      
    }
  
  ingress     {
      description      = "allow all"
      from_port        = local.http
      to_port          = local.http
      protocol         = local.tcp
      cidr_blocks      = [local.anywhere]
      
    }
  
  tags = {
    "Name" = "websgtf"
  }
  depends_on = [
    aws_route_table.publicrt,
    aws_route_table.privatert
  ]

}


resource "aws_security_group" "appsg" {
  name        = "appsg"
  description = "allow ports 22 and 8080 from vpc range"
  vpc_id      = aws_vpc.ntier.id

  ingress     {
      description      = "allow ssh port"
      from_port        = local.ssh
      to_port          = local.ssh
      protocol         = local.tcp
      cidr_blocks      = [var.vpccidr]
      
    }
  
  ingress      {
      description      = "allow app port"
      from_port        = local.appport
      to_port          = local.appport
      protocol         = local.tcp
      cidr_blocks      = [var.vpccidr]
      
    }
  
  tags = {
    "Name" = "appsgtf"
  }
  depends_on = [
    aws_route_table.publicrt,
    aws_route_table.privatert
  ]
}

resource "aws_security_group" "dbsg" {
  name        = "dbsg"
  description = "allow ports 3306 from vpc range"
  vpc_id      = aws_vpc.ntier.id

  ingress     {
      description      = "allow db port"
      from_port        = local.dbport
      to_port          = local.dbport
      protocol         = local.tcp
      cidr_blocks      = [var.vpccidr]
      
    }
  
  
  tags = {
    "Name" = "dbsgtf"
  }
  depends_on = [
    aws_route_table.publicrt,
    aws_route_table.privatert
  ]
}
