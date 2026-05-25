# HAProxy PostgreSQL Logrotate Docker

HAProxy 공식 Docker 이미지를 기반으로 만든 PostgreSQL write/read 라우팅용 HAProxy 이미지입니다.

구성 목표는 다음과 같습니다.

- HAProxy `3.3.10` 기반
- PostgreSQL master/replica 앞단 TCP 라우팅
- `:5432` write -> master DB
- `:5433` read -> replica DB
- `:8404` HAProxy stats
- 매일 00:00 로그 압축
- 365일이 지난 압축 로그 삭제

## 아키텍처

`../postgresql-logrotate` 프로젝트의 권장 구조에 바로 붙일 수 있는 구성을 기본값으로 둡니다.

```text
app server
  └─ haproxy-logrotate
      ├─ :5432 write -> postgres-master:5432
      └─ :5433 read  -> postgres-replica:5432

master server
  └─ postgres-master

replica server
  └─ postgres-replica
```

운영에서는 `POSTGRES_MASTER_HOST`, `POSTGRES_REPLICA_HOST`를 실제 DB 서버 IP 또는 DNS로 바꾸세요.

## 이미지

- 베이스 이미지: `haproxy:3.3.10`
- 로컬 빌드 이미지: `haproxy-logrotate:3.3.10`
- Docker Hub 태그: HAProxy 버전 태그 기준, 예: `3.3.10`

`latest` 태그는 사용하지 않습니다.

## HAProxy 구성

컨테이너 시작 시 환경 변수를 읽어 `/usr/local/etc/haproxy/haproxy.cfg`를 생성합니다.

| 변수 | 설명 | 기본값 |
| --- | --- | --- |
| `HAPROXY_VERSION` | 사용할 HAProxy 버전 | `3.3.10` |
| `IMAGE_NAME` | 로컬 이미지 이름 | `haproxy-logrotate` |
| `TZ` | 컨테이너 시간대 | `Asia/Seoul` |
| `HAPROXY_MAXCONN` | HAProxy 최대 연결 수 | `4096` |
| `HAPROXY_WRITE_PORT` | write endpoint 포트 | `5432` |
| `HAPROXY_READ_PORT` | read endpoint 포트 | `5433` |
| `HAPROXY_STATS_PORT` | stats/metrics 포트 | `8404` |
| `POSTGRES_MASTER_HOST` | master DB 주소 | `postgres-master` |
| `POSTGRES_MASTER_PORT` | master DB 포트 | `5432` |
| `POSTGRES_REPLICA_HOST` | replica DB 주소 | `postgres-replica` |
| `POSTGRES_REPLICA_PORT` | replica DB 포트 | `5432` |

## 로컬 실행

```bash
cp .env.example .env
docker compose build
docker compose up -d
```

`../postgresql-logrotate`의 master/replica와 함께 테스트하려면 같은 Docker network에서 실행되도록 붙이거나, `.env`의 DB host 값을 접근 가능한 주소로 바꾸세요.

예시:

```env
POSTGRES_MASTER_HOST=10.0.0.10
POSTGRES_MASTER_PORT=5432
POSTGRES_REPLICA_HOST=10.0.0.20
POSTGRES_REPLICA_PORT=5432
```

애플리케이션에서는 쓰기/읽기 커넥션을 분리합니다.

```text
DATABASE_WRITE_URL=postgresql://postgres:<password>@app-server:5432/app
DATABASE_READ_URL=postgresql://devgyurak:<password>@app-server:5433/app
```

## 로그 관리

HAProxy 로그는 rsyslog를 통해 `/var/log/haproxy/haproxy.log`에 저장됩니다.

- 실행 시각: 매일 00:00, 컨테이너 로컬 시간 기준
- 압축: gzip
- 보관: 최대 365개, 365일 초과 파일 삭제
- 예시 파일명: `haproxy.log-20260525.gz`

수동 테스트:

```bash
docker compose exec haproxy logrotate -f -s /var/lib/logrotate/status /etc/logrotate.d/haproxy
docker compose exec haproxy ls -l /var/log/haproxy
```

## 상태 확인

```bash
docker compose ps
docker compose exec haproxy haproxy -c -f /usr/local/etc/haproxy/haproxy.cfg
curl http://localhost:8404/
```

## Docker Hub 배포

`.github/workflows/dockerhub.yml`은 `main` 브랜치에 push될 때 Docker Hub로 이미지를 빌드 및 push합니다.

필요한 GitHub Actions secrets:

- `DOCKERHUB_USERNAME`
- `DOCKERHUB_TOKEN`

푸시 대상:

```text
${DOCKERHUB_USERNAME}/haproxy-logrotate:3.3.10
${DOCKERHUB_USERNAME}/haproxy-logrotate:sha-<commit>
```
