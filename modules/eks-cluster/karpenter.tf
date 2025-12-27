# locals {
#   karpenter_namespace = "karpenter"
#   # tags = {
#   #   Environment = "dev"
#   #   Terraform   = "true"
#   # }
# }
#
# module "karpenter" {
#   source = "terraform-aws-modules/eks/aws//modules/karpenter"
#   version = "21.10.1"
#   cluster_name = module.eks.cluster_name
#   namespace    = local.karpenter_namespace
#
#   # Karpenter가 만들어낼 "EC2 노드들"에 붙일 Role
#   # 처음엔 기존 example 노드 role 재사용해도 OK
#   create_node_iam_role = false
#   node_iam_role_arn    = module.eks.eks_managed_node_groups["example"].iam_role_arn
#
#   # ✅ Pod Identity association (Helm에 role-arn annotation 불필요)
#   create_pod_identity_association = true
#
#   # Since the node group role will already have an access entry
#   create_access_entry = false
#   # tags = local.tags
# }
#
# resource "helm_release" "karpenter" {
#   name             = "karpenter"
#   namespace        = local.karpenter_namespace
#   create_namespace = true
#
#   repository          = "oci://public.ecr.aws/karpenter"
#   repository_username = data.aws_ecrpublic_authorization_token.token.user_name
#   repository_password = data.aws_ecrpublic_authorization_token.token.password
#   chart               = "karpenter"
#   version             = "1.7.4"
#
#   values = [<<-EOT
# settings:
#   clusterName: ${module.eks.cluster_name}
#   clusterEndpoint: ${module.eks.cluster_endpoint}
#   interruptionQueue: ${module.karpenter.queue_name}
# EOT
#   ]
#
#   lifecycle { ignore_changes = [repository_password] }
# }