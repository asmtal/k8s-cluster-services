terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "2.4.1"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.7.1"
    }
  }
}

data "terraform_remote_state" "k8s_user_pki" {
  backend = "remote"

  count = (length(var.k8s_client_certificate) > 0 || length(var.k8s_client_key) > 0 || length(var.k8s_cluster_ca_cert) > 0) ? 0 : 1

  config = {
    organization = "McSwainHomeNetwork"
    workspaces = {
      name = "k8s-user-pki"
    }
  }
}

provider "helm" {
  kubernetes {
    host                   = var.k8s_host
    client_certificate     = length(var.k8s_client_certificate) > 0 ? var.k8s_client_certificate : data.terraform_remote_state.k8s_user_pki[0].outputs.ci_user_cert_pem
    client_key             = length(var.k8s_client_key) > 0 ? var.k8s_client_key : data.terraform_remote_state.k8s_user_pki[0].outputs.ci_user_key_pem
    cluster_ca_certificate = length(var.k8s_cluster_ca_cert) > 0 ? var.k8s_cluster_ca_cert : data.terraform_remote_state.k8s_user_pki[0].outputs.ca_cert_pem
  }
}

provider "kubernetes" {
  host                   = var.k8s_host
  client_certificate     = length(var.k8s_client_certificate) > 0 ? var.k8s_client_certificate : data.terraform_remote_state.k8s_user_pki[0].outputs.ci_user_cert_pem
  client_key             = length(var.k8s_client_key) > 0 ? var.k8s_client_key : data.terraform_remote_state.k8s_user_pki[0].outputs.ci_user_key_pem
  cluster_ca_certificate = length(var.k8s_cluster_ca_cert) > 0 ? var.k8s_cluster_ca_cert : data.terraform_remote_state.k8s_user_pki[0].outputs.ca_cert_pem
}

module "metallb" {
  source = "./modules/metallb"

  providers = {
    helm       = helm
    kubernetes = kubernetes
  }
}

module "nginx-ingress" {
  source = "./modules/nginx-ingress"

  providers = {
    helm       = helm
    kubernetes = kubernetes
  }

  depends_on = [module.metallb]
}
