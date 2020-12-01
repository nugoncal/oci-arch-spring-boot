#cloud-config


runcmd:
  # Run firewall commands to open DNS (udp/53)
###  - sudo firewall-offline-cmd --zone=public --add-port=53/udp

  - sudo yum update -y
  - sudo yum install java -y
  - sudo yum install maven -y
 
