# PSA labels on namespace (restricted)
# Use kubernetes_manifest to avoid drift on the existing "default" ns.
resource "kubernetes_manifest" "psa_labels" {
  count = var.manage_namespace ? 1 : 0

  manifest = {
    apiVersion = "v1"
    kind       = "Namespace"
    metadata = {
      name = var.namespace
      labels = {
        "kubernetes.io/metadata.name"                = var.namespace
        "pod-security.kubernetes.io/enforce"         = "restricted"
        "pod-security.kubernetes.io/enforce-version" = "latest"
        "pod-security.kubernetes.io/warn"            = "restricted"
        "pod-security.kubernetes.io/warn-version"    = "latest"
      }
    }
  }
}

# --- RBAC (namespace-scoped) ---

# Minimally-privileged view role (no Secrets)
resource "kubernetes_manifest" "role_view" {
  manifest = {
    apiVersion = "rbac.authorization.k8s.io/v1"
    kind       = "Role"
    metadata = {
      name      = "viewer"
      namespace = var.namespace
    }
    rules = [
      {
        apiGroups = [""]
        resources = ["pods", "services", "endpoints", "configmaps"]
        verbs     = ["get", "list", "watch"]
      },
      {
        apiGroups = ["apps"]
        resources = ["deployments", "replicasets", "statefulsets"]
        verbs     = ["get", "list", "watch"]
      }
    ]
  }
  depends_on = [kubernetes_manifest.psa_labels]
}

# Admin-ish role (namespace-only - not cluster-admin)
resource "kubernetes_manifest" "role_app_admin" {
  manifest = {
    apiVersion = "rbac.authorization.k8s.io/v1"
    kind       = "Role"
    metadata = {
      name      = "app-admin"
      namespace = var.namespace
    }
    rules = [
      {
        apiGroups = ["", "apps", "batch", "autoscaling", "policy", "networking.k8s.io"]
        resources = ["*"]
        verbs     = ["*"]
      }
    ]
  }
  depends_on = [kubernetes_manifest.psa_labels]
}

# Bind app ServiceAccount to viewer by default (least privilege)
resource "kubernetes_manifest" "rb_view_sa" {
  manifest = {
    apiVersion = "rbac.authorization.k8s.io/v1"
    kind       = "RoleBinding"
    metadata = {
      name      = "viewer-${var.namespace}-app"
      namespace = var.namespace
    }
    subjects = [{
      kind      = "ServiceAccount"
      name      = var.service_account
      namespace = var.namespace
    }]
    roleRef = {
      apiGroup = "rbac.authorization.k8s.io"
      kind     = "Role"
      name     = "viewer"
    }
  }
  depends_on = [kubernetes_manifest.role_view]
}

# --- NetworkPolicies ---

# 1) Default deny ingress & egress
resource "kubernetes_network_policy_v1" "default_deny_all" {
  metadata {
    name      = "default-deny-all-the-things"
    namespace = var.namespace
  }
  spec {
    pod_selector {}
    policy_types = ["Ingress", "Egress"]
    # No ingress/egress blocks => deny all by default
  }
  depends_on = [kubernetes_manifest.psa_labels]
}

# 2) Allow ingress to app pods on service port from anywhere within the cluster.
#    ALB (target-type: ip) originates from VPC IP ranges which are opaque at deploy time,
#    allowing cluster sources keeps it reachable but still blocks cross-namespace by default.
resource "kubernetes_manifest" "np_allow_app_ingress" {
  manifest = {
    apiVersion = "networking.k8s.io/v1"
    kind       = "NetworkPolicy"
    metadata = {
      name      = "allow-app-ingress"
      namespace = var.namespace
    }
    spec = {
      podSelector = {
        matchLabels = {
          (var.app_selector.key) = var.app_selector.value
        }
      }
      policyTypes = ["Ingress"]
      ingress = [
        {
          from = concat(
            [
              # Same namespace pods (Optional - keep for intra-ns calls)
              { podSelector = {} }
            ],
            [
              for cidr in var.ingress_cidrs : { ipBlock = { cidr = cidr } }
            ]
          )
          ports = [
            { protocol = "TCP", port = var.app_port }
          ]
        }
      ]
    }
  }
  depends_on = [kubernetes_network_policy_v1.default_deny_all]
}

# 3) Allow egress to kube-dns (UDP/TCP 53) in kube-system
resource "kubernetes_manifest" "np_allow_dns_egress" {
  manifest = {
    apiVersion = "networking.k8s.io/v1"
    kind       = "NetworkPolicy"
    metadata = {
      name      = "allow-dns-egress"
      namespace = var.namespace
    }
    spec = {
      podSelector = {}
      policyTypes = ["Egress"]
      egress = [
        {
          to = [{
            namespaceSelector = {
              matchLabels = {
                "kubernetes.io/metadata.name" = "kube-system"
              }
            }
            podSelector = {
              matchLabels = {
                "k8s-app" = "kube-dns"
              }
            }
          }]
          ports = [
            { protocol = "UDP", port = 53 },
            { protocol = "TCP", port = 53 }
          ]
        }
      ]
    }
  }
  depends_on = [kubernetes_network_policy_v1.default_deny_all]
}

# 4) Optional: allow HTTPS egress
resource "kubernetes_manifest" "np_allow_https_egress" {
  count = var.allow_https_egress.enabled ? 1 : 0
  manifest = {
    apiVersion = "networking.k8s.io/v1"
    kind       = "NetworkPolicy"
    metadata = {
      name      = "allow-https-egress"
      namespace = var.namespace
    }
    spec = {
      podSelector = {}
      policyTypes = ["Egress"]
      egress = [
        {
          to    = [{ ipBlock = { cidr = "0.0.0.0/0" } }]
          ports = [{ protocol = "TCP", port = 443 }]
        }
      ]
    }
  }
  depends_on = [kubernetes_network_policy_v1.default_deny_all]
}

# 5) Optional: allow DB egress to specific CIDRs/ports
resource "kubernetes_manifest" "np_allow_db_egress" {
  count = var.allow_db_egress.enabled ? 1 : 0
  manifest = {
    apiVersion = "networking.k8s.io/v1"
    kind       = "NetworkPolicy"
    metadata = {
      name      = "allow-db-egress"
      namespace = var.namespace
    }
    spec = {
      podSelector = {}
      policyTypes = ["Egress"]
      egress = [
        {
          to = [
            for cidr in var.allow_db_egress.cidrs : {
              ipBlock = { cidr = cidr }
            }
          ]
          ports = [
            for p in var.allow_db_egress.ports : {
              protocol = "TCP"
              port     = p
            }
          ]
        }
      ]
    }
  }
  depends_on = [kubernetes_network_policy_v1.default_deny_all]
}

# 6) Allow HTTP egress from any pod in the namespace (Smoke-Test Job)
#    to the app pods on the service port (var.app_port [80]).
resource "kubernetes_manifest" "np_allow_http_egress_to_app" {
  manifest = {
    apiVersion = "networking.k8s.io/v1"
    kind       = "NetworkPolicy"
    metadata = {
      name      = "allow-http-egress-to-app"
      namespace = var.namespace
    }
    spec = {
      podSelector = {} # Applies to all pods
      policyTypes = ["Egress"]
      egress = [
        {
          to = [{
            podSelector = {
              matchLabels = {
                (var.app_selector.key) = var.app_selector.value
              }
            }
          }]
          ports = [
            { protocol = "TCP", port = var.app_port } # Matches service port [80]
          ]
        }
      ]
    }
  }
  depends_on = [kubernetes_network_policy_v1.default_deny_all]
}
