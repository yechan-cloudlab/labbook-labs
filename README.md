# LabBook Labs

[LabBook](https://labbook.dev) 블로그의 AWS 글에서 다룬 구성과 실측 환경을 재현할 수 있는 최소 Terraform 코드 모음입니다.

> **비용 주의**: 이 저장소의 코드는 최소 스펙(`t4g.nano`, Lambda `128 MB`, NAT Gateway / ALB 미사용)을 기본으로 작성했지만, 일부 실습(VPC Interface Endpoint, Transit Gateway, Elastic IP 등)은 **리소스를 띄워 둔 시간당 과금**이 발생합니다. 실습이 끝나면 반드시 각 폴더의 `terraform destroy`와 정리 체크리스트를 끝까지 실행하세요.

## 디렉터리 목록

| 경로 | 주제 | 블로그 글 | 기본 리전 | 유료 리소스 포함 여부 |
| --- | --- | --- | --- | --- |
| [`aws/iam-network-condition-keys-sqs/`](./aws/iam-network-condition-keys-sqs/) | IAM 네트워크 조건 키(`SourceIp`, `VpcSourceIp`, `SourceVpc`, `SourceVpce`)와 SQS 대기열 정책 | [글 보기](https://labbook.dev/posts/iam-network-condition-keys-sqs/) | `ap-northeast-2` | 선택적 Interface VPCE (시간당 과금) |
| [`aws/sagemaker-presigned-url-ip-vpc/`](./aws/sagemaker-presigned-url-ip-vpc/) | SageMaker Studio `CreatePresignedDomainUrl` IAM 조건 및 `VpcOnly` 구성 | [글 보기](https://labbook.dev/posts/sagemaker-presigned-url-ip-vpc/) | `ap-northeast-2` | Interface VPCE (시간당 과금) |
| [`aws/transit-gateway-appliance-mode/`](./aws/transit-gateway-appliance-mode/) | Transit Gateway 검사 VPC 연결과 Appliance Mode 설정 | [글 보기](https://labbook.dev/posts/transit-gateway-appliance-mode/) | `ap-northeast-2` | TGW Attachment (시간당 과금) |
| [`aws/aws-free-plan-korea-seoul-region-scp/`](./aws/aws-free-plan-korea-seoul-region-scp/) | AWS Free 플랜 한국 계정의 리전 제한(SCP) 재현용 최소 리소스 프로브 | [글 보기](https://labbook.dev/posts/aws-free-plan-korea-seoul-region-scp/) | `ap-southeast-2` | Always Free 범위 내 (즉시 삭제 권장) |
| [`aws/ec2-stop-public-ipv4-eip-charge/`](./aws/ec2-stop-public-ipv4-eip-charge/) | EC2 중지 시 자동 할당 퍼블릭 IPv4 해제 vs EIP 유지 비교 (`t4g.nano`) | [글 보기](https://labbook.dev/posts/ec2-stop-public-ipv4-eip-charge/) | `ap-southeast-2` | `t4g.nano` + 퍼블릭 IPv4 / EIP (시간당 과금) |
| [`aws/lambda-cold-start-arm-snapstart-vpc/`](./aws/lambda-cold-start-arm-snapstart-vpc/) | Lambda `x86_64` vs `arm64`, VPC 연결, SnapStart 비교 (`128 MB`) | [글 보기](https://labbook.dev/posts/lambda-cold-start-arm-snapstart-vpc/) | `ap-southeast-2` | Always Free 범위 내 (SnapStart 스냅샷 보관료 주의) |

## 사용 전 공통 안내

### 1. 실제 AWS에서 실행할 때

각 폴더로 이동해 `init` → `plan` → `apply` 순서로 실행하고, 확인이 끝나면 즉시 `destroy` 하세요.

```bash
cd aws/<slug>
terraform init
terraform plan
terraform apply
# 확인 후 즉시 정리
terraform destroy
```

- 한국 가입 AWS Free 플랜 계정처럼 조직 SCP로 서울 리전(`ap-northeast-2`) 생성이 제한된 계정은 `-var="aws_region=ap-southeast-2"`처럼 허용된 리전을 지정하세요.
- 모든 리소스는 기본 `default_tags`(`Project = "labbook-labs"`, `ManagedBy = "terraform"`)를 포함합니다.

### 2. 로컬 에뮬레이터(`moto`)로 `plan`만 검증할 때

실제 AWS 비용 없이 문법과 실행 계획을 확인하려면 [moto](https://github.com/getmoto/moto) 서버(`http://127.0.0.1:5000`)를 띄운 뒤 `-var="use_emulator=true"`와 `-var="aws_endpoint_url=http://127.0.0.1:5000"`을 넘깁니다.

```bash
moto_server -p 5000 &
AWS_EC2_METADATA_DISABLED=true terraform plan \
  -var="use_emulator=true" \
  -var="aws_endpoint_url=http://127.0.0.1:5000"
```

> 에뮬레이터(`moto`)는 API 수용 여부와 리소스 스키마를 검증할 뿐, 실제 IAM 조건 평가, SCP 거부, 퍼블릭 IPv4 과금, Lambda 콜드스타트 지연 시간은 재현하지 못합니다.

## 라이선스

[MIT License](./LICENSE)
