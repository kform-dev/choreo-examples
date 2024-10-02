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

def getPrefixPrefix(prefix):
  return prefix.get("prefix", "")

def getPrefixType(prefix):
  return prefix.get("prefixType", "aggregate")

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

def getEnabledAFs(ipindex):
  afs = {
    "ipv4": False,
    "ipv6": False,
  }
  for prefix in getPrefixes(ipindex):
    if isIPv4(getPrefixPrefix(prefix)):
      afs["ipv4"] = True
    if isIPv6(getPrefixPrefix(prefix)):
      afs["ipv6"] = True
  return ipclaims

def getIPIndexIPClaims(ipindex, parentName):
  ipclaims = []
  namespace = getNamespace(ipindex)
  ipIndexName = getName(ipindex)

  for af in getEnabledAFs(afs):
    labels = {}
    labels["ipam.be.kuid.dev/address-family"] = af
    ipclaims.append(getIPClaim(parentName + "." + af, namespace, getIPIndexIPClaimSpec(ipIndexName, getPrefixType(prefix), labels)))
  return ipclaims

def getIPIndexIPClaimSpec(ipindexName, ipPrefixType, labels):
  return {
        "index": ipindexName,
        "prefixType": ipPrefixType,
        "selector": {
          "matchLabels": labels,
        }
      }
