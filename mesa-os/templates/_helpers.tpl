{{/*
Expand the name of the chart.
*/}}
{{- define "mesa.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "mesa.fullname" -}}
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
{{- define "mesa.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "mesa.labels" -}}
helm.sh/chart: {{ include "mesa.chart" . }}
app.kubernetes.io/name: {{ include "mesa.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Common Annotations
*/}}
{{- define "mesa.annotations" -}}
meta.helm.sh/release-name: {{ .Release.Name }}
meta.helm.sh/release-namespace: {{ .Release.Namespace }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "mesa.selectorLabels" -}}
app.kubernetes.io/name: {{ include "mesa.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Resource Name Helper
*/}}
{{- define "mesa.resourceName" -}}
{{- $root := .root }}
{{- $suffix := .suffix }}
{{- if $suffix }}
{{- printf "%s-%s-%s" $root.Values.global.company $root.Values.global.environment $suffix | lower | trunc 63 | trimPrefix "-" | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" $root.Values.global.company $root.Values.global.environment | lower | trunc 63 | trimPrefix "-" | trimSuffix "-" }}
{{- end }}
{{- end }}
