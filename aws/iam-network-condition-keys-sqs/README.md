# IAM 네트워크 조건 키와 SQS 대기열 정책 실습

- **블로그 글**: [IAM 네트워크 조건 키와 SQS 대기열 정책: 값이 비는 순간 Deny가 터진다](https://labbook.dev/posts/iam-network-condition-keys-sqs/)
- **목적**: SQS 대기열 정책에서 `aws:SourceIp`, `aws:SourceVpce`를 잘못 썼을 때의 장애 패턴을 피하고, `BoolIfExists`(`aws:PrincipalIsAWSService`, `aws:ViaAWSService`) 예외와 최소 권한 SQS Interface VPC Endpoint 정책을 결합한 안전한 구성을 재현합니다.

## 포함 파일

- `main.tf` / `variables.tf` / `outputs.tf`: 테스트용 VPC(1 AZ, NAT/ALB 없음), SQS 큐, SNS 토픽, 앱 IAM Role, SQS Interface VPCE, 안전한 대기열 정책
- `policies/`: 글에서 다룬 잘못된 정책 예시(`bad-deny-sourceip-private.json`, `bad-deny-vpce-no-exception.json`)와 참조용 JSON

> 참고: `moto` 에뮬레이터는 정책 문법과 리소스 생성만 확인하며 실제 IAM 조건 평가는 수행하지 않습니다.

## 실행 방법 (Apply / Destroy)

### 1. 로컬 `moto` 에뮬레이터로 `plan` 검증

```bash
AWS_EC2_METADATA_DISABLED=true terraform init
AWS_EC2_METADATA_DISABLED=true terraform plan \
  -var="use_emulator=true" \
  -var="aws_endpoint_url=http://127.0.0.1:5000"
```

### 2. 실제 AWS 적용 및 삭제

```bash
terraform init
terraform plan
terraform apply

# 확인 후 즉시 삭제
terraform destroy
```

- 서울 리전(`ap-northeast-2`) 생성이 제한된 계정은 `-var="aws_region=ap-southeast-2"`를 추가하세요.
- VPC 엔드포인트 비용 없이 대기열/정책만 테스트하려면 `-var="create_vpc_endpoint=false"`로 실행하세요.

## 예상 비용

- `create_vpc_endpoint = true` (기본값): SQS Interface VPC Endpoint **시간당 약 $0.01** (1 AZ 기준, 데이터 처리 요금 별도). 10분 테스트 후 즉시 삭제 시 **$0.01 미만**.
- `create_vpc_endpoint = false`: VPC 엔드포인트 미생성 시 SQS/SNS/IAM 리소스 자체는 **유휴 요금 $0** (SQS/SNS는 Always Free 범위 내).
- NAT Gateway와 ALB는 생성하지 않습니다.

## 정리 체크리스트

- [ ] `terraform destroy` 실행 완료 및 오류 없음 확인
- [ ] 해당 리전의 VPC Endpoints 목록에서 `labbook-sqs-net-sqs-vpce` 삭제 확인
- [ ] SQS 대기열 및 SNS 토픽 삭제 확인
- [ ] IAM 역할(`labbook-sqs-net-app-role`) 삭제 확인
