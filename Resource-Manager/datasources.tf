## Copyright © 2020, Oracle and/or its affiliates. 
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl

# Get list of availability domains
data "oci_identity_availability_domains" "ADs" {
  compartment_id = var.tenancy_ocid
}

# Get the latest Oracle Linux image
data "oci_core_images" "InstanceImageOCID" {
  compartment_id           = var.compartment_Non_Security_Zone_ocid
  operating_system         = var.instance_os
  operating_system_version = var.linux_os_version

  filter {
    name   = "display_name"
    values = ["^.*Oracle[^G]*$"]
    regex  = true
  }
}

#Get list of MySQL configuration
data "oci_mysql_mysql_configurations" "mds_mysql_configurations" {
  compartment_id = var.compartment_Security_Zone_ocid
}


data "oci_cloud_guard_cloud_guard_configuration" "test_cloud_guard_configuration" {
    #Required
    compartment_id = var.compartment_Non_Security_Zone_ocid
}


data "oci_cloud_guard_detector_recipes" "list_detector_recipes" {

  compartment_id = var.tenancy_ocid
  state          = var.detector_recipe_state
  display_name   = "OCI Configuration Detector Recipe"

  depends_on = [oci_cloud_guard_cloud_guard_configuration.enable_cloud_guard]
}

data "oci_cloud_guard_responder_recipes" "list_responder_recipes" {
  compartment_id = var.tenancy_ocid
  state          = var.responder_recipe_state
  display_name   = "OCI Responder Recipe"

  depends_on = [oci_cloud_guard_cloud_guard_configuration.enable_cloud_guard]
}



data "oci_cloud_guard_target" "test_target" {
    #Required
 target_id = oci_cloud_guard_target.test_target.id
}

