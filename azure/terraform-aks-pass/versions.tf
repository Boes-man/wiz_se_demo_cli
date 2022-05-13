terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "2.66.0"
    }
    wiz = {
      version = " ~> 1.0"
      source = "tf.app.wiz.io/wizsec/wiz"
    }
  }
  required_version = ">= 0.14"
}

