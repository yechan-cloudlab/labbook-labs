# Transit Gateway 어플라이언스 모드 실습

- **블로그 글**: [Transit Gateway 어플라이언스 모드: 검사 VPC에서 응답이 버려지는 이유](https://labbook.dev/posts/transit-gateway-appliance-mode/)
- **목적**: 다중 AZ 검사 VPC와 Transit Gateway(TGW) VPC 연결(attachment)에서 `appliance_mode_support = "enable"` 설정이 어떻게 구성되는지 재현합니다.

## 포함 파일

- `main.tf` / `variables.tf` / `outputs.tf`: 2개 AZ 서브넷을 가진 검사 VPC, Transit Gateway, `appliance_mode_support = "enable"` VPC 연결

> 참고: `moto` 에뮬레이터는 TGW와 VPC 연결 생성, `ApplianceModeSupport` 옵션 확인까지 지원하며, 실제 패킷 경로(비대칭 라우팅·흐름 해시)와 `modifying` / `rolling back` 상태 전이는 재현하지 못합니다.

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

- 한국 가입 Free 플랜 계정 등 서울 리전(`ap-northeast-2`) 생성이 제한된 환경에서는 `-var="aws_region=ap-southeast-2"`를 넘기세요. (참고: 일부 Free 플랜 비용 정책에서는 TGW 자체 생성을 지양합니다.)

## 예상 비용

- **Transit Gateway VPC Attachment**: **시간당 $0.05** (트래픽이 0이어도 연결이 유지되는 시간마다 과금, 월 ~$36.5).
- 확인이 끝나면 방치하지 말고 즉시 `terraform destroy`를 실행하세요. 10분 테스트 후 삭제 시 약 **$0.05** (1시간 단위 절상).
- NAT Gateway와 ALB는 생성하지 않습니다.

## 정리 체크리스트

- [ ] `terraform destroy` 실행 완료 및 오류 없음 확인
- [ ] Transit Gateway Attachments 콘솔에서 연결 상태가 `deleted`인지 확인
- [ ] Transit Gateways 콘솔에서 `labbook-tgw-appliance-tgw` 삭제 확인
- [ ] 검사 VPC(`labbook-tgw-appliance-inspection`) 삭제 확인
