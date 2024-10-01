load("api.k8s.io.object.star", "getName", "getNamespace", "getSpec")

def getGreeting(self, msg):
  return {
    "apiVersion": "example.com/v1alpha1",
    "kind": "Greeting",
    "metadata": {
        "name": getName(self),
        "namespace": getNamespace(self),
    },
    "spec": {
      "message": getGreetingMsg(self, msg)
    },
  }

def getGreetingMsg(self, msg):
  spec = getSpec(self)
  return spec.get("greeting", msg)