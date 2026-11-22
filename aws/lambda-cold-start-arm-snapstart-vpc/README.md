# Lambda 콜드스타트 비교 실습 (`arm64` · SnapStart · VPC)

- **블로그 글**: [Lambda 콜드스타트 실측: arm64·SnapStart·VPC는 얼마나 바꿀까](https://labbook.dev/posts/lambda-cold-start-arm-snapstart-vpc/) (초안 / 발행 예정)
- **목적**: 최소 핸들러(`{"ok": true}`)를 기준으로 Python 3.12(`x86_64`, `arm64`, VPC 연결, SnapStart)와 Java 21(일반, SnapStart) 6개 구성을 배포해 Init/Restore Duration 및 청구 시간을 비교합니다.

> **메모리 기본값 안내**: 비용 정책(`COST-POLICY`)에 따라 이 Terraform 코드는 **`lambda_memory_size = 128` MB**를 기본값으로 둡니다. 블로그 글의 6개 구성 비교 표와 동일한 조건(`512 MB`)으로 재현하려면 `-var="lambda_memory_size=512"`를 넘겨 실행하세요.

## 포함 파일

- `main.tf` / `variables.tf` / `outputs.tf`: 최대 6개 Lambda 함수, IAM 실행 역할, CloudWatch 로그 그룹(`retention_in_days = 1`), 기본 VPC 서브넷 + 최소 SG (NAT Gateway / ALB / VPC Endpoint 없음)
- `src/python/index.py`, `src/java/src/example/Handler.java`: 최소 핸들러 소스
- `build-python-zip.sh`, `build-java-zip.sh`, `dist/*.zip`: 빌드 스크립트 및 사전 빌드된 최소 배포 패키지

> 참고: `moto` 에뮬레이터는 리소스 스키마와 실행 계획만 검증하며, 실제 Lambda Init/Restore Duration이나 SnapStart 스냅샷 최적화는 AWS 환경에서만 측정됩니다.

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

# (선택) 블로그 표와 동일한 512 MB로 테스트할 때:
# terraform apply -var="lambda_memory_size=512"
```

테스트 호출 예시(SnapStart 함수는 반드시 발행된 버전 qualifier 지정):

```bash
aws lambda invoke --region ap-southeast-2 \
  --function-name labbook-coldstart-py312-arm-novpc \
  --log-type Tail --cli-binary-format raw-in-base64-out \
  --payload '{"ping":true}' /tmp/out.json
```

측정이 끝나면 즉시 삭제합니다(VPC Lambda ENI가 분리될 때까지 `terraform destroy`가 수십 초 대기할 수 있습니다).

```bash
terraform destroy
```

## 예상 비용

- **Always Free 범위 내**: Lambda 월 100만 요청 · 400,000 GB-초, CloudWatch Logs 월 5 GB 수집이 무료 범위에 포함됩니다.
- **주의할 점**:
  - SnapStart를 켠 함수를 방치하면 스냅샷 스토리지/캐시 비용이 소액 발생할 수 있으므로 테스트 직후 `terraform destroy`를 실행하세요.
  - VPC 연결 Lambda는 기본 VPC 서브넷과 보안 그룹만 사용하며 NAT Gateway와 ALB를 만들지 않습니다.

## 정리 체크리스트

- [ ] `terraform destroy` 완료 확인 (VPC ENI 분리 지연 시 몇 분 뒤 재시도)
- [ ] Lambda 콘솔에서 `labbook-coldstart-*` 함수 6개 모두 삭제 확인
- [ ] CloudWatch Logs에서 `/aws/lambda/labbook-coldstart-*` 로그 그룹 삭제 확인
- [ ] `labbook-coldstart-vpc-sg` 보안 그룹 및 `labbook-coldstart-role` IAM 역할 삭제 확인
