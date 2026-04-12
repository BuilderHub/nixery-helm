{{/*
Expand the name of the chart.
*/}}
{{- define "nixery.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "nixery.fullname" -}}
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
Chart label*/}}
{{- define "nixery.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "nixery.labels" -}}
helm.sh/chart: {{ include "nixery.chart" . }}
{{ include "nixery.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "nixery.selectorLabels" -}}
app.kubernetes.io/name: {{ include "nixery.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Service account name
*/}}
{{- define "nixery.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "nixery.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Validate replica count vs filesystem backend
*/}}
{{- define "nixery.validateFilesystemReplicas" -}}
{{- if and (eq .Values.storage.backend "filesystem") (gt (int .Values.replicaCount) 1) }}
{{- fail "storage.backend filesystem is not compatible with replicaCount > 1; use S3 or GCS for HA, or set replicaCount to 1" }}
{{- end }}
{{- end }}

{{- define "nixery.validatePkgSource" -}}
{{- $ch := .Values.nixery.channel | default "" | trim }}
{{- $repo := .Values.nixery.pkgsRepo | default "" | trim }}
{{- $path := .Values.nixery.pkgsPath | default "" | trim }}
{{- $n := 0 }}
{{- if ne $ch "" }}{{ $n = add1 $n }}{{- end }}
{{- if ne $repo "" }}{{ $n = add1 $n }}{{- end }}
{{- if ne $path "" }}{{ $n = add1 $n }}{{- end }}
{{- if eq $n 0 }}
{{- fail "nixery: set exactly one of nixery.channel, nixery.pkgsRepo, or nixery.pkgsPath" }}
{{- end }}
{{- if gt $n 1 }}
{{- fail "nixery: only one of nixery.channel, nixery.pkgsRepo, or nixery.pkgsPath may be set (set unused fields to empty string)" }}
{{- end }}
{{- end }}

{{- define "nixery.validateStorage" -}}
{{- if eq .Values.storage.backend "s3" }}
{{- if not .Values.storage.s3.bucket }}
{{- fail "storage.s3.bucket is required when storage.backend is s3" }}
{{- end }}
{{- end }}
{{- if eq .Values.storage.backend "gcs" }}
{{- if not .Values.storage.gcs.bucket }}
{{- fail "storage.gcs.bucket is required when storage.backend is gcs" }}
{{- end }}
{{- end }}
{{- end }}

{{- define "nixery.validateFilesystemVolumes" -}}
{{- if eq .Values.storage.backend "filesystem" }}
{{- if not (or .Values.storage.filesystem.persistence.enabled .Values.storage.filesystem.emptyDir.enabled) }}
{{- fail "filesystem storage requires storage.filesystem.persistence.enabled or storage.filesystem.emptyDir.enabled" }}
{{- end }}
{{- end }}
{{- end }}
