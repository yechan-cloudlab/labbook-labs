# LabBook Labs

[LabBook](https://labbook.dev) 블로그의 AWS 글 가운데, 독자가 인프라를 직접 만들어 측정이나 실험을 재현해야 하는 글만 Terraform 코드로 모아 둔 저장소입니다. 개념 설명, 콘솔 설정, 짧은 AWS CLI 호출만으로 따라 할 수 있는 글의 코드는 넣지 않습니다.

> **비용 주의**: 코드는 최소 스펙(`t4g.nano`, Lambda `128 MB`, NAT Gateway / ALB 미사용)을 기본으로 작성했지만, EC2와 퍼블릭 IPv4·EIP는 **띄워 둔 시간당 과금**이 발생합니다. 실습이 끝나면 반드시 각 폴더의 `terraform destroy`와 정리 체크리스트를 끝까지 실행하세요. 기본 리전은 시드니(`ap-southeast-2`)입니다.

## 디렉터리 목록

| 경로 | 주제 | 블로그 글 | 기본 리전 | 유료 리소스 포함 여부 |
| --- | --- | --- | --- | --- |
| [`aws/ec2-stop-public-ipv4-eip-charge/`](./aws/ec2-stop-public-ipv4-eip-charge/) | EC2 중지 시 자동 할당 퍼블릭 IPv4 해제 vs EIP 유지 비교 (`t4g.nano`) | [글 보기](https://labbook.dev/posts/ec2-stop-public-ipv4-eip-charge/) | `ap-southeast-2` | `t4g.nano` + 퍼블릭 IPv4 / EIP (시간당 과금) |
| [`aws/lambda-cold-start-arm-snapstart-vpc/`](./aws/lambda-cold-start-arm-snapstart-vpc/) | Lambda `x86_64` vs `arm64`, VPC 연결, SnapStart 비교 (`128 MB`) | [글 보기](https://labbook.dev/posts/lambda-cold-start-arm-snapstart-vpc/) | `ap-southeast-2` | Always Free 범위 내 (SnapStart 스냅샷 보관료 주의) |

두 글 모두 아직 초안(`draft: true`)이므로, 발행 전까지는 로컬 미리보기로 본문을 확인하면 됩니다.

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

- 이 저장소의 기본 리전은 `ap-southeast-2`(시드니)입니다. 한국 가입 AWS Free 플랜 계정처럼 조직 SCP로 서울 리전(`ap-northeast-2`) 생성이 제한된 계정에서도 그대로 사용하면 됩니다.
- 모든 리소스는 기본 `default_tags`(`Project = "labbook-labs"`, `ManagedBy = "terraform"`)를 포함합니다.

### 2. 로컬 에뮬레이터(`moto`)로 `plan`만 검증할 때

실제 AWS 비용 없이 문법과 실행 계획을 확인하려면 [moto](https://github.com/getmoto/moto) 서버(`http://127.0.0.1:5000`)를 띄운 뒤 `-var="use_emulator=true"`와 `-var="aws_endpoint_url=http://127.0.0.1:5000"`을 넘깁니다.

```bash
moto_server -p 5000 &
AWS_EC2_METADATA_DISABLED=true terraform plan \
  -var="use_emulator=true" \
  -var="aws_endpoint_url=http://127.0.0.1:5000"
```

> 에뮬레이터(`moto`)는 API 수용 여부와 리소스 스키마를 검증할 뿐, 실제 퍼블릭 IPv4 과금이나 Lambda 콜드스타트 지연 시간은 재현하지 못합니다.

## 라이선스

[MIT License](./LICENSE)
