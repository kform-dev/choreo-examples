load("api.k8s.io.object.star", "getDeletionTimestamp", "delFinalizer", "setFinalizer")
load("example.com.greetings.star", "getGreeting")


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

  rsp = client_create(getGreeting(self, "hi choreo, i am referencing this code now"))
  if rsp["error"] != None:
    return reconcile_result(self, True, 0, conditionType, rsp["error"], rsp["fatal"])

  rsp = client_apply()
  if rsp["error"] != None:
    return reconcile_result(self, True, 0, conditionType, rsp["error"], rsp["fatal"])
  return reconcile_result(self, False, 0, conditionType, "", False)


