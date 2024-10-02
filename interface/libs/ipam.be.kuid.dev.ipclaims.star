def getIPClaim(name, namespace, spec):
  return {
    "apiVersion": "ipam.be.kuid.dev/v1alpha1",
    "kind": "IPClaim",
    "metadata": {
        "name": name,
        "namespace": namespace
    },
    "spec": spec,
  }