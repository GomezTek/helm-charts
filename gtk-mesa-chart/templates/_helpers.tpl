{{- define "mesa.labels" -}}
app.kubernetes.io/name: {{ .Chart.Name }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "mesa.name" -}}
{{ .Chart.Name }}-{{ .Release.Name }}
{{- end }}

{{- define "mesa.fullname" -}}
{{ include "mesa.name" . }}-{{ .Values.nameOverride | default .Release.Name }}
{{- end }}

# {{- define "mesa.namespace" -}}
# {{ .Release.Namespace }}
# {{- end }}
