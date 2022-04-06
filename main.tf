terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"

    }
  }
    backend "azurerm" {
        resource_group_name  = ""
        storage_account_name = ""
        container_name       = ""
        key                  = ""
    }

}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = var.global_name_app
  location = var.llsappservice_location
}

resource "azurerm_service_plan" "sp" {
  name                = var.global_name_app
  resource_group_name = var.global_name_app
  location            = var.llsappservice_location
  sku_name            = "F1"
  os_type             = "Windows"

  depends_on = [ azurerm_resource_group.rg ]
}

resource "azurerm_windows_web_app" "wwa" {
  name                = var.global_name_app
  resource_group_name = var.global_name_app
  location            = var.llsappservice_location
  service_plan_id     = azurerm_service_plan.sp.id

  site_config {
      always_on         = false
      use_32_bit_worker = true
      ftps_state        = "Disabled"
      scm_use_main_ip_restriction = true
      virtual_application {
        physical_path = "site\\wwwroot" 
        preload       = false
        virtual_path  = "/"
      }
      ip_restriction {
        action      = "Deny"
        ip_address  = var.appservice_ip_block
        name        = "internet"
        priority    = 101 
      }
      ip_restriction {
        action      = "Allow"
        ip_address  = var.appservice_ip_allow
        name        = "myip"
        priority    = 100
      } 
      application_stack {
          current_stack   = "dotnet"
          dotnet_version  = "v4.0"
      }  

  }

  depends_on = [ azurerm_service_plan.sp ]
}

resource "null_resource" "zipdeploy" {
  provisioner "local-exec" {
    when = create
    command = "az webapp deployment source config-zip -g ${var.global_name_app} -n ${var.global_name_app} --src aspnetapp.zip"
  }
  depends_on = [ azurerm_windows_web_app.wwa ]
}
