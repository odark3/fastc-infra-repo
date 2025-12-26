module "eks" {
  # eks 모듈에서 사용할 변수 정의
  source = "./modules/eks-cluster"
  cluster_name = "fast-cluster"
  cluster_version = "1.32"
  vpc_id = "vpc-00be289be11ac67c8"

  private_subnets = ["subnet-092959a166337f39d", "subnet-0c1b3a9813519f6c2"]
  # public_subnets  = ["subnet-086988a80349db3ca", "subnet-06208337644186f1e"]
}