{{/*
Expand the name of the chart.
*/}}
{{- define "mesa.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "mesa.labels" -}}
app.kubernetes.io/name: {{ include "mesa.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: {{ .Values.global.company }}-platform
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
app.kubernetes.io/environment: {{ .Values.global.environment }}
{{- with .Values.global.team }}
team: {{ . }}
{{- end }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "mesa.selectorLabels" -}}
app.kubernetes.io/name: {{ include "mesa.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Common annotations
*/}}
{{- define "mesa.annotations" -}}
meta.helm.sh/release-name: {{ .Release.Name }}
meta.helm.sh/release-namespace: {{ .Release.Namespace }}
{{- with .Values.global.description }}
description: {{ . }}
{{- end }}
{{- end }}

{{/*
Resource name prefix with optional suffix
*/}}
{{- define "mesa.resourceName" -}}
{{- if .root -}}
{{- $prefix := printf "%s-%s" .root.Values.global.company .root.Values.global.environment -}}
{{- if .suffix -}}
{{- printf "%s-%s" $prefix .suffix -}}
{{- else -}}
{{- $prefix -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Company-Environment combination
*/}}
{{- define "mesa.companyEnv" -}}
{{- printf "%s-%s" .Values.global.company .Values.global.environment -}}
{{- end -}}
