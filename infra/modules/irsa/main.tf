data "aws_eks_cluster" "this" {
  name = var.cluster_name
}

data "tls_certificate" "oidc" {
  url = data.aws_eks_cluster.this.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  url            = data.aws_eks_cluster.this.identity[0].oidc[0].issuer
  client_id_list = ["sts.amazonaws.com"]

  # Use all certificates from the chain as thumbprints.
  thumbprint_list = [
    for c in data.tls_certificate.oidc.certificates : c.sha1_fingerprint
  ]
}
