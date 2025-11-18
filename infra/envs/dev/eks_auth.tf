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

# Derive optional console admins from tfvars
locals {
  # Roles (i.e. SSO assumed roles) -> system:masters
  admin_maproles = [
    for arn in try(var.console_admin_role_arns, []) : {
      rolearn  = arn
      username = "admin-console"
      groups   = ["system:masters"]
    }
  ]

  # Users (raw IAM users) -> system:masters
  admin_mapusers = [
    for arn in try(var.console_admin_user_arns, []) : {
      userarn  = arn
      username = "admin-console-user"
      groups   = ["system:masters"]
    }
  ]
}

# resource "kubernetes_config_map_v1" "aws_auth" {
#   metadata {
#     name      = "aws-auth"
#     namespace = "kube-system"
#   }

#   # Merge in optional admins & only emit mapUsers if provided.
#   data = merge(
#     {
#       # NOTE:
#       # - If aws-auth already exists, import it before apply:
#       #     terraform import kubernetes_config_map_v1.aws_auth kube-system/aws-auth
#       #   then reconcile mapRoles to avoid clobbering.
#       mapRoles = yamlencode(concat([
#         # Worker nodes: allow them to join the cluster
#         {
#           rolearn  = aws_iam_role.eks_node.arn
#           username = "system:node:{{EC2PrivateDNSName}}"
#           groups = [
#             "system:bootstrappers",
#             "system:nodes",
#           ]
#         },
#         # GitHub Actions deploy role: maps to "github-deployer" group
#         {
#           rolearn  = aws_iam_role.gha_deployer.arn
#           username = "github-deployer"
#           groups = [
#             "github-deployer",
#           ]
#         },
#       ], local.admin_maproles))
#     },
#     length(local.admin_mapusers) > 0 ? {
#       mapUsers = yamlencode(local.admin_mapusers)
#     } : {}
#   )

#   depends_on = [
#     module.eks,
#     aws_iam_role.eks_node,
#     aws_iam_role.gha_deployer,
#   ]
# }

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

# resource "kubernetes_manifest" "github_deployer_clusterrole" {
#   manifest = {
#     apiVersion = "rbac.authorization.k8s.io/v1"
#     kind       = "ClusterRole"
#     metadata   = { name = "github-deployer" }
#     rules = [
#       # --- Pod-level access (read + ephemeral curl pods for smoke tests) ---
#       {
#         apiGroups = [""]
#         resources = ["pods", "pods/log", "endpoints", "namespaces"]
#         verbs     = ["get", "list", "watch", "create", "delete"]
#       },

#       # --- Core objects Helm creates/updates in your chart ---
#       {
#         apiGroups = [""]
#         resources = ["services", "configmaps", "serviceaccounts", "secrets"]
#         verbs     = ["get", "list", "watch", "create", "update", "patch", "delete"]
#       },

#       # --- Workloads (Helm manages these during upgrade/rollback) ---
#       {
#         apiGroups = ["apps"]
#         resources = ["deployments", "replicasets"]
#         verbs     = ["get", "list", "watch", "create", "update", "patch", "delete"]
#       },

#       # --- Policy (PDB) ---
#       {
#         apiGroups = ["policy"]
#         resources = ["poddisruptionbudgets"]
#         verbs     = ["get", "list", "watch", "create", "update", "patch", "delete"]
#       },

#       # --- Autoscaling (HPA) ---
#       {
#         apiGroups = ["autoscaling"]
#         resources = ["horizontalpodautoscalers"]
#         verbs     = ["get", "list", "watch", "create", "update", "patch", "delete"]
#       },

#       # --- Ingress (ALB-backed) ---
#       {
#         apiGroups = ["networking.k8s.io"]
#         resources = ["ingresses"]
#         verbs     = ["get", "list", "watch", "create", "update", "patch", "delete"]
#       },

#       # --- Smoke-test Job lifecycle (from deploy workflow) ---
#       {
#         apiGroups = ["batch"]
#         resources = ["jobs"]
#         verbs     = ["get", "list", "watch", "create", "delete"]
#       },
#     ]
#   }

#   depends_on = [kubernetes_config_map_v1.aws_auth]
# }

############################################################
# ClusterRoleBinding: bind aws-auth group -> ClusterRole
############################################################

# resource "kubernetes_manifest" "github_deployer_clusterrolebinding" {
#   manifest = {
#     apiVersion = "rbac.authorization.k8s.io/v1"
#     kind       = "ClusterRoleBinding"
#     metadata = {
#       name = "github-deployer-binding"
#     }
#     roleRef = {
#       apiGroup = "rbac.authorization.k8s.io"
#       kind     = "ClusterRole"
#       name     = "github-deployer"
#     }
#     subjects = [
#       {
#         kind     = "Group"
#         name     = "github-deployer" # Match aws-auth group entry
#         apiGroup = "rbac.authorization.k8s.io"
#       }
#     ]
#   }

#   depends_on = [
#     kubernetes_manifest.github_deployer_clusterrole,
#   ]
# }
