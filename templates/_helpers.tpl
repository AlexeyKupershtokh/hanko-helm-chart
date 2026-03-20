{{/*
Expand the name of the chart.
*/}}
{{- define "hanko.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "hanko.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "hanko.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "hanko.labels" -}}
helm.sh/chart: {{ include "hanko.chart" . }}
{{ include "hanko.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "hanko.selectorLabels" -}}
app.kubernetes.io/name: {{ include "hanko.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "hanko.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "hanko.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Hanko configuration
*/}}
{{- define "hanko.config" -}}
service:
  name: {{ .Values.config.service.name | quote }}

server:
  public:
    address: {{ .Values.config.server.public.address | quote }}
    port: {{ .Values.config.server.public.port }}
    {{- if .Values.config.server.public.cors.allowOrigins }}
    cors:
      allow_origins:
        {{- toYaml .Values.config.server.public.cors.allowOrigins | nindent 8 }}
    {{- end }}
  admin:
    address: {{ .Values.config.server.admin.address | quote }}
    port: {{ .Values.config.server.admin.port }}

database:
  dialect: {{ .Values.config.database.dialect | quote }}
  {{- if .Values.postgresql.enabled }}
  host: {{ .Release.Name }}-postgresql
  {{- else if .Values.config.database.host }}
  host: {{ .Values.config.database.host | quote }}
  {{- else }}
  host: {{ include "hanko.fullname" . }}-postgresql
  {{- end }}
  port: {{ .Values.config.database.port }}
  database: {{ .Values.config.database.database | quote }}
  user: {{ .Values.config.database.user | quote }}
  {{- if .Values.config.database.passwordSecret }}
  password: ${DATABASE_PASSWORD}
  {{- else if .Values.config.database.password }}
  password: {{ .Values.config.database.password | quote }}
  {{- else if .Values.postgresql.enabled }}
  password: ${DATABASE_PASSWORD}
  {{- end }}
  {{- if or .Values.config.database.sslMode .Values.postgresql.enabled }}
  sslmode: {{ .Values.config.database.sslMode | default "disable" | quote }}
  {{- end }}
  max_open_conns: {{ .Values.config.database.maxOpenConns }}
  max_idle_conns: {{ .Values.config.database.maxIdleConns }}

session:
  {{- if .Values.config.session.secretSecretName }}
  jwt_secret: ${SESSION_SECRET}
  {{- else if .Values.config.session.secret }}
  jwt_secret: {{ .Values.config.session.secret | quote }}
  {{- else }}
  jwt_secret: ${SESSION_SECRET}
  {{- end }}
  cookie:
    name: {{ .Values.config.session.cookie.name | quote }}
    {{- if .Values.config.session.cookie.domain }}
    domain: {{ .Values.config.session.cookie.domain | quote }}
    {{- end }}
    path: {{ .Values.config.session.cookie.path | quote }}
    secure: {{ .Values.config.session.cookie.secure }}
    http_only: {{ .Values.config.session.cookie.httpOnly }}
    same_site: {{ .Values.config.session.cookie.sameSite | quote }}
  lifespan: {{ .Values.config.session.lifespan }}

secrets:
  {{- if .Values.config.secrets.secretsSecretName }}
  keys:
    - ${SECRETS_KEYS}
  {{- else if .Values.config.secrets.keys }}
  keys:
    {{- toYaml .Values.config.secrets.keys | nindent 4 }}
  {{- else }}
  keys:
    - {{ randAlphaNum 32 | quote }}
  {{- end }}

webauthn:
  relying_party:
    {{- if .Values.config.webauthn.relyingParty.id }}
    id: {{ .Values.config.webauthn.relyingParty.id | quote }}
    {{- else }}
    id: {{ include "hanko.fullname" . }}
    {{- end }}
    name: {{ .Values.config.webauthn.relyingParty.name | quote }}
    {{- if .Values.config.webauthn.relyingParty.origins }}
    origins:
      {{- toYaml .Values.config.webauthn.relyingParty.origins | nindent 6 }}
    {{- end }}
  user_verification: {{ .Values.config.webauthn.userVerification | quote }}

{{- if .Values.config.emailDelivery.enabled }}
email_delivery:
  smtp:
    host: {{ .Values.config.emailDelivery.smtp.host | quote }}
    port: {{ .Values.config.emailDelivery.smtp.port }}
    {{- if .Values.config.emailDelivery.smtp.user }}
    user: {{ .Values.config.emailDelivery.smtp.user | quote }}
    {{- end }}
    {{- if .Values.config.emailDelivery.smtp.passwordSecret }}
    password: ${SMTP_PASSWORD}
    {{- else if .Values.config.emailDelivery.smtp.password }}
    password: {{ .Values.config.emailDelivery.smtp.password | quote }}
    {{- end }}
    {{- if .Values.config.emailDelivery.smtp.tls }}
    tls: {{ .Values.config.emailDelivery.smtp.tls }}
    {{- end }}
  from_address: {{ .Values.config.emailDelivery.fromAddress | quote }}
{{- end }}

password:
  enabled: {{ .Values.config.password.enabled }}
  min_length: {{ .Values.config.password.minLength }}
  require_uppercase: {{ .Values.config.password.requireUppercase }}
  require_lowercase: {{ .Values.config.password.requireLowercase }}
  require_number: {{ .Values.config.password.requireNumber }}
  require_special: {{ .Values.config.password.requireSpecial }}

mfa:
  enabled: {{ .Values.config.mfa.enabled }}
  optional: {{ .Values.config.mfa.optional }}
  acquire_on_login: {{ .Values.config.mfa.acquireOnLogin }}
  acquire_on_registration: {{ .Values.config.mfa.acquireOnRegistration }}
  totp:
    enabled: {{ .Values.config.mfa.totp.enabled }}
  security_keys:
    enabled: {{ .Values.config.mfa.securityKeys.enabled }}

rate_limiter:
  enabled: {{ .Values.config.rateLimiter.enabled }}
  {{- if eq .Values.config.rateLimiter.storage "redis" }}
  storage: redis
  redis:
    host: {{ .Values.config.rateLimiter.redis.host | quote }}
    port: {{ .Values.config.rateLimiter.redis.port }}
    {{- if .Values.config.rateLimiter.redis.password }}
    password: {{ .Values.config.rateLimiter.redis.password | quote }}
    {{- end }}
    database: {{ .Values.config.rateLimiter.redis.database }}
  {{- else }}
  storage: memory
  {{- end }}

log:
  level: {{ .Values.config.log.level | quote }}
  format: {{ .Values.config.log.format | quote }}

audit_log:
  enabled: {{ .Values.config.auditLog.enabled }}
  output: {{ .Values.config.auditLog.output | quote }}

privacy:
  use_analytics: {{ .Values.config.privacy.useAnalytics }}
{{- end }}
