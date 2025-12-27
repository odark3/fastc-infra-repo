locals {
  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version
  region          = "ap-northeast-2"
  vpc_id          = var.vpc_id
  # public_subnets  = var.public_subnets
  private_subnets = var.private_subnets

  tags = {
    Environment = "test"
    Terraform   = "true"
  }
}

locals {
  eks_access_entries = merge(
      var.bootstrap_principal_arn == null ? {} : {
      bootstrap_admin = {
        principal_arn = var.bootstrap_principal_arn
        policy_associations = {
          cluster_admin = {
            policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
            access_scope = { type = "cluster" }
          }
        }
      }
    },

      var.platform_admin_role_arn == null ? {} : {
      platform_admin = {
        principal_arn = var.platform_admin_role_arn
        policy_associations = {
          cluster_admin = {
            policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
            access_scope = { type = "cluster" }
          }
        }
      }
    },

      var.app_team_role_arn == null ? {} : {
      app_team_edit = {
        principal_arn = var.app_team_role_arn
        policy_associations = {
          edit_default = {
            policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSEditPolicy"
            access_scope = {
              type       = "namespace"
              namespaces = ["default", "apps"]
            }
          }
        }
      }
    },

      var.app_team_view_role_arn == null ? {} : {
      app_team_view = {
        principal_arn = var.app_team_view_role_arn
        policy_associations = {
          view_default = {
            policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy"
            access_scope = {
              type       = "namespace"
              namespaces = ["default", "apps"]
            }
          }
        }
      }
    }
  )
}



module "eks" {
  # https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  # ########################################################
  name               = local.cluster_name
  kubernetes_version = "1.32"



  addons = {
    # CNI는 노드(Compute) 생성 전에 설치되게 강제
    vpc-cni = {
      before_compute = true
      most_recent    = true
    }

    # 나머지는 보통 노드 이후여도 OK
    kube-proxy = { most_recent = true }
    coredns    = { most_recent = true }

    # 있으면 같이
    eks-pod-identity-agent = { most_recent = true }
  }





  # Optional
  endpoint_public_access = true
  endpoint_private_access = true

  # Optional: Adds the current caller identity as an administrator via cluster access entry
  enable_cluster_creator_admin_permissions = false

  vpc_id                   = local.vpc_id
  subnet_ids               = local.private_subnets
  control_plane_subnet_ids = local.private_subnets

  eks_managed_node_groups = {
    example = {
      # Starting on 1.30, AL2023 is the default AMI type for EKS managed node groups
      ami_type = "AL2_x86_64"
      instance_types = ["t3.large"]


      min_size     = 2
      max_size     = 3
      desired_size = 2
    }
  }

  fargate_profiles = {
    karpenter-controller = {
      selectors = [
        {
          namespace = "karpenter"
          labels = {
            "app.kubernetes.io/name" = "karpenter"
          }
        }
      ]
    }
  }
  # Tag Node Security Group
  node_security_group_tags = merge(local.tags, {
    "karpenter.sh/discovery" = local.cluster_name
  })

  tags = local.tags
##########################################################
  # Network Setting


  # IRSA Enable / OIDC 구성
  enable_irsa = true

  # node_security_group_additional_rules = {
  #   ingress_nodes_karpenter_port = {
  #     description                   = "Cluster API to Node group for Karpenter webhook"
  #     protocol                      = "tcp"
  #     from_port                     = 8443
  #     to_port                       = 8443
  #     type                          = "ingress"
  #     source_cluster_security_group = true
  #   }
  # }






  # # console identity mapping (AWS user)
  # # eks configmap aws-auth에 콘솔 사용자 혹은 역할을 등록
  # access_entries = {
  #   # One access entry with a policy associated
  #   platform_admin = {
  #     principal_arn = "arn:aws:iam::363240302231:user/admin"
  #
  #     policy_associations = {
  #       cluster_admin = {
  #         policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy"
  #         access_scope = {
  #           namespaces = ["default"]
  #           type       = "namespace"
  #         }
  #       }
  #     }
  #   }
  # }
  # ======= 여기가 거버넌스 핵심 =======
  access_entries = local.eks_access_entries
}

// 프라이빗 서브넷 태그
resource "aws_ec2_tag" "private_subnet_tag" {
  for_each    = toset(local.private_subnets)
  resource_id = each.value
  key         = "kubernetes.io/role/internal-elb"
  value       = "1"
}

resource "aws_ec2_tag" "private_subnet_cluster_tag" {
  for_each    = toset(local.private_subnets)
  resource_id = each.value
  key         = "kubernetes.io/cluster/${local.cluster_name}"
  value       = "owned"
}

resource "aws_ec2_tag" "private_subnet_karpenter_tag" {
  for_each    = toset(local.private_subnets)
  resource_id = each.value
  key         = "karpenter.sh/discovery/${local.cluster_name}"
  value       = local.cluster_name
}

// 퍼블릭 서브넷 태그
# resource "aws_ec2_tag" "public_subnet_tag" {
#   for_each    = toset(local.public_subnets)
#   resource_id = each.value
#   key         = "kubernetes.io/role/elb"
#   value       = "1"
# }