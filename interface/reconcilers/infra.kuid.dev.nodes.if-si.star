load("api.k8s.io.object.star", "getName", "getNamespace", "getDeletionTimestamp", "delFinalizer", "setFinalizer")
load("infra.kuid.dev.nodes.star", "getPartition", "getNodeID")
load("id.kuid.dev.ids.star", "getEndpointID", "genEndpointIDString", "genNodeIDString")
load("device.network.kubenet.dev.interfaces.star", "getInterfaceSpec", "getInterface")
load("device.network.kubenet.dev.subinterfaces.star", "getSubInterface")
load("ipam.be.kuid.dev.ipclaims.star", "getIPClaimedAddress")
load("ipam.be.kuid.dev.ipindices.star", "getIPIndexInstance", "getEnabledAFs")

finalizer = "node.infra.kuid.dev/itfce"
conditionType = "InterfaceReady"

def reconcile(self):
  namespace = getNamespace(self)
  partition = getPartition(self)

  if getDeletionTimestamp(self) != None:
    rsp = client_delete()
    if rsp["error"] != None:
      return reconcile_result(self, True, 0, conditionType, rsp["error"], rsp["fatal"])
    
    delFinalizer(self, finalizer)
    return reconcile_result(self, False, 0, conditionType, "", False)

  setFinalizer(self, finalizer)

  if is_conditionready(self, "IPClaimReady") != True:
    return reconcile_result(self, True, 0, conditionType, "ip claim not ready", False)

  ipindex, err = getIPIndexInstance(partition + "." + "default", namespace)
  if err != None:
    # we dont return the error but wait for the network design retrigger
    return reconcile_result(self, False, 0, conditionType, err, False)

  interfaces = getInterfaces(self)
  for itfce in interfaces:
    rsp = client_create(itfce)
    if rsp["error"] != None:
      return reconcile_result(self, True, 0, conditionType, rsp["error"], rsp["fatal"])
  
  subInterfaces, err = getSubInterfaces(self, ipindex)
  if err != None:
    return reconcile_result(self, True, 0, conditionType, err, False)
  for subItfce in subInterfaces:
    rsp = client_create(subItfce)
    if rsp["error"] != None:
      return reconcile_result(self, True, 0, conditionType, rsp["error"], rsp["fatal"]) 
  
  rsp = client_apply()
  if rsp["error"] != None:
    return reconcile_result(self, True, 0, conditionType, rsp["error"], rsp["fatal"])
  return reconcile_result(self, False, 0, conditionType, "", False)

def getInterfaces(self):
  nodeID = getNodeID(self)
  namespace = getNamespace(self)

  interfaces = []
  systemEPID = getEndpointID(nodeID, 0, 0, "system")
  systemEPName = genEndpointIDString(systemEPID)
  systemSpec = getInterfaceSpec(systemEPID)   
  interfaces.append(getInterface(systemEPName, namespace, systemSpec))   

  return interfaces


def getSubInterfaces(self, ipindex):
  nodeID = getNodeID(self)
  nodeName = getName(self)
  namespace = getNamespace(self)

  subinterfaces = []

  id = 0
  epID = getEndpointID(nodeID, 0, 0, "system")
  siName = genEndpointIDString(epID) + "." + str(id)

  spec = {}
  for key, val in epID.items():
    if key == "port" or key == "endpoint":
      spec[key] = int(val)
    else:
      spec[key] = val
  spec["type"] = "routed"
  spec["id"] = id
  for af in getEnabledAFs(ipindex):
    afaddrs = {}
    afaddrs["addresses"] = []
    address, err = getIPClaimedAddress(genNodeIDString(nodeID) + "." + af, namespace) 
    if err != None:
      return None, err
    afaddrs["addresses"].append(address)
    spec[af] = afaddrs
  
  subinterfaces.append(getSubInterface(siName, namespace, spec))
  return subinterfaces, None