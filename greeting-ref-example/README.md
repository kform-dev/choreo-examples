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

```
```