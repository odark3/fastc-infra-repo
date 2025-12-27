module "eks" {
  # eks 모듈에서 사용할 변수 정의
  source = "./modules/eks-cluster"
  cluster_name = "fast-cluster"
  cluster_version = "1.32"
  vpc_id = "vpc-09da5bb6c1643cec6"

  private_subnets = ["subnet-0372fe0de55934c57", "subnet-05af3cc427f452091"]
  # public_subnets  = ["subnet-054ec239e07345ffc", "subnet-07f41782e24d1e723"]
  bootstrap_principal_arn = "arn:aws:iam::363240302231:user/admin"

}