apiVersion: config.sdcio.dev/v1alpha1
kind: Config
metadata:
  name: {{ .metadata.name }}
  namespace: {{ .metadata.namespace }}
  labels:
    config.sdcio.dev/targetName: {{ .spec.node }}
    config.sdcio.dev/targetNamespace: {{ .metadata.namespace }}
  ownerReferences:
  - apiVersion: {{ .apiVersion }}
    controller: true
    kind: {{ .kind }}
    name: {{ .metadata.name }}
    uid: {{ .metadata.uid }}
spec:
  priority: 10
  config:
  - path: /
    value: 
{{- template "srlsubinterface" .spec}}
