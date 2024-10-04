{{- define "srlsubinterface"}}
      interface:
      - name: {{ .name }}
        subinterface:
        - index: {{ .id }}
          type: {{ .type }}
          description: k8s-{{ printf "%s.%d" .name .id }}
          admin-state: enable
     {{- if .ipv4 }}
          ipv4:
            admin-state: enable
        {{- if ne 0 (len .ipv4.addresses)}}
            address:
        {{- range $index, $address := .ipv4.addresses}}
            - ip-prefix: {{ $address }}
        {{- end }}
            unnumbered:
              admin-state: disable
        {{- end}}
     {{- end}}
     {{- if .ipv6 }}
          ipv6:
            admin-state: enable
            router-advertosement:
              router-role:
                admin-state: enable
        {{- if ne 0 (len .ipv6.addresses)}}
            address:
        {{- range $index, $address := .ipv6.addresses}}
            - ip-prefix: {{ $address }}
        {{- end }}
        {{- end}}
     {{- end}}
{{- end }}
