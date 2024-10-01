# choreo examples

assumption is you continue from the greeting example

The goal of this exercise is to show how you can reference code or data from a blueprint example. As such you build more reusable code that can be leveraaged amongst various projects.

In this exercise we use the same logic as in the greetings example, with the difference that the reconciler and library code is imported from an upstream repo.

## upstream reference

in this project we added an upstream reference, which points to a repo URL with a subdirectory in the repo and a hash reference as an immutable reference. The library/reconcilers and data in this repo is used as the reconciler logic in the exercise.

```yaml
apiVersion: choreo.kform.dev/v1alpha1
kind: UpstreamRef
metadata:
  name: greeting
spec:
  url: https://github.com/kform-dev/choreo-examples.git
  directory: greeting-ref
  ref:
    type: hash
    name: f90ee1ae44bd6a1568e9d5f5e9d2ea1850de6693
```

## starting the choreoserver

```bash
choreoctl server run greeting-ref-example
```

## api resources

after starting the choreoserver, we can see the api resources got imported

```bash
choreoctl api-resources
```

```bash
&{upstreamrefs choreo.kform.dev v1alpha1 UpstreamRef  false [pkg knet]}
&{libraries choreo.kform.dev v1alpha1 Library  false [choreo]}
&{greetings example.com v1alpha1 Greeting GreetingList true []}
&{helloworlds example.com v1alpha1 HelloWorld HelloWorldList true []}
&{apiresources choreo.kform.dev v1alpha1 APIResources  true []}
&{customresourcedefinitions apiextensions.k8s.io v1 CustomResourceDefinition  false []}
&{configgenerators choreo.kform.dev v1alpha1 ConfigGenerator  false [pkg knet]}
&{reconcilers choreo.kform.dev v1alpha1 Reconciler  false [choreo]}
```

## running the business logic

```
chorectl run once
```

check if we get the proper result. Given the helloWorld spec was empty we get the default greeting

```bash
choreoctl get greetings.example.com test -o yaml
```

HelloWorld input

```yaml
apiVersion: example.com/v1alpha1
kind: HelloWorld
metadata:
  name: test
  namespace: default
```

Greeting output

```yaml
apiVersion: example.com/v1alpha1
kind: Greeting
metadata:
  creationTimestamp: "2024-10-01T15:56:49Z"
  name: test
  namespace: default
  ownerReferences:
  - apiVersion: example.com/v1alpha1
    controller: true
    kind: HelloWorld
    name: test
    uid: ccf5df9e-543f-4c47-9f90-51d14f36b4bf
  resourceVersion: "0"
  uid: 525dc6dc-624c-408d-b952-4b52b8042270
spec:
  message: hi choreo, i am referencing this code now
```
