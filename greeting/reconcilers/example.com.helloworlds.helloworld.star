load("api.k8s.io.object.star", "getName", "getNamespace", "getDeletionTimestamp", "delFinalizer", "setFinalizer")

finalizer = "greeting.example.com/ready"
conditionType = "Ready"

def reconcile(self):
  # self = helloworld

  if getDeletionTimestamp(self) != None:
    rsp = client_delete()
    if rsp["error"] != None:
      return reconcile_result(self, True, 0, conditionType, rsp["error"], rsp["fatal"])
    
    delFinalizer(self, finalizer)
    return reconcile_result(self, False, 0, conditionType, "", False)
  
  setFinalizer(self, finalizer)

  rsp = client_create(getGreeting(self))
  if rsp["error"] != None:
    return reconcile_result(self, True, 0, conditionType, rsp["error"], rsp["fatal"])

  rsp = client_apply()
  if rsp["error"] != None:
    return reconcile_result(self, True, 0, conditionType, rsp["error"], rsp["fatal"])
  return reconcile_result(self, False, 0, conditionType, "", False)

def getGreeting(helloworld):
  return {
    "apiVersion": "example.com/v1alpha1",
    "kind": "Greeting",
    "metadata": {
        "name": getName(helloworld),
        "namespace": getNamespace(helloworld),
    },
    "spec": {
      "message": getGreetingMsg(helloworld)
    },
  }

def getGreetingMsg(self):
  spec = getSpec(self)
  return spec.get("greeting", "hi choreo, how are you")
