# AWS Free 플랜 한국 계정 리전 제한(SCP) 재현 실습

- **블로그 글**: [AWS Free 플랜 한국 계정으로 서울 리전에 만들 수 있을까: SCP 거부 실측](https://labbook.dev/posts/aws-free-plan-korea-seoul-region-scp/) (초안 / 발행 예정)
- **목적**: 허용된 리전(`ap-southeast-2`)에서는 보안 그룹·S3 버킷·SQS 큐·DynamoDB 테이블·최소 스펙 Lambda(128 MB)가 정상 생성되는 반면, 조직 SCP로 제한된 계정에서 `-var="aws_region=ap-northeast-2"`(서울)를 주면 생성 API가 명시적 거부(`AccessDenied` / `UnauthorizedOperation`)로 실패하는 동작을 재현합니다.

## 포함 파일

- `main.tf` / `variables.tf` / `outputs.tf`: 기본 리전 `ap-southeast-2`, 보안 그룹(인바운드 없음), 빈 S3 버킷, SQS 큐, DynamoDB 온디맨드 테이블, Python 3.12 Lambda(`128 MB`), CloudWatch 로그 그룹(`retention_in_days = 1`)
- `src/python/index.py`, `dist/python-handler.zip`: 최소 핸들러(`{"ok": true}`)

> 참고: `moto` 에뮬레이터에는 조직 SCP가 없으므로 `ap-northeast-2`로 실행해도 차단되지 않습니다. SCP 거부는 실제 AWS 계정에서만 확인할 수 있습니다.

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
# 허용 리전(ap-southeast-2)에서 생성 확인
terraform init
terraform plan
terraform apply

# 확인 후 즉시 삭제
terraform destroy
```

서울 리전 거부를 재현하려면 아래처럼 리전을 바꿔 `apply`를 시도합니다(실패한 리소스 외에 IAM Role 등이 부분 생성될 수 있으므로 테스트 후 `terraform destroy -var="aws_region=ap-northeast-2"`로 정리하세요).

```bash
terraform apply -var="aws_region=ap-northeast-2"
terraform destroy -var="aws_region=ap-northeast-2"
```

## 예상 비용

- 모든 리소스가 Always Free 또는 빈 상태 무과금 리소스입니다(Lambda `128 MB`, DynamoDB 빈 `PAY_PER_REQUEST`, 빈 S3 버킷, SQS 큐, 보안 그룹).
- NAT Gateway, ALB, EC2 인스턴스를 만들지 않습니다. 확인 직후 `terraform destroy` 시 **$0**.

## 정리 체크리스트

- [ ] `terraform destroy` 실행 완료 (서울 리전 테스트 시 동일 `-var="aws_region=ap-northeast-2"`로 정리)
- [ ] `ap-southeast-2`에서 Lambda 함수, CloudWatch 로그 그룹, DynamoDB 테이블, SQS 큐, S3 버킷, 보안 그룹 삭제 확인
- [ ] IAM 역할(`labbook-region-probe-lambda-role`) 삭제 확인
