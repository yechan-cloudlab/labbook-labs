# SageMaker Studio presigned URL 접속 제한 실습

- **블로그 글**: [SageMaker Studio presigned URL 접속 제한: VPC 엔드포인트만 만들면 막히지 않는다](https://labbook.dev/posts/sagemaker-presigned-url-ip-vpc/)
- **목적**: `AuthMode=IAM`, `AppNetworkAccessType=VpcOnly` 도메인과 SageMaker API / Studio 인터페이스 VPC 엔드포인트를 구성하고, `CreatePresignedDomainUrl`에 적용하는 IAM 조건 정책(`aws:SourceIp`, `aws:SourceVpce`, `aws:VpcSourceIp` + `aws:SourceVpc`, `Deny` 패턴)을 재현합니다.

## 포함 파일

- `main.tf` / `variables.tf` / `outputs.tf`: 프라이빗 서브넷 2개(NAT/ALB 없음), Studio 보안 그룹(`8192-65535`, `2049`), SageMaker 도메인(`IAM` / `VpcOnly`), API·Studio 인터페이스 엔드포인트, 독립 IAM 정책 4종
- `policies/`: 글에서 비교한 허용·차단·함정 정책(`bad-and-ip-and-vpce.json` 등) 원본 JSON

> 참고: `moto` 에뮬레이터는 도메인·VPCE·IAM 정책 생성까지 확인 가능하며 `CreatePresignedDomainUrl` 호출과 브라우저 세션 조건 평가는 재현하지 못합니다.

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
- VPC 엔드포인트 없이 IAM 정책 문법만 보려면 `-var="create_vpc_endpoints=false" -var="create_sagemaker_domain=false"`로 실행하세요.

## 예상 비용

- Interface VPC Endpoint 2개(`sagemaker.api`, `studio`, 각 1 AZ): **시간당 약 $0.02** ($0.01 × 2) + 데이터 처리 요금.
- SageMaker Domain 자체는 앱(JupyterLab/KernelGateway)을 띄우지 않으면 시간당 인스턴스 과금이 없으며, 자동 생성되는 EFS도 비어 있으면 소액(GB-month 기준 $0.30/GB)입니다.
- NAT Gateway와 ALB는 생성하지 않습니다. 테스트 후 즉시 `terraform destroy` 시 **$0.05 미만**.

## 정리 체크리스트

- [ ] 실행 중인 SageMaker App이 있다면 먼저 삭제 후 `terraform destroy` 실행
- [ ] SageMaker Domains 콘솔에서 `labbook-sm-vpconly-domain` 및 연결된 EFS 볼륨 삭제 확인
- [ ] VPC Endpoints 콘솔에서 API·Studio VPCE 2개 삭제 확인
- [ ] IAM Policies / Role(`labbook-sm-vpconly-*`) 삭제 확인
