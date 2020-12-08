## Copyright © 2020, Oracle and/or its affiliates. 
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

resource "oci_core_vcn" "vcn01" {
  cidr_block     = var.vcn01_cidr_block
  dns_label      = var.vcn01_dns_label
  compartment_id = var.compartment_ocid
  display_name   = var.vcn01_display_name
}

resource "oci_core_vcn" "vcn02" {
  cidr_block     = var.vcn02_cidr_block
  dns_label      = var.vcn02_dns_label
  compartment_id = var.compartment_SZ_ocid
  display_name   = var.vcn02_display_name
}

resource "oci_core_local_peering_gateway" "vcn01_local_peering_gateway" {
    #Required
    compartment_id = var.compartment_ocid
    vcn_id = oci_core_vcn.vcn01.id
     peer_id = oci_core_local_peering_gateway.vcn02_local_peering_gateway.id
 ##    route_table_id = oci_core_default_route_table.vcn02_default_route_table.id

    #Optional
   # defined_tags = {"Operations.CostCenter"= "42"}
   # display_name = var.local_peering_gateway_display_name
   # freeform_tags = {"Department"= "Finance"}
   # peer_id = oci_core_local_peering_gateway.test_local_peering_gateway2.id
   # route_table_id = oci_core_route_table.test_route_table.id
}

resource "oci_core_local_peering_gateway" "vcn02_local_peering_gateway" {
    #Required
    compartment_id = var.compartment_SZ_ocid
    vcn_id = oci_core_vcn.vcn02.id
 ###route_table_id = oci_core_default_route_table.vcn01_default_route_table.id
    ###peer_id = oci_core_local_peering_gateway.vcn01_local_peering_gateway.id

    #Optional
   # defined_tags = {"Operations.CostCenter"= "42"}
   # display_name = var.local_peering_gateway_display_name
   # freeform_tags = {"Department"= "Finance"}
   # peer_id = oci_core_local_peering_gateway.test_local_peering_gateway2.id
   # route_table_id = oci_core_route_table.test_route_table.id
}

#IGW
resource "oci_core_internet_gateway" "vcn01_internet_gateway" {
    compartment_id = var.compartment_ocid
    vcn_id = oci_core_vcn.vcn01.id
    enabled = "true"
    display_name = "IGW_vcn01"
}


###resource "oci_core_nat_gateway" "vcn01_nat_gateway" {
###    compartment_id = var.compartment_ocid
###   vcn_id = oci_core_vcn.vcn01.id
###    display_name = "NAT_GW_vcn01"
###}

###resource "oci_core_nat_gateway" "vcn02_nat_gateway" {
###    compartment_id = var.compartment_SZ_ocid
###    vcn_id = oci_core_vcn.vcn02.id
###    display_name = "NAT_GW_vcn02"
###}
#Default route table vcn01
resource "oci_core_default_route_table" "vcn01_default_route_table" {
    manage_default_resource_id = oci_core_vcn.vcn01.default_route_table_id
    route_rules {
        network_entity_id = oci_core_internet_gateway.vcn01_internet_gateway.id
        destination       = "0.0.0.0/0"
        destination_type  = "CIDR_BLOCK"
    }  

    route_rules {
        network_entity_id = oci_core_local_peering_gateway.vcn01_local_peering_gateway.id
        destination       = var.vcn02_cidr_block
        destination_type  = "CIDR_BLOCK"
    }  
}

#Default route table vcn02
resource "oci_core_default_route_table" "vcn02_default_route_table" {
    manage_default_resource_id = oci_core_vcn.vcn02.default_route_table_id
    route_rules {
        network_entity_id = oci_core_local_peering_gateway.vcn02_local_peering_gateway.id
        destination       = var.vcn01_cidr_block
        destination_type  = "CIDR_BLOCK"
    }   

}


#Default security list
resource "oci_core_default_security_list" "vcn01_default_security_list" {
    manage_default_resource_id = oci_core_vcn.vcn01.default_security_list_id
    egress_security_rules {
        destination = "0.0.0.0/0"
        protocol = "all"
    }

  ingress_security_rules {
      protocol = "all"
      source   = "0.0.0.0/0"


    }
  
}

resource "oci_core_default_security_list" "vcn02_default_security_list" {
    manage_default_resource_id = oci_core_vcn.vcn02.default_security_list_id
    egress_security_rules {
        destination = "0.0.0.0/0"
        protocol = "all"
    }
             
}

resource "oci_core_security_list" "vcn01_db_security_list" {
    compartment_id = var.compartment_ocid
    vcn_id = oci_core_vcn.vcn01.id
    display_name = "MDSSecureList"
    egress_security_rules {
        destination = "0.0.0.0/0"
        protocol = "all"
    }
    ingress_security_rules {
        protocol = 6
        source = "0.0.0.0/0"

        source_type = "CIDR_BLOCK"
        tcp_options {
            max = 3306
            min = 3306
        }
    }
    ingress_security_rules {
        protocol = 6
        source = "0.0.0.0/0"

        source_type = "CIDR_BLOCK"
        tcp_options {
            max = 33060
            min = 33060
        }
    }
             
}
resource "oci_core_network_security_group" "BastionSecurityGroup" {
    compartment_id = var.compartment_ocid
    vcn_id = oci_core_vcn.vcn01.id
    display_name = "Bastion_NSG"
}

resource "oci_core_network_security_group_security_rule" "BastionSecurityIngressGroupRules" {
    network_security_group_id = oci_core_network_security_group.BastionSecurityGroup.id
    direction = "INGRESS"
    protocol = "6"
    source = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    tcp_options {
        destination_port_range {
            max = 22
            min = 22
        }
    }
}

resource "oci_core_network_security_group" "LBSecurityGroup" {
    compartment_id = var.compartment_ocid
    vcn_id = oci_core_vcn.vcn01.id
    display_name = "LB_NSG"
}

resource "oci_core_network_security_group_security_rule" "LBSecurityIngressGroupRules_TCP80" {
    network_security_group_id = oci_core_network_security_group.LBSecurityGroup.id
    direction = "INGRESS"
    protocol = "6"
    source = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    tcp_options {
        destination_port_range {
            max = 80
            min = 80
        }
    }
}

resource "oci_core_network_security_group_security_rule" "LBSecurityIngressGroupRules_TCP443" {
    network_security_group_id = oci_core_network_security_group.LBSecurityGroup.id
    direction = "INGRESS"
    protocol = "6"
    source = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    tcp_options {
        destination_port_range {
            max = 443
            min = 443
        }
    }
}


resource "oci_core_network_security_group" "APPSecurityGroup" {
    compartment_id = var.compartment_ocid
    vcn_id = oci_core_vcn.vcn01.id
    display_name = "APP_NSG"
}

resource "oci_core_network_security_group_security_rule" "APPSecurityIngressGroupRules" {
    network_security_group_id = oci_core_network_security_group.APPSecurityGroup.id
    direction = "INGRESS"
    protocol = "6"
    source = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    tcp_options {
        destination_port_range {
            max = 8080
            min = 8080
        }
    }
}


###resource "oci_core_route_table" "vnc01_nat_route_table" {
###    compartment_id = var.compartment_ocid
###    vcn_id = oci_core_vcn.vcn01.id
###    display_name = "NAT_RT"
###    route_rules {
###        network_entity_id = oci_core_nat_gateway.vcn01_nat_gateway.id
###        cidr_block = "0.0.0.0/0"
###        destination_type = "CIDR_BLOCK"
###    }
###}


#vcn01 pub01 subnet
resource "oci_core_subnet" "vcn01_subnet_pub01" {
    cidr_block = var.vcn01_subnet_pub01_cidr_block
    compartment_id = var.compartment_ocid
    vcn_id = oci_core_vcn.vcn01.id
    display_name = var.vcn01_subnet_pub01_display_name
}

#vcn01 pub02 subnet
resource "oci_core_subnet" "vcn01_subnet_pub02" {
    cidr_block = var.vcn01_subnet_pub02_cidr_block
    compartment_id = var.compartment_ocid
    vcn_id = oci_core_vcn.vcn01.id
    display_name = var.vcn01_subnet_pub02_display_name
}

#vcn01 app01 subnet
resource "oci_core_subnet" "vcn01_subnet_app01" {
    cidr_block = var.vcn01_subnet_app01_cidr_block
    compartment_id = var.compartment_ocid
    vcn_id = oci_core_vcn.vcn01.id
    display_name = var.vcn01_subnet_app01_display_name
    prohibit_public_ip_on_vnic = false
}

###resource "oci_core_route_table_attachment" "vcn01_subnet_app01_route_table_attachment" {
###  subnet_id = oci_core_subnet.vcn01_subnet_app01.id
###  route_table_id = oci_core_default_route_table.vcn01_default_route_table
###}


#vcn01 db01 subnet
###resource "oci_core_subnet" "vcn01_subnet_db01" {
###    cidr_block = var.vcn01_subnet_db01_cidr_block
###    compartment_id = var.compartment_ocid
###    dns_label = "dbsubnet"
###    vcn_id = oci_core_vcn.vcn01.id
###    display_name = var.vcn01_subnet_db01_display_name
###    prohibit_public_ip_on_vnic = true
###}
###resource "oci_core_route_table_attachment" "vcn01_subnet_db01_route_table_attachment" {
###  subnet_id = oci_core_subnet.vcn01_subnet_db01.id
###  route_table_id = oci_core_route_table.vnc01_nat_route_table.id
###}

#vcn02 db01 subnet
resource "oci_core_subnet" "vcn02_subnet_db01" {
    cidr_block = var.vcn02_subnet_db01_cidr_block
    compartment_id = var.compartment_SZ_ocid
    dns_label = "dbsubnet"
    vcn_id = oci_core_vcn.vcn02.id
    display_name = var.vcn02_subnet_db01_display_name
    prohibit_public_ip_on_vnic = true
}
#resource "oci_core_route_table_attachment" "vcn02_subnet_db01_route_table_attachment" {
#  subnet_id = oci_core_subnet.vcn02_subnet_db01.id
#  route_table_id = oci_core_route_table.vcn01_default_route_table.id
#}

resource "oci_cloud_guard_cloud_guard_configuration" "vcn01_cloud_guard_configuration" {
    #Required
    compartment_id = var.tenancy_ocid 
    reporting_region = var.region
    status = var.cloud_guard_configuration_status

}

resource "oci_cloud_guard_cloud_guard_configuration" "enable_cloud_guard" {
  #Required
  compartment_id   = var.tenancy_ocid
  reporting_region = var.cloud_guard_configuration_reporting_region
  status           = var.cloud_guard_configuration_status
}


resource "oci_cloud_guard_detector_recipe" "cloned_detector_recipe" {
  #Required
  compartment_id            = var.compartment_ocid
  display_name              = var.detector_recipe1_display_name
  source_detector_recipe_id = data.oci_cloud_guard_detector_recipes.list_detector_recipes.detector_recipe_collection.0.items.0.id
}

resource "oci_cloud_guard_responder_recipe" "cloned_responder_recipe" {
  compartment_id             = var.compartment_ocid
  description                = var.responder_recipe1_description
  display_name               = var.responder_recipe1_display_name
  source_responder_recipe_id = data.oci_cloud_guard_responder_recipes.list_responder_recipes.responder_recipe_collection.0.items.0.id

}
resource "oci_cloud_guard_detector_recipe" "cloned2_detector_recipe" {
  #Required
  compartment_id            = var.compartment_ocid
  display_name              = var.detector_recipe2_display_name
  source_detector_recipe_id = data.oci_cloud_guard_detector_recipes.list_detector_recipes.detector_recipe_collection.0.items.0.id
}

resource "oci_cloud_guard_responder_recipe" "cloned2_responder_recipe" {
  compartment_id             = var.compartment_ocid
  description                = var.responder_recipe2_description
  display_name               = var.responder_recipe2_display_name
  source_responder_recipe_id = data.oci_cloud_guard_responder_recipes.list_responder_recipes.responder_recipe_collection.0.items.0.id

}


resource "oci_cloud_guard_target" "test_target" {
  #Required
  compartment_id = var.compartment_ocid
  display_name = var.target1_display_name
  target_resource_id = var.compartment_ocid

  target_resource_type = var.target_target_resource_type
  description   = var.target_description
  state         = var.target_state

  target_detector_recipes {
    detector_recipe_id = oci_cloud_guard_detector_recipe.cloned_detector_recipe.id
  }
  target_responder_recipes {
    responder_recipe_id = oci_cloud_guard_responder_recipe.cloned_responder_recipe.id
   
  }

}

resource "oci_cloud_guard_target" "test_target2" {
  #Required
  compartment_id = var.compartment_SZ_ocid
  display_name = var.target2_display_name

  target_resource_id = var.compartment_SZ_ocid
  target_resource_type = var.target_target_resource_type
  description   = var.target_description
  state         = var.target_state

  target_detector_recipes {
    detector_recipe_id = oci_cloud_guard_detector_recipe.cloned2_detector_recipe.id
  }
target_responder_recipes {
    responder_recipe_id = oci_cloud_guard_responder_recipe.cloned2_responder_recipe.id
   
  }
}


# # Bastion VM

resource "oci_core_instance" "bastion_instance" {
  availability_domain = data.oci_identity_availability_domains.ADs.availability_domains[1]["name"]
  compartment_id = var.compartment_ocid
  display_name = "BastionVM"
  shape = var.BastionInstanceShape

  create_vnic_details {
    subnet_id = oci_core_subnet.vcn01_subnet_pub02.id
    display_name = "primaryvnic"
    assign_public_ip = true
  }

  source_details {
    source_type             = "image"
    source_id               = data.oci_core_images.InstanceImageOCID.images[0].id
    boot_volume_size_in_gbs = "50"
  }

  metadata = {
    ###ssh_authorized_keys = var.ssh_public_key
    ##ssh_authorized_keys = chomp(file(var.ssh_public_key))
    ssh_authorized_keys = tls_private_key.public_private_key_pair.public_key_openssh
  }
  # timeouts {
  #   create = "60m"
  # }
}