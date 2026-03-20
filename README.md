# Hanko Helm Chart

[![License](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

A Helm chart for deploying [Hanko](https://www.hanko.io) - an open-source authentication and user management service - on Kubernetes.

## What is Hanko?

Hanko is an open-source authentication and user management service that provides:

- 🔐 **Passkeys** - Passwordless authentication with WebAuthn
- 📧 **Email OTP** - One-time passcodes via email
- 🔑 **Password Authentication** - Traditional password-based login
- 📱 **MFA** - Multi-factor authentication with TOTP
- 🎨 **Customizable UI** - White-label authentication components
- 🔗 **SSO Integration** - OAuth/OIDC third-party providers

Learn more at [hanko.io](https://www.hanko.io) or on [GitHub](https://github.com/teamhanko/hanko).

## Prerequisites

- Kubernetes 1.19+
- Helm 3.10+
- PostgreSQL 12+ (can be installed as a dependency)

## Installation

### Add the Helm Repository

```bash
helm repo add hanko https://your-repo-url/hanko
helm repo update
```

### Quick Start

For a quick test deployment with an included PostgreSQL database:

```bash
helm install hanko hanko/hanko \
  --namespace hanko \
  --create-namespace \
  --set postgresql.enabled=true \
  --set postgresql.auth.password=hanko-password \
  --set config.session.secret=$(openssl rand -base64 32) \
  --set config.secrets.keys[0]=$(openssl rand -base64 32)
```

### Production Installation

1. Create a values file for your production configuration:

```yaml
# values-production.yaml
replicaCount: 3

image:
  tag: "v1.0.0"

config:
  server:
    public:
      cors:
        allowOrigins:
          - "https://your-app.com"
  webauthn:
    relyingParty:
      id: "your-app.com"
      name: "Your App"
      origins:
        - "https://your-app.com"
  session:
    cookie:
      secure: true
      domain: "your-app.com"
  database:
    host: your-postgres-host
    passwordSecret: hanko-db-password
  secrets:
    secretsSecretName: hanko-secrets

ingress:
  enabled: true
  className: nginx
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
  hosts:
    public:
      - host: auth.your-app.com
        paths:
          - path: /
            pathType: Prefix
  tls:
    - secretName: hanko-tls
      hosts:
        - auth.your-app.com

resources:
  limits:
    cpu: 500m
    memory: 512Mi
  requests:
    cpu: 100m
    memory: 128Mi

autoscaling:
  enabled: true
  minReplicas: 3
  maxReplicas: 10
  targetCPUUtilizationPercentage: 80
```

2. Deploy:

```bash
helm install hanko hanko/hanko \
  --namespace hanko \
  --create-namespace \
  -f values-production.yaml
```

## Configuration

The following table lists the configurable parameters of the Hanko chart and their default values.

### General Parameters

| Parameter          | Description           | Default                   |
|--------------------|-----------------------|---------------------------|
| `replicaCount`     | Number of replicas    | `1`                       |
| `image.repository` | Image repository      | `ghcr.io/teamhanko/hanko` |
| `image.pullPolicy` | Image pull policy     | `IfNotPresent`            |
| `image.tag`        | Image tag             | `""` (uses appVersion)    |
| `imagePullSecrets` | Registry pull secrets | `[]`                      |
| `nameOverride`     | Override chart name   | `""`                      |
| `fullnameOverride` | Override full name    | `""`                      |

### Service Account

| Parameter                    | Description                 | Default        |
|------------------------------|-----------------------------|----------------|
| `serviceAccount.create`      | Create service account      | `true`         |
| `serviceAccount.annotations` | Service account annotations | `{}`           |
| `serviceAccount.name`        | Service account name        | Auto-generated |

### Hanko Configuration

#### Service

| Parameter             | Description  | Default                          |
|-----------------------|--------------|----------------------------------|
| `config.service.name` | Service name | `"Hanko Authentication Service"` |

#### Server

| Parameter                                | Description             | Default     |
|------------------------------------------|-------------------------|-------------|
| `config.server.public.address`           | Public API bind address | `"0.0.0.0"` |
| `config.server.public.port`              | Public API port         | `8000`      |
| `config.server.public.cors.allowOrigins` | CORS allowed origins    | `[]`        |
| `config.server.admin.address`            | Admin API bind address  | `"0.0.0.0"` |
| `config.server.admin.port`               | Admin API port          | `8001`      |

#### Database

| Parameter                        | Description          | Default    |
|----------------------------------|----------------------|------------|
| `config.database.dialect`        | Database type        | `postgres` |
| `config.database.host`           | Database host        | `""`       |
| `config.database.port`           | Database port        | `5432`     |
| `config.database.database`       | Database name        | `hanko`    |
| `config.database.user`           | Database user        | `hanko`    |
| `config.database.password`       | Database password    | `""`       |
| `config.database.passwordSecret` | Secret with password | `""`       |
| `config.database.sslMode`        | SSL mode             | `disable`  |
| `config.database.maxOpenConns`   | Max open connections | `25`       |
| `config.database.maxIdleConns`   | Max idle connections | `5`        |

#### Session

| Parameter                         | Description            | Default |
|-----------------------------------|------------------------|---------|
| `config.session.secret`           | JWT secret             | `""`    |
| `config.session.secretSecretName` | Secret with JWT secret | `""`    |
| `config.session.cookie.name`      | Cookie name            | `hanko` |
| `config.session.cookie.domain`    | Cookie domain          | `""`    |
| `config.session.cookie.path`      | Cookie path            | `/`     |
| `config.session.cookie.secure`    | Secure cookie flag     | `false` |
| `config.session.cookie.httpOnly`  | HttpOnly flag          | `true`  |
| `config.session.cookie.sameSite`  | SameSite policy        | `lax`   |
| `config.session.lifespan`         | Session lifespan       | `1h`    |

#### Secrets

| Parameter                          | Description             | Default               |
|------------------------------------|-------------------------|-----------------------|
| `config.secrets.keys`              | Secret keys for signing | `[]` (auto-generated) |
| `config.secrets.secretsSecretName` | Secret with keys        | `""`                  |

#### WebAuthn/Passkeys

| Parameter                              | Description        | Default        |
|----------------------------------------|--------------------|----------------|
| `config.webauthn.relyingParty.id`      | Relying party ID   | Auto-generated |
| `config.webauthn.relyingParty.name`    | Relying party name | `Hanko`        |
| `config.webauthn.relyingParty.origins` | Allowed origins    | `[]`           |
| `config.webauthn.userVerification`     | User verification  | `preferred`    |

#### Email Delivery

| Parameter                                  | Description           | Default |
|--------------------------------------------|-----------------------|---------|
| `config.emailDelivery.enabled`             | Enable email delivery | `false` |
| `config.emailDelivery.smtp.host`           | SMTP host             | `""`    |
| `config.emailDelivery.smtp.port`           | SMTP port             | `587`   |
| `config.emailDelivery.smtp.user`           | SMTP user             | `""`    |
| `config.emailDelivery.smtp.password`       | SMTP password         | `""`    |
| `config.emailDelivery.smtp.passwordSecret` | Secret with password  | `""`    |
| `config.emailDelivery.smtp.tls`            | Enable TLS            | `true`  |
| `config.emailDelivery.fromAddress`         | From address          | `""`    |

#### Password Authentication

| Parameter                          | Description           | Default |
|------------------------------------|-----------------------|---------|
| `config.password.enabled`          | Enable passwords      | `true`  |
| `config.password.minLength`        | Minimum length        | `8`     |
| `config.password.requireUppercase` | Require uppercase     | `false` |
| `config.password.requireLowercase` | Require lowercase     | `false` |
| `config.password.requireNumber`    | Require numbers       | `false` |
| `config.password.requireSpecial`   | Require special chars | `false` |

#### MFA

| Parameter                          | Description             | Default |
|------------------------------------|-------------------------|---------|
| `config.mfa.enabled`               | Enable MFA              | `true`  |
| `config.mfa.optional`              | MFA optional            | `true`  |
| `config.mfa.acquireOnLogin`        | Acquire on login        | `false` |
| `config.mfa.acquireOnRegistration` | Acquire on registration | `true`  |
| `config.mfa.totp.enabled`          | Enable TOTP             | `true`  |
| `config.mfa.securityKeys.enabled`  | Enable security keys    | `false` |

#### Rate Limiter

| Parameter                           | Description          | Default  |
|-------------------------------------|----------------------|----------|
| `config.rateLimiter.enabled`        | Enable rate limiting | `true`   |
| `config.rateLimiter.storage`        | Storage type         | `memory` |
| `config.rateLimiter.redis.host`     | Redis host           | `""`     |
| `config.rateLimiter.redis.port`     | Redis port           | `6379`   |
| `config.rateLimiter.redis.password` | Redis password       | `""`     |
| `config.rateLimiter.redis.database` | Redis database       | `0`      |

#### Logging

| Parameter           | Description | Default |
|---------------------|-------------|---------|
| `config.log.level`  | Log level   | `info`  |
| `config.log.format` | Log format  | `json`  |

#### Audit Log

| Parameter                 | Description          | Default    |
|---------------------------|----------------------|------------|
| `config.auditLog.enabled` | Enable audit logging | `false`    |
| `config.auditLog.output`  | Output type          | `database` |

### PostgreSQL Subchart

| Parameter                        | Description       | Default        |
|----------------------------------|-------------------|----------------|
| `postgresql.enabled`             | Enable PostgreSQL | `false`        |
| `postgresql.auth.database`       | Database name     | `hanko`        |
| `postgresql.auth.username`       | Database user     | `hanko`        |
| `postgresql.auth.password`       | Database password | Auto-generated |
| `postgresql.auth.existingSecret` | Existing secret   | `""`           |

### Service

| Parameter                   | Description         | Default     |
|-----------------------------|---------------------|-------------|
| `service.type`              | Service type        | `ClusterIP` |
| `service.ports.public.port` | Public API port     | `8000`      |
| `service.ports.admin.port`  | Admin API port      | `8001`      |
| `service.annotations`       | Service annotations | `{}`        |

### Ingress

| Parameter              | Description         | Default                       |
|------------------------|---------------------|-------------------------------|
| `ingress.enabled`      | Enable ingress      | `false`                       |
| `ingress.className`    | Ingress class       | `""`                          |
| `ingress.annotations`  | Ingress annotations | `{}`                          |
| `ingress.hosts.public` | Public API hosts    | `[{host: hanko.local}]`       |
| `ingress.hosts.admin`  | Admin API hosts     | `[{host: hanko-admin.local}]` |
| `ingress.tls`          | TLS configuration   | `[]`                          |

### Resources

| Parameter   | Description              | Default |
|-------------|--------------------------|---------|
| `resources` | Resource limits/requests | `{}`    |

### Autoscaling

| Parameter                                       | Description        | Default |
|-------------------------------------------------|--------------------|---------|
| `autoscaling.enabled`                           | Enable autoscaling | `false` |
| `autoscaling.minReplicas`                       | Minimum replicas   | `1`     |
| `autoscaling.maxReplicas`                       | Maximum replicas   | `10`    |
| `autoscaling.targetCPUUtilizationPercentage`    | Target CPU %       | `80`    |
| `autoscaling.targetMemoryUtilizationPercentage` | Target memory %    | `80`    |

### Pod Disruption Budget

| Parameter                            | Description        | Default |
|--------------------------------------|--------------------|---------|
| `podDisruptionBudget.enabled`        | Enable PDB         | `false` |
| `podDisruptionBudget.minAvailable`   | Min available pods | `1`     |
| `podDisruptionBudget.maxUnavailable` | Max unavailable    | `null`  |

### Migration Job

| Parameter                           | Description          | Default |
|-------------------------------------|----------------------|---------|
| `migration.enabled`                 | Enable migration job | `true`  |
| `migration.annotations`             | Job annotations      | `{}`    |
| `migration.ttlSecondsAfterFinished` | Job TTL              | `600`   |
| `migration.backoffLimit`            | Backoff limit        | `5`     |
| `migration.resources`               | Migration resources  | `{}`    |

## Examples

### Example 1: Basic Development Setup

```yaml
# values-dev.yaml
postgresql:
  enabled: true
  auth:
    password: devpassword

config:
  session:
    secret: "dev-secret-change-in-production"
    cookie:
      secure: false
  secrets:
    keys:
      - "dev-key-change-in-production"
  server:
    public:
      cors:
        allowOrigins:
          - "http://localhost:3000"
  webauthn:
    relyingParty:
      origins:
        - "http://localhost:3000"
```

### Example 2: Production with External Database

```yaml
# values-prod.yaml
replicaCount: 3

config:
  database:
    host: postgres.prod.svc.cluster.local
    passwordSecret: hanko-db-credentials
  session:
    secretSecretName: hanko-session-secret
    cookie:
      secure: true
      domain: "example.com"
  secrets:
    secretsSecretName: hanko-signing-keys
  server:
    public:
      cors:
        allowOrigins:
          - "https://app.example.com"
  webauthn:
    relyingParty:
      id: "auth.example.com"
      name: "Example App"
      origins:
        - "https://app.example.com"


ingress:
  enabled: true
  className: nginx
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
  hosts:
    public:
      - host: auth.example.com
        paths:
          - path: /
            pathType: Prefix
  tls:
    - secretName: hanko-tls
      hosts:
        - auth.example.com

resources:
  limits:
    cpu: 1000m
    memory: 1Gi
  requests:
    cpu: 200m
    memory: 256Mi

autoscaling:
  enabled: true
  minReplicas: 3
  maxReplicas: 10
```

### Example 3: Using External Secrets

```yaml
# values-external-secrets.yaml
config:
  database:
    passwordSecret: external-hanko-db
  session:
    secretSecretName: external-hanko-session
  secrets:
    secretsSecretName: external-hanko-keys
  emailDelivery:
    enabled: true
    smtp:
      host: smtp.example.com
      port: 587
      user: noreply@example.com
      passwordSecret: external-hanko-smtp
    fromAddress: noreply@example.com
```

## Upgrading

### To Version 0.2.0

TBD

## Troubleshooting

### Database Connection Issues

If Hanko can't connect to the database:

```bash
# Check database connectivity
kubectl exec -it deployment/hanko -- nc -zv <db-host> 5432

# Check logs
kubectl logs deployment/hanko
```

### Migration Failures

If the migration job fails:

```bash
# Check job status
kubectl get jobs
kubectl describe job hanko-migrate

# View job logs
kubectl logs job/hanko-migrate

# Re-run migration
kubectl create job --from=job/hanko-migrate hanko-migrate-retry
```

### CORS Issues

If you're getting CORS errors:

1. Ensure `config.server.public.cors.allowOrigins` includes your frontend URL
2. Check that the origin exactly matches (including protocol and port)

## Security Considerations

- **Always use external secrets** for sensitive values in production (passwords, JWT secrets, signing keys)
- **Enable TLS** for session cookies when using HTTPS
- **Set strong password policies** if enabling password authentication
- **Enable MFA** for enhanced security
- **Use network policies** to restrict pod-to-pod communication
- **Enable audit logging** for compliance requirements

## Uninstalling

```bash
helm uninstall hanko --namespace hanko
```

To remove all resources including PVCs:

```bash
kubectl delete pvc -l app.kubernetes.io/instance=hanko --namespace hanko
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This Helm chart is licensed under the MIT License.

## Resources

- [Hanko Documentation](https://www.hanko.io/docs)
- [Hanko GitHub](https://github.com/teamhanko/hanko)
- [Hanko Elements](https://github.com/teamhanko/hanko/tree/main/frontend/elements)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Helm Documentation](https://helm.sh/docs/)
