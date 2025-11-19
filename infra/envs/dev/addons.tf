############################################################
# EKS core add-ons — Let AWS choose the recommended version,
# no data sources, no extra permissions needed.
############################################################

locals {
  eks_cluster_name = try(
    module.eks.cluster_name,
    try(module.eks.id, var.cluster_name)
  )
}

resource "aws_eks_addon" "vpc_cni" {
  cluster_name                = local.eks_cluster_name
  addon_name                  = "vpc-cni"
  resolve_conflicts_on_update = "OVERWRITE"

  timeouts {
    create = "5m"
    update = "5m"
    delete = "5m"
  }
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name                = local.eks_cluster_name
  addon_name                  = "kube-proxy"
  resolve_conflicts_on_update = "OVERWRITE"

  timeouts {
    create = "5m"
    update = "5m"
    delete = "5m"
  }
}

resource "aws_eks_addon" "coredns" {
  cluster_name                = local.eks_cluster_name
  addon_name                  = "coredns"
  resolve_conflicts_on_update = "OVERWRITE"

  timeouts {
    create = "5m"
    update = "5m"
    delete = "5m"
  }
}

# Dev doesn't currently need dynamic EBS PV provisioning, so we skip the
# EBS CSI addon here to keep the cluster simpler. Prod keeps this enabled.
# When dev needs PVs, re-enable this block.
# resource "aws_eks_addon" "ebs_csi" {
#   cluster_name                = local.eks_cluster_name
#   addon_name                  = "aws-ebs-csi-driver"
#   resolve_conflicts_on_update = "OVERWRITE"
#   service_account_role_arn    = aws_iam_role.ebs_csi_irsa.arn

#   depends_on = [aws_iam_role.ebs_csi_irsa]

#   timeouts {
#     create = "5m"
#     update = "5m"
#     delete = "5m"
#   }
# }

# Allow ALB to reach pods on HTTP 8080 via the cluster SG
data "aws_security_group" "eks_cluster" {
  filter {
    name   = "tag:aws:eks:cluster-name"
    values = [module.eks.cluster_name]
  }
}

resource "aws_security_group_rule" "allow_alb_to_pods_http" {
  type      = "ingress"
  from_port = 8080
  to_port   = 8080
  protocol  = "tcp"

  # EKS cluster/node SG
  security_group_id = data.aws_security_group.eks_cluster.id

  # ALB SG from the new alb_sg module
  source_security_group_id = module.alb_sg.security_group_id

  description = "Allow ALB to reach pods via HTTP 8080"
}
