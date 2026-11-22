# EC2 중지 시 자동 퍼블릭 IPv4 해제 vs EIP 유지 실습

- **블로그 글**: [EC2를 중지하면 퍼블릭 IPv4 요금은 멈출까: 자동 IP와 EIP 실측](https://labbook.dev/posts/ec2-stop-public-ipv4-eip-charge/) (초안 / 발행 예정)
- **목적**: EC2 인스턴스를 `stop-instances`로 중지했을 때 자동 할당 퍼블릭 IPv4는 해제되는 반면 탄력적 IP(EIP)는 그대로 연결된 채 유지되는 제어 플레인 동작을 최소 스펙(`t4g.nano`)으로 재현합니다.

> **스펙 안내**: 블로그 본문 실측은 비용 원칙 확정 전에 `t4g.micro`로 진행했지만, 자동 IP 해제와 EIP 유지는 인스턴스 크기와 무관한 제어 플레인 동작이므로 이 Terraform 코드는 최소 사양인 **`t4g.nano`**(기본 VPC, AMI 기본 8 GB EBS)를 기본값으로 사용합니다.

## 포함 파일

- `main.tf` / `variables.tf` / `outputs.tf`: 기본 VPC·서브넷 조회, 최신 Amazon Linux 2023 arm64 AMI 조회, 인바운드 없는 보안 그룹, `t4g.nano` 인스턴스(IMDSv2 필수), 선택적 EIP 및 연결(`allocate_eip`)

## 실행 방법 (Apply / Destroy)

### 1. 로컬 `moto` 에뮬레이터로 `plan` 검증

```bash
AWS_EC2_METADATA_DISABLED=true terraform init
AWS_EC2_METADATA_DISABLED=true terraform plan \
  -var="use_emulator=true" \
  -var="aws_endpoint_url=http://127.0.0.1:5000"
```

### 2. 실제 AWS 2단계 확인 및 삭제

1단계(자동 할당 IP 해제 확인):

```bash
terraform init
terraform apply -var="allocate_eip=false"

# 인스턴스 중지 후 퍼블릭 IPv4가 비는지 확인
INSTANCE_ID=$(terraform output -raw instance_id)
aws ec2 stop-instances --region ap-southeast-2 --instance-ids "$INSTANCE_ID"
aws ec2 wait instance-stopped --region ap-southeast-2 --instance-ids "$INSTANCE_ID"
aws ec2 describe-instances --region ap-southeast-2 --instance-ids "$INSTANCE_ID" \
  --query 'Reservations[].Instances[].PublicIpAddress'
```

2단계(EIP 유지 확인 후 즉시 정리):

```bash
terraform apply -var="allocate_eip=true"

# 중지된 상태에서도 EIP가 유지되는지 확인
aws ec2 describe-addresses --region ap-southeast-2 \
  --allocation-ids "$(terraform output -raw eip_allocation_id)"

# 확인 직후 즉시 모든 리소스 삭제 (EIP 포함)
terraform destroy -var="allocate_eip=true"
```

## 예상 비용

- `t4g.nano` (`ap-southeast-2` Linux): 시간당 약 **$0.0052** (실행 중일 때만 과금).
- 퍼블릭 IPv4 주소(자동 할당 또는 EIP): 사용 중인 IPv4 주소당 시간당 **$0.005** (EIP는 인스턴스를 중지해도 할당 해제 전까지 계속 과금).
- 기본 8 GB gp3 EBS: 약 **$0.096/GB-month** (인스턴스 종료 전까지 과금).
- NAT Gateway와 ALB는 생성하지 않습니다. 5분 내외 테스트 후 즉시 `terraform destroy` 시 **약 $0.01 이하**.

## 정리 체크리스트

- [ ] `terraform destroy` 완료 확인
- [ ] `aws ec2 describe-addresses --region ap-southeast-2` 결과가 비어 있는지(유휴 EIP 없음) 확인
- [ ] `aws ec2 describe-instances --region ap-southeast-2`에서 인스턴스 상태가 `terminated`인지 확인
- [ ] EBS 볼륨 잔여 없음 및 `labbook-ec2-ipv4-sg` 삭제 확인
