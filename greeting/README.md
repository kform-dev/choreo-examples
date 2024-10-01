# choreo examples

This exercise will walk through a basic Hello world example, which focusses on customizing a resource through some basic business logic. The Hello World API is already generated.

## Hello world resource (API)

```golang
// HelloWorldSpec defines the desired state of the HelloWorld
type HelloWorldSpec struct {
	Greeting string `json:"greeting,omitempty" protobuf:"bytes,1,opt,name=greeting"`
}

// HelloWorldStatus defines the state of the HelloWorld resource
type HelloWorldStatus struct {
	// ConditionedStatus provides the status of the resource using conditions
	// - a ready condition indicates the overall status of the resource
	ConditionedStatus `json:",inline" yaml:",inline" protobuf:"bytes,1,opt,name=conditionedStatus"`
}

// +kubebuilder:object:root=true
// HelloWorld defines the HelloWorld API
type HelloWorld struct {
	metav1.TypeMeta   `json:",inline"`
	metav1.ObjectMeta `json:"metadata,omitempty" protobuf:"bytes,1,opt,name=metadata"`

	Spec HelloWorldSpec `json:"spec,omitempty" protobuf:"bytes,2,opt,name=spec"`
	Status HelloWorldStatus `json:"status,omitempty" protobuf:"bytes,3,opt,name=status"`
}
```

## getting started

clone the choreo-examples git repo

```bash
git clone https://github.com/kform-dev/choreo-examples
```

Best to use 2 windows, one for the choreo server and one for the choreo client, since the choreo server will serve the system

## choreo server

start the choreoserver

```
choreoctl server start choreo-examples/greeting/
```

The choreoserver support a version controlled backend but we don't explore this in this exercise.

```json
{"time":"2024-09-30T19:26:06.771564+02:00","level":"INFO","message":"server started","logger":"choreoctl-logger","data":{"name":"choreoServer","address":"127.0.0.1:51000"}}
branchstore update main oldstate <nil> -> newstate CheckedOut
```

## choreo client

With the following command we can explore the api(s) supported by the system. We see the helloworlds api being present, which got loaded when we started the server

```bash
choreoctl api-resources
```

```bash
&{customresourcedefinitions apiextensions.k8s.io v1 CustomResourceDefinition  false []}
&{upstreamrefs choreo.kform.dev v1alpha1 UpstreamRef  false [pkg knet]}
&{libraries choreo.kform.dev v1alpha1 Library  false [choreo]}
&{apiresources choreo.kform.dev v1alpha1 APIResources  true []}
&{configgenerators choreo.kform.dev v1alpha1 ConfigGenerator  false [pkg knet]}
&{reconcilers choreo.kform.dev v1alpha1 Reconciler  false [choreo]}
&{greetings example.com v1alpha1 Greeting GreetingList true []}
&{helloworlds example.com v1alpha1 HelloWorld HelloWorldList true []}
```

When executing the following command no result should be shown, since no hello world resources are loaded

```
choreoctl get customresourcedefinitions.apiextensions.k8s.io
```

Autocompletion should work, maybe try TAB completion iso copying the full command

Now run the reconciler

```
choreoctl run once
```

you should see the reconciler `example.com.helloworlds.helloworld` being executed.

```
execution success, time(sec) 0.0031725
Reconciler                         Start Stop Requeue Error
example.com.helloworlds.helloworld     3    3       0     0
```

What just happened?

a. the reconciler got loaded

/// details | HelloWorld Reconciler

```yaml
--8<--
https://raw.githubusercontent.com/kform-dev/choreo-examples/main/greeting/reconcilers/example.com.helloworlds.helloworld.star
--8<--
```

///

b. The reconciler registered to be informed on any HelloWorld resource change

```yaml
    group: example.com
    version: v1alpha1
    kind: HelloWorld
```

/// details | HelloWorld Reconciler Hook

```yaml
--8<--
https://raw.githubusercontent.com/kform-dev/choreo-examples/main/greeting/reconcilers/example.com.helloworlds.helloworld.yaml
--8<--
```

///

c. The reconciler business logic got triggered by adding this HelloWorld manifest

/// details | Hello World manifest

```yaml
--8<--
https://raw.githubusercontent.com/kform-dev/choreo-examples/main/greeting/in/example.com.helloworlds.test.yaml
--8<--
```

///

let's see if it performed its job, by looking at the details of the HelloWorld manifest

```
choreoctl get helloworlds.example.com test -o yaml
```

We should see a new resource being generated

```yaml
apiVersion: example.com/v1alpha1
kind: Greeting
metadata:
  creationTimestamp: "2024-10-01T05:45:08Z"
  generation: 1
  managedFields:
  - apiVersion: example.com/v1alpha1
    fieldsType: FieldsV1
    fieldsV1:
      f:metadata:
        f:ownerReferences:
          k:{"uid":"8cad289b-7e68-42b0-a864-a1369414b401"}: {}
      f:spec:
        f:message: {}
    manager: example.com.helloworlds.helloworld
    operation: Apply
    time: "2024-10-01T05:45:57Z"
  name: test
  namespace: default
  ownerReferences:
  - apiVersion: example.com/v1alpha1
    controller: true
    kind: HelloWorld
    name: test
    uid: 8cad289b-7e68-42b0-a864-a1369414b401
  resourceVersion: "1"
  uid: e0dd1952-2f97-4090-a170-53460860f0fb
spec:
  message: hi
```

🎉 You have generated a greeting resource from the hello world resource. 🤘

Try changing the business logic from `Hello Choreo` to `hello <your name>` and execute the business logic again

```python
def reconcile(helloworld):
  spec = helloworld.get("spec", {})
  spec["greeting"] = "hello wim"
  helloworld['spec'] = spec
  return reconcile_result(helloworld, False, 0, conditionType, "", False)
```

This should result in the following outcome if we run the business logic again.

```
choreoctl run once
```

```yaml
apiVersion: example.com/v1alpha1
kind: HelloWorld
metadata:
  annotations:
    api.choreo.kform.dev/origin: '{"kind":"File"}'
  creationTimestamp: "2024-09-30T17:49:34Z"
  generation: 1
  name: test
  namespace: default
  resourceVersion: "1"
  uid: deedbf64-b348-477e-9fbb-d2738ab4f3b0
spec:
  greeting: hello wim
status:
  conditions:
  - lastTransitionTime: "2024-09-30T17:49:34Z"
    message: ""
    reason: Ready
    status: "True"
    type: Ready
```

You can also introduce an error and see what happens; e.g. change `greeting` to `greetings` which is an invalid json key in the schema.

```python
def reconcile(helloworld):
  spec = helloworld.get("spec", {})
  spec["greetings"] = "hello wim"
  helloworld['spec'] = spec
  return reconcile_result(helloworld, False, 0, conditionType, "", False)
```

when executing

```
choreoctl run once
```

the following result is obtained, indicating the schema error

```bash
execution failed example.com.helloworlds.helloworld.HelloWorld.example.com.test rpc error: code = InvalidArgument desc = fieldmanager apply failed err: failed to create typed patch object (default/test; example.com/v1alpha1, Kind=HelloWorld): .spec.greetings: field not declared in schema
```