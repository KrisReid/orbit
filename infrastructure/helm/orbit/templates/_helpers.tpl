{{/*
Expand the name of the chart.
*/}}
{{- define "orbit.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "orbit.fullname" -}}
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
{{- define "orbit.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "orbit.labels" -}}
helm.sh/chart: {{ include "orbit.chart" . }}
{{ include "orbit.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "orbit.selectorLabels" -}}
app.kubernetes.io/name: {{ include "orbit.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Backend labels
*/}}
{{- define "orbit.backend.labels" -}}
{{ include "orbit.labels" . }}
app.kubernetes.io/component: backend
{{- end }}

{{/*
Backend selector labels
*/}}
{{- define "orbit.backend.selectorLabels" -}}
{{ include "orbit.selectorLabels" . }}
app.kubernetes.io/component: backend
{{- end }}

{{/*
Frontend labels
*/}}
{{- define "orbit.frontend.labels" -}}
{{ include "orbit.labels" . }}
app.kubernetes.io/component: frontend
{{- end }}

{{/*
Frontend selector labels
*/}}
{{- define "orbit.frontend.selectorLabels" -}}
{{ include "orbit.selectorLabels" . }}
app.kubernetes.io/component: frontend
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "orbit.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "orbit.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Backend image
*/}}
{{- define "orbit.backend.image" -}}
{{- $tag := .Values.backend.image.tag | default .Chart.AppVersion }}
{{- printf "%s:%s" .Values.backend.image.repository $tag }}
{{- end }}

{{/*
Frontend image
*/}}
{{- define "orbit.frontend.image" -}}
{{- $tag := .Values.frontend.image.tag | default .Chart.AppVersion }}
{{- printf "%s:%s" .Values.frontend.image.repository $tag }}
{{- end }}

{{/*
Database URL
*/}}
{{- define "orbit.databaseUrl" -}}
{{- if .Values.externalDatabase.enabled }}
{{- printf "postgresql+asyncpg://%s:$(DATABASE_PASSWORD)@%s:%d/%s" .Values.externalDatabase.username .Values.externalDatabase.host (int .Values.externalDatabase.port) .Values.externalDatabase.database }}
{{- else }}
{{- printf "postgresql+asyncpg://%s:$(DATABASE_PASSWORD)@%s-postgresql:5432/%s" .Values.postgresql.auth.username (include "orbit.fullname" .) .Values.postgresql.auth.database }}
{{- end }}
{{- end }}

{{/*
Secret name for backend
*/}}
{{- define "orbit.backend.secretName" -}}
{{- if .Values.backend.secrets.existingSecret }}
{{- .Values.backend.secrets.existingSecret }}
{{- else }}
{{- printf "%s-backend" (include "orbit.fullname" .) }}
{{- end }}
{{- end }}

{{/*
Secret name for database password
*/}}
{{- define "orbit.database.secretName" -}}
{{- if .Values.externalDatabase.enabled }}
  {{- if .Values.externalDatabase.existingSecret }}
    {{- .Values.externalDatabase.existingSecret }}
  {{- else }}
    {{- printf "%s-external-db" (include "orbit.fullname" .) }}
  {{- end }}
{{- else }}
  {{- if .Values.postgresql.auth.existingSecret }}
    {{- .Values.postgresql.auth.existingSecret }}
  {{- else }}
    {{- printf "%s-postgresql" (include "orbit.fullname" .) }}
  {{- end }}
{{- end }}
{{- end }}

{{/*
Secret key for database password
*/}}
{{- define "orbit.database.secretKey" -}}
{{- if .Values.externalDatabase.enabled }}
  {{- .Values.externalDatabase.existingSecretPasswordKey | default "password" }}
{{- else }}
  {{- .Values.postgresql.auth.secretKeys.userPasswordKey | default "password" }}
{{- end }}
{{- end }}
