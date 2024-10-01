finalizer = "helloworld.example.com/ready"
conditionType = "Ready"

def reconcile(self):
  # self = helloworld

  spec = self.get("spec", {})
  spec["greeting"] = "hello choreo"
  self['spec'] = spec
  return reconcile_result(self, False, 0, conditionType, "", False)