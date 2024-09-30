finalizer = "example.com/ready"
conditionType = "Ready"

def reconcile(helloworld):
  spec = helloworld.get("spec", {})
  spec["greeting"] = "hello choreo"
  helloworld['spec'] = spec
  return reconcile_result(helloworld, False, 0, conditionType, "", False)