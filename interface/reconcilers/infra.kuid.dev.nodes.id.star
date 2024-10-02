load("api.k8s.io.object.star", "getName", "getNamespace", "getDeletionTimestamp", "delFinalizer", "setFinalizer")
load("infra.kuid.dev.nodes.star", "getPartition")
load("ipam.be.kuid.dev.ipindices.star", "getIPIndexInstance", "getIPClaims")

finalizer = "node.infra.kuid.dev/ids"
conditionType = "IPClaimReady"

def reconcile(self):
  # self is node
  name = getName(self)
  namespace = getNamespace(self)
  partition = getPartition(self)

  if getDeletionTimestamp(self) != None:
    rsp = client_delete()
    if rsp["error"] != None:
      return reconcile_result(self, True, 0, conditionType, rsp["error"], rsp["fatal"])
    
    delFinalizer(self, finalizer)
    return reconcile_result(self, False, 0, conditionType, "", False)

  setFinalizer(self, finalizer)

  ipindex, err = getIPIndexInstance(partition + "." + "default", namespace)
  if err != None:
    # we dont return the error but wait for the network design retrigger
    return reconcile_result(self, False, 0, conditionType, err, False)
        
  ipClaims = getIPIndexIPClaims(self, name)
  for ipClaim in ipClaims:
    rsp = client_create(ipClaim)
    if rsp["error"] != None:
        return reconcile_result(self, True, 0, conditionType, rsp["error"], rsp["fatal"])

  rsp = client_apply()
  if rsp["error"] != None:
    return reconcile_result(self, True, 0, conditionType, rsp["error"], rsp["fatal"])
  return reconcile_result(self, False, 0, conditionType, "", False)
