{{/* Expand the name of the chart. */}}
{{- define "base-workload.name" -}}
{{- default .Release.Name .Values.app.name | trunc 63 | trimSuffix "-" -}}
{{- end }}

{{/* Create chart name and version as used by the chart label. */}}
{{- define "base-workload.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end }}

{{/* Common labels */}}
{{- define "base-workload.labels" -}}
helm.sh/chart: {{ include "base-workload.chart" . }}
app.kubernetes.io/name: {{ include "base-workload.name" . }}
app.kubernetes.io/instance: {{ default .Release.Name .Values.app.instance }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- if .Values.app.component }}
app.kubernetes.io/component: {{ .Values.app.component }}
{{- end }}
{{- if .Values.app.partOf }}
app.kubernetes.io/part-of: {{ .Values.app.partOf }}
{{- end }}
{{- end }}

{{/* Match labels */}}
{{- define "base-workload.selectorLabels" -}}
app.kubernetes.io/name: {{ include "base-workload.name" . }}
app.kubernetes.io/instance: {{ default .Release.Name .Values.app.instance }}
{{- end }}