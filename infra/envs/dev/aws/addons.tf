############################################################
# EKS core add-ons — Let AWS choose the recommended version,
# no data sources, no extra permissions needed.
############################################################

locals {
  eks_cluster_name = try(
    module.eks.cluster_name,
    try(module.eks.id, var.cluster_name)
  )
  eks_cluster_sg_id = module.eks.cluster_security_group_id
  alb_allowed_cidrs = var.alb_allowed_cidrs
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

resource "aws_security_group_rule" "allow_alb_to_pods_http" {
  type      = "ingress"
  from_port = 8080
  to_port   = 8080
  protocol  = "tcp"

  # EKS cluster/node SG
  security_group_id = module.alb_sg.security_group_id

  # ALB SG from the new alb_sg module
  source_security_group_id = module.eks.cluster_security_group_id

  description = "Allow ALB to reach pods via HTTP 8080"
}

resource "aws_security_group_rule" "alb_ingress_admin_http" {
  type              = "ingress"
  description       = "Allow admin HTTP 80 to ALB"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  security_group_id = module.alb_sg.security_group_id
  cidr_blocks       = local.alb_allowed_cidrs
}
