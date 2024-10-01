# choreo examples

assumption is you continue from the hello workd example

The goal of this exercise is to show you can generate a new resource from a top resource. Secondly we want to show you the use of libraries where you can store reusable components and libraries you can leverage in various reconcilers.

In this example we create a `Greeting` resource from the `Helloworld` resource. 

## reconciler changes

The reconciler got some new extensions to hook into the system. Basides the for, you now also see the owns registration of the greeting resource. This basically tell the system that this reconciler can generate the `Greeting` resource.

```yaml
spec: 
  for: 
    group: example.com
    version: v1alpha1
    kind: HelloWorld
    selector: {}
  owns:
  - group: example.com
    version: v1alpha1
    kind: Greeting
```

## choreo server

start the choreoserver

```
choreoctl server start choreo-examples/greeting
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
example.com.helloworlds.helloworld     3    3       0     0
```

let's see if it performed its job, by looking at the details of the HelloWorld manifest

```
choreoctl get helloworlds.example.com test -o yaml
```

We should see a new `Greeting` resource being generated.

```yaml
apiVersion: example.com/v1alpha1
kind: Greeting
metadata:
  creationTimestamp: "2024-10-01T15:31:24Z"
  generation: 1
  managedFields:
  - apiVersion: example.com/v1alpha1
    fieldsType: FieldsV1
    fieldsV1:
      f:metadata:
        f:ownerReferences:
          k:{"uid":"4e126eed-2282-49f2-9e25-2b7e947a3ad6"}: {}
      f:spec:
        f:message: {}
    manager: example.com.helloworlds.helloworld
    operation: Apply
    time: "2024-10-01T15:32:20Z"
  name: test
  namespace: default
  ownerReferences:
  - apiVersion: example.com/v1alpha1
    controller: true
    kind: HelloWorld
    name: test
    uid: 4e126eed-2282-49f2-9e25-2b7e947a3ad6
  resourceVersion: "1"
  uid: a9326b59-cead-482f-a77a-cd36042b7d91
spec:
  message: hello choreo
```

Look at the owner reference. You see Greeting is owned by HelloWorld. Lets check the dependencies

```bash
chorectl deps
```

```bash
CustomResourceDefinition.apiextensions.k8s.io/v1 greetings.example.com 
CustomResourceDefinition.apiextensions.k8s.io/v1 helloworlds.example.com 
HelloWorld.example.com/v1alpha1 test 
+-Greeting.example.com/v1alpha1 test 
Library.choreo.kform.dev/v1alpha1 api.k8s.io.object.star 
Reconciler.choreo.kform.dev/v1alpha1 example.com.helloworlds.helloworld 
```

🎉 You have generated a greeting resource from the hello world resource. 🤘

Try removing the spec from the hello world resource and run once again

```yaml
apiVersion: example.com/v1alpha1
kind: HelloWorld
metadata:
  name: test
  namespace: default
```

```bash
choreoctl run once
```

expected result.

```yaml
apiVersion: example.com/v1alpha1
kind: Greeting
metadata:
  creationTimestamp: "2024-10-01T15:31:24Z"
  generation: 2
  managedFields:
  - apiVersion: example.com/v1alpha1
    fieldsType: FieldsV1
    fieldsV1:
      f:metadata:
        f:ownerReferences:
          k:{"uid":"4e126eed-2282-49f2-9e25-2b7e947a3ad6"}: {}
      f:spec:
        f:message: {}
    manager: example.com.helloworlds.helloworld
    operation: Apply
    time: "2024-10-01T15:37:36Z"
  name: test
  namespace: default
  ownerReferences:
  - apiVersion: example.com/v1alpha1
    controller: true
    kind: HelloWorld
    name: test
    uid: 4e126eed-2282-49f2-9e25-2b7e947a3ad6
  resourceVersion: "2"
  uid: a9326b59-cead-482f-a77a-cd36042b7d91
spec:
  message: hi choreo, how are you?
```