load("id.kuid.dev.ids.star", "getNodeKeys", "getEndpointKeys", "genEndpointIDString")

def getSpec(self):
  return self.get("spec", {})

def getInterfaceName(self):
  spec = getSpec(self)
  return spec.get("name", "")

def getLocalAF(self, af):
  spec = getSpec(self)
  return spec.get(af, {})

def getLocalAddresses(self, af):
  af = getLocalAF(self, af)
  return  af.get("addresses", [])

def getLocalAddress(self, af, idx):
  addresses = getLocalAddresses(self, af)
  return get_address(addresses[idx])

def getPeerAF(self, af):
  spec = getSpec(self)
  peer = spec.get("peer", {})
  return peer.get(af, {})

def getPeerAddresses(self, af):
  af = getPeerAF(self, af)
  return  af.get("addresses", [])

def getPeerAddress(self, af, idx):
  addresses = getPeerAddresses(self, af)
  return get_address(addresses[idx])

def getLocalNodeID(self):
  nodeKeys = getNodeKeys()
  spec = getSpec(self)
  nodeID = {}
  for key, val in spec.items():
    if key in nodeKeys:
      nodeID[key] = val
  return nodeID

def getPeer(self):
  spec = getSpec(self)
  return spec.get("peer", {})

def getPeerNodeID(self):
  nodeKeys = getNodeKeys()
  peer = getPeer(self)
  nodeID = {}
  for key, val in peer.items():
    if key in nodeKeys:
      nodeID[key] = val
  return nodeID

def getPartition(self):
  spec = getSpec(self)
  return spec.get("partition", "")

def getspec(si):
  return si.get("spec", {})

def getEPID(si):
  epID = {}
  epKeys = getEndpointKeys()
  spec = getspec(si)
  for key, val in spec.items():
    if key in epKeys:
      epID[key] = val
  return epID


def getID(si):
  spec = getspec(si)
  return spec.get("id", 0)

def getSubInterface(name, namespace, spec):
  return {
    "apiVersion": "device.network.kubenet.dev/v1alpha1",
    "kind": "SubInterface",
    "metadata": {
        "name": name,
        "namespace": namespace
    },
    "spec": spec,
  }