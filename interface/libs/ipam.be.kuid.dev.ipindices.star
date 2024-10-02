load("api.k8s.io.object.star", "getName", "getNamespace")
load("ipam.be.kuid.dev.ipclaims.star", "getIPClaim")

def getIPIndexInstance(name, namespace):
  resource = get_resource("ipam.be.kuid.dev/v1alpha1", "IPIndex")
  rsp = client_get(name, namespace, resource["resource"])
  if rsp["error"] != None:
    return None, "ipindex " + name + " err: " + rsp["error"]
  
  if is_conditionready(rsp["resource"], "Ready") != True:
    return None, "ipindex " + name + " not ready"
  return rsp["resource"], None

def getPrefixes(ipindex):
  spec = ipindex.get("spec", {})
  return spec.get("prefixes", [])

def getPrefixType(prefix):
  return prefix.get("prefixTYpe", "agagregate")

def getLabels(prefix):
  return prefix.get("labels", {})

def getIPIndex(name, namespace, spec):
  return {
    "apiVersion": "ipam.be.kuid.dev/v1alpha1",
    "kind": "IPIndex",
    "metadata": {
        "name": name,
        "namespace": namespace
    },
    "spec": spec,
  }

def getIPIndexIPClaims(ipindex, parentName):
  ipclaims = []
  namespace = getNamespace(ipindex)
  ipIndexName = getName(ipindex)

  for prefix in getPrefixes(ipindex):
    af = "ipv6"
    if isIPv4(index, prefix):
      af = "ipv4"
    labels = getLabels(prefix)
    labels["ipam.be.kuid.dev/address-family"] = af

    ipclaims.append(getIPClaim(parentName + "." + af, namespace, getIPIndexIPClaimSpec(ipIndexName, getPrefixType(prefix), labels)))
  return ipclaims

def getIPIndexIPClaimSpec(ipindexName, ipPrefixType, labels):
  return {
        "index": ipIndexName,
        "prefixType": ipPrefixType,
        "selector": {
          "matchLabels": labels,
        }
      }
