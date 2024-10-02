load("id.kuid.dev.ids.star", "genEndpointIDString")
load("infra.kuid.dev.endpoints.star", "getEndpointSpeed")

def getInterfaceSpec(epID):
  spec = {}
  for key, val in epID.items():
    if key == "port" or key == "endpoint":
      spec[key] = int(val)
    else:
      spec[key] = val
  return spec

def getInterface(name, namespace, spec):
  return {
    "apiVersion": "device.network.kubenet.dev/v1alpha1",
    "kind": "Interface",
    "metadata": {
        "name": name,
        "namespace": namespace,
    },
    "spec": spec,
  }


        

        

           