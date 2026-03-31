resource "kubectl_manifest" "nginx_deployment" {
    depends_on = [ module.k3s_cluster , module.helm_ingress ]
  yaml_body = <<YAML
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-demo
  namespace: default
spec:
  replicas: 2
  selector:
    matchLabels:
      app: nginx-demo
  template:
    metadata:
      labels:
        app: nginx-demo
    spec:
      containers:
        - name: nginx
          image: bitnami/nginx:latest
          ports:
            - containerPort: 8080
YAML
}
resource "kubectl_manifest" "nginx_service" {
     depends_on = [ module.k3s_cluster , module.helm_ingress ]
  yaml_body = <<YAML
apiVersion: v1
kind: Service
metadata:
  name: nginx-demo
  namespace: default
spec:
  type: NodePort 
  selector:
    app: nginx-demo
  ports:
    - port: 80
      targetPort: 8080
      # nodePort: 30080   # optional; k8s can assign automatically
YAML
}

resource "kubectl_manifest" "nginx_ingress" {
  depends_on = [kubectl_manifest.nginx_service,module.helm_ingress,module.k3s_cluster]

  yaml_body = <<YAML
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: nginx-demo
  namespace: default
spec:
  ingressClassName: nginx
  rules:  
    - http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: nginx-demo
                port:
                  number: 80
YAML
}