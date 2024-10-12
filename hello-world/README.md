# choreo HelloWorld example

The goal of this exercise is to show you the basics of choreo and how you can customize the business logic using a hello world example. The Hello World API is already generated from this [source][#Hello world resource (API)]


## getting started

/// tab | Codespaces

run the environment in codespaces

```bash
https://codespaces.new/kform-dev/choreo-examples
```

///


/// tab | local environment

clone the choreo-examples git repo

```bash
git clone https://github.com/kform-dev/choreo-examples
```

///

Best to use 2 windows, one for the choreo server and one for the choreo client, since the choreo server will serve the system

## choreo server

start the choreoserver

```bash
choreoctl server start hello-world
```

The choreoserver support a version controlled backend (git) but we don't explore this in this exercise.

```json
{"time":"2024-09-30T19:26:06.771564+02:00","level":"INFO","message":"server started","logger":"choreoctl-logger","data":{"name":"choreoServer","address":"127.0.0.1:51000"}}
branchstore update main oldstate <nil> -> newstate CheckedOut
```

## choreo client

With the following command we can explore the api(s) supported by the system. We see the `helloworlds` api being present. Choreo comes with some built in apis and can be extended with your own customized apis (CRDs).

These API(s) got loaded when the server started.

```bash
choreoctl api-resources
```

```bash
&{upstreamrefs choreo.kform.dev v1alpha1 UpstreamRef  false [pkg knet]}
&{libraries choreo.kform.dev v1alpha1 Library  false [choreo]}
&{apiresources choreo.kform.dev v1alpha1 APIResources  true []}
&{configgenerators choreo.kform.dev v1alpha1 ConfigGenerator  false [pkg knet]}
&{customresourcedefinitions apiextensions.k8s.io v1 CustomResourceDefinition  false []}
&{reconcilers choreo.kform.dev v1alpha1 Reconciler  false [choreo]}
&{helloworlds example.com v1alpha1 HelloWorld HelloWorldList true []}
```

When executing the following command no result should be shown, since no hello world resources are loaded

```bash
choreoctl get helloworlds.example.com
```

Autocompletion should work, maybe try TAB completion iso copying the full command

Now run the reconciler

```bash
choreoctl run once
```

you should see the reconciler `example.com.helloworlds.helloworld` being executed.

```bash
execution success, time(sec) 0.0031725
Reconciler                         Start Stop Requeue Error
example.com.helloworlds.helloworld     2    2       0     0
```

What just happened?

a. the reconciler got loaded

/// details | HelloWorld Reconciler

```yaml
--8<--
https://raw.githubusercontent.com/kform-dev/choreo-examples/main/hello-world/reconcilers/example.com.helloworlds.helloworld.star
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
https://raw.githubusercontent.com/kform-dev/choreo-examples/main/hello-world/reconcilers/example.com.helloworlds.helloworld.yaml
--8<--
```

///

c. The reconciler business logic got triggered by adding this HelloWorld manifest

/// details | Hello World manifest

```yaml
--8<--
https://raw.githubusercontent.com/kform-dev/choreo-examples/main/hello-world/in/example.com.helloworlds.test.yaml
--8<--
```

///

let's see if it performed its job, by looking at the details of the HelloWorld manifest

```bash
choreoctl get helloworlds.example.com test -o yaml
```

We should see spec.greeting being changed to `hello choreo`

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
  greeting: hello choreo
status:
  conditions:
  - lastTransitionTime: "2024-09-30T17:49:34Z"
    message: ""
    reason: Ready
    status: "True"
    type: Ready
```

🎉 You ran you first choreo reconciler. 🤘

Did you notice none of this required a kubernetes cluster?
Choreo applies the kubernetes principles w/o imposing all the kubernetes container orchestration primitives.

Try changing the business logic from `Hello choreo` to `hello <your name>` and execute the business logic again

```python
def reconcile(self):
  spec = self.get("spec", {})
  spec["greeting"] = "hello me"
  self['spec'] = spec
  return reconcile_result(self, False, 0, conditionType, "", False)
```

After changing the business logic run the following command. This takes the reconcilers and libraries and update the reconciler and library files with the updated busines logic

```bash
choreoctl dev parse hello-world
```

This should result in the following outcome if we run the business logic again.

```bash
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
  greeting: hello me
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
def reconcile(self):
  spec = self.get("spec", {})
  spec["greetings"] = "hello me"
  self['spec'] = spec
  return reconcile_result(self, False, 0, conditionType, "", False)
```

update the reconciler input files.

```bash
choreoctl dev parse hello-world
```

when executing

```bash
choreoctl run once
```

the following result is obtained, indicating the schema error

```bash
execution failed example.com.helloworlds.helloworld.HelloWorld.example.com.test rpc error: code = InvalidArgument desc = fieldmanager apply failed err: failed to create typed patch object (default/test; example.com/v1alpha1, Kind=HelloWorld): .spec.greetings: field not declared in schema
```

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