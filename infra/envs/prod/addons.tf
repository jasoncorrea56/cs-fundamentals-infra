############################################################
# EKS core add-ons — let AWS choose the recommended version
# (no data sources, no extra permissions needed)
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
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name                = local.eks_cluster_name
  addon_name                  = "kube-proxy"
  resolve_conflicts_on_update = "OVERWRITE"
}

resource "aws_eks_addon" "coredns" {
  cluster_name                = local.eks_cluster_name
  addon_name                  = "coredns"
  resolve_conflicts_on_update = "OVERWRITE"
}

resource "aws_eks_addon" "ebs_csi" {
  cluster_name                = local.eks_cluster_name
  addon_name                  = "aws-ebs-csi-driver"
  resolve_conflicts_on_update = "OVERWRITE"
  service_account_role_arn    = aws_iam_role.ebs_csi_irsa.arn

  depends_on                  = [aws_iam_role.ebs_csi_irsa]
}
