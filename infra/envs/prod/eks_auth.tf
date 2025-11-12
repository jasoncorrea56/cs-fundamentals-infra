############################################################
# EKS aws-auth & GitHub deployer RBAC
#
# - Maps:
#     - Worker node role  -> system:nodes (required for node auth)
#     - GitHub deploy IAM -> github-deployer group
# - Grants github-deployer only the permissions needed for:
#     - Helm upgrades of this app
#     - Reading core resources
#     - Creating the smoke-test Job
############################################################

resource "kubernetes_config_map_v1" "aws_auth" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }

  data = {
    # NOTE:
    # - If aws-auth already exists, import it before apply:
    #     terraform import kubernetes_config_map_v1.aws_auth kube-system/aws-auth
    #   then reconcile mapRoles to avoid clobbering.
    mapRoles = yamlencode([
      # Worker nodes: allow them to join the cluster
      {
        rolearn  = aws_iam_role.eks_node.arn
        username = "system:node:{{EC2PrivateDNSName}}"
        groups = [
          "system:bootstrappers",
          "system:nodes",
        ]
      },
      # GitHub Actions deploy role: maps to "github-deployer" group
      {
        rolearn  = aws_iam_role.gha_deployer.arn
        username = "github-deployer"
        groups = [
          "github-deployer",
        ]
      },
    ])
  }

  depends_on = [
    module.eks,
    aws_iam_role.eks_node,
    aws_iam_role.gha_deployer,
  ]
}

############################################################
# ClusterRole: github-deployer
#
# Scope:
# - Read pods/svcs/ing/CM/Secrets/SA for observability & Helm
# - Manage deployments/RS in support of Helm upgrades
# - Create/delete Jobs for in-cluster smoke tests
#
# Intentionally much narrower than cluster-admin.
############################################################

resource "kubernetes_manifest" "github_deployer_clusterrole" {
  manifest = {
    apiVersion = "rbac.authorization.k8s.io/v1"
    kind       = "ClusterRole"
    metadata = {
      name = "github-deployer"
    }
    rules = [
      # Read core workloads & config (no writes here)
      {
        apiGroups = [""]
        resources = [
          "pods",
          "pods/log",
          "services",
          "endpoints",
          "namespaces",
          "configmaps",
          "secrets",
          "serviceaccounts",
        ]
        verbs = ["get", "list", "watch"]
      },
      # Manage Deployments/ReplicaSets for Helm releases
      {
        apiGroups = ["apps"]
        resources = [
          "deployments",
          "replicasets",
        ]
        verbs = ["get", "list", "watch", "create", "update", "patch"]
      },
      # Allow creating/deleting Jobs for smoke tests
      {
        apiGroups = ["batch"]
        resources = ["jobs"]
        verbs     = ["get", "list", "watch", "create", "delete"]
      },
      # Read Ingress for verification
      {
        apiGroups = ["networking.k8s.io"]
        resources = ["ingresses"]
        verbs     = ["get", "list", "watch"]
      },
    ]
  }

  depends_on = [
    kubernetes_config_map_v1.aws_auth,
  ]
}

############################################################
# ClusterRoleBinding: bind aws-auth group -> ClusterRole
############################################################

resource "kubernetes_manifest" "github_deployer_clusterrolebinding" {
  manifest = {
    apiVersion = "rbac.authorization.k8s.io/v1"
    kind       = "ClusterRoleBinding"
    metadata = {
      name = "github-deployer-binding"
    }
    roleRef = {
      apiGroup = "rbac.authorization.k8s.io"
      kind     = "ClusterRole"
      name     = "github-deployer"
    }
    subjects = [
      {
        kind     = "Group"
        name     = "github-deployer" # must match aws-auth groups entry
        apiGroup = "rbac.authorization.k8s.io"
      }
    ]
  }

  depends_on = [
    kubernetes_manifest.github_deployer_clusterrole,
  ]
}
