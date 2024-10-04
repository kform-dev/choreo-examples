# choreo Config example

This exercise build from the interface example. Besides creating a `Interface` and `SubInterface` object using the python reconcilers we also generate a device specific `Config` resource for the interface and subinterface that represents a Nokia SRL specific device config. We use go templates to render the device specific configs in this exercise. Besides `python` also `gotemplate` based reconcilers are used in this exercise.

## Input used in this exercise

You were delegated a prefix from the orginization, which you can use to claim IP addresses from.

```yaml
apiVersion: ipam.be.kuid.dev/v1alpha1
kind: IPIndex
metadata:
  name: kubenet.default
  namespace: default
spec:
  prefixes:
  - prefix: 10.0.0.0/24
    prefixType: pool
    labels:
      infra.kuid.dev/purpose: loopback
```

In the input we also use a `Node` resource that represents a device in our inventory

```yaml
apiVersion: infra.kuid.dev/v1alpha1
kind: Node
metadata:
  namespace: default
  name: kubenet.region1.us-east.node1
spec:
  node: node1
  partition: kubenet
  platformType: ixrd3
  provider: srlinux.nokia.com
  region: region1
  site: us-east
```

## starting the choreoserver

Let's start the choreo server with the -r flag. The -r flags enables some internal resources which can be used to claim IP(s), etc

```bash
choreoctl server run interface -r
```

## api resources

after starting the choreoserver, we can see the api resources used in this exercise.

```bash
choreoctl api-resources
```

When building from the interface exercise you see we have an additional config api

```bash
&{apiresources choreo.kform.dev v1alpha1 APIResources  true []}
&{asclaims as.be.kuid.dev v1alpha1 ASClaim  true []}
&{asentries as.be.kuid.dev v1alpha1 ASEntry  true []}
&{asindexes as.be.kuid.dev v1alpha1 ASIndex  true []}
&{configgenerators choreo.kform.dev v1alpha1 ConfigGenerator  false [pkg knet]}
&{configs config.sdcio.dev v1alpha1 Config ConfigList true []}
&{customresourcedefinitions apiextensions.k8s.io v1 CustomResourceDefinition  false []}
&{genidclaims genid.be.kuid.dev v1alpha1 GENIDClaim  true []}
&{genidentries genid.be.kuid.dev v1alpha1 GENIDEntry  true []}
&{genidindexes genid.be.kuid.dev v1alpha1 GENIDIndex  true []}
&{interfaces device.network.kubenet.dev v1alpha1 Interface InterfaceList true [kuid net]}
&{ipclaims ipam.be.kuid.dev v1alpha1 IPClaim  true []}
&{ipentries ipam.be.kuid.dev v1alpha1 IPEntry  true []}
&{ipindices ipam.be.kuid.dev v1alpha1 IPIndex  true []}
&{libraries choreo.kform.dev v1alpha1 Library  false [choreo]}
&{nodes infra.kuid.dev v1alpha1 Node NodeList true []}
&{reconcilers choreo.kform.dev v1alpha1 Reconciler  false [choreo]}
&{subinterfaces device.network.kubenet.dev v1alpha1 SubInterface SubInterfaceList true [kuid net]}
&{upstreamrefs choreo.kform.dev v1alpha1 UpstreamRef  false [pkg knet]}
&{vlanclaims vlan.be.kuid.dev v1alpha1 VLANClaim  true []}
&{vlanentries vlan.be.kuid.dev v1alpha1 VLANEntry  true []}
&{vlanindices vlan.be.kuid.dev v1alpha1 VLANIndex  true []}
```

## look at the business logic

There is 2 reconcilers as per the interface exercise. On top we added 2 additional reconcilers:

- `device.kubenet.dev.interfaces.config.nokiasrl`: uses a gotemplate to render the `Interface` CR to a device specifc `Config` resource

- `device.kubenet.dev.subinterfaces.config.nokiasrl`: uses a gotemplate to render the `SubInterface` CR to a device specifc `Config` resource

## running the business logic

```bash
chorectl run once
```

check if we get the proper result based on the input.

```bash
choreoctl get configs.config.sdcio.dev  
```

for each interface and subinterface we should see a config resource

```bash
Config.config.sdcio.dev/v1alpha1 kubenet.region1.us-east.node1.0.0.system
Config.config.sdcio.dev/v1alpha1 kubenet.region1.us-east.node1.0.0.system.0
```


Check the config for `Interface` output

```bash
choreoctl get configs.config.sdcio.dev kubenet.region1.us-east.node1.0.0.system -o yaml
```

In the output you can also see the owner reference referencing the `Interface` resource

```yaml
apiVersion: config.sdcio.dev/v1alpha1
kind: Config
metadata:
  creationTimestamp: "2024-10-03T16:27:55Z"
  labels:
    config.sdcio.dev/targetName: node1
    config.sdcio.dev/targetNamespace: default
  name: kubenet.region1.us-east.node1.0.0.system
  namespace: default
  ownerReferences:
  - apiVersion: device.network.kubenet.dev/v1alpha1
    controller: true
    kind: Interface
    name: kubenet.region1.us-east.node1.0.0.system
    uid: 7c9e2801-873b-4fea-81a3-79522fa0294b
  resourceVersion: "0"
  uid: d14f8c6f-fa61-4369-bfd1-a30b29197f7f
spec:
  config:
  - path: /
    value:
      interface:
      - admin-state: enable
        description: k8s-system
        name: system
  priority: 10
```

Check the config for `SubInterface` output

```bash
choreoctl get configs.config.sdcio.dev kubenet.region1.us-east.node1.0.0.system.0 -o yaml
```

In the output you can also see the owner reference referencing the `SubInterface` resource

```yaml
apiVersion: config.sdcio.dev/v1alpha1
kind: Config
metadata:
  creationTimestamp: "2024-10-03T17:14:30Z"
  generation: 2
  labels:
    config.sdcio.dev/targetName: node1
    config.sdcio.dev/targetNamespace: default
  name: kubenet.region1.us-east.node1.0.0.system.0
  namespace: default
  ownerReferences:
  - apiVersion: device.network.kubenet.dev/v1alpha1
    controller: true
    kind: SubInterface
    name: kubenet.region1.us-east.node1.0.0.system.0
    uid: 5b685b88-ca7a-44ae-a3f5-035ea705c656
  resourceVersion: "2"
  uid: 01670f50-bb50-4d08-a0db-1234f59f6356
spec:
  config:
  - path: /
    value:
      interface:
      - name: system
        subinterface:
        - admin-state: enable
          description: k8s-system.%!d(float64=0)
          index: 0
          ipv4:
            address:
            - ip-prefix: 10.0.0.0/32
            admin-state: enable
            unnumbered:
              admin-state: disable
          type: routed
  priority: 10
```

lets check the dependency tree

```bash
choreoctl deps
```

You see that the `Node` resource got an `Interface`, `SubInterface` and `IPClaim` assigned and the IP address of the `IPClaim` is used in the `SubInterface` resource. On top ther is a `Config` child for the `Interface` and `Subinterface` resource

```bash
CustomResourceDefinition.apiextensions.k8s.io/v1 interfaces.device.network.kubenet.dev 
CustomResourceDefinition.apiextensions.k8s.io/v1 nodes.infra.kuid.dev 
CustomResourceDefinition.apiextensions.k8s.io/v1 subinterfaces.device.network.kubenet.dev 
IPIndex.ipam.be.kuid.dev/v1alpha1 kubenet.default 
+-IPClaim.ipam.be.kuid.dev/v1alpha1 kubenet.default.10.0.0.0-24 
  +-IPEntry.ipam.be.kuid.dev/v1alpha1 kubenet.default.10.0.0.0-24 
+-IPClaim.ipam.be.kuid.dev/v1alpha1 kubenet.default.1000---32 
  +-IPEntry.ipam.be.kuid.dev/v1alpha1 kubenet.default.1000---32 
Library.choreo.kform.dev/v1alpha1 api.k8s.io.object.star 
Library.choreo.kform.dev/v1alpha1 device.network.kubenet.dev.interfaces.star 
Library.choreo.kform.dev/v1alpha1 device.network.kubenet.dev.subinterfaces.star 
Library.choreo.kform.dev/v1alpha1 id.kuid.dev.ids.star 
Library.choreo.kform.dev/v1alpha1 infra.kuid.dev.nodes.star 
Library.choreo.kform.dev/v1alpha1 ipam.be.kuid.dev.ipclaims.star 
Library.choreo.kform.dev/v1alpha1 ipam.be.kuid.dev.ipindices.star 
Node.infra.kuid.dev/v1alpha1 kubenet.region1.us-east.node1 
+-Interface.device.network.kubenet.dev/v1alpha1 kubenet.region1.us-east.node1.0.0.system 
  +-Config.config.sdcio.dev/v1alpha1 kubenet.region1.us-east.node1.0.0.system 
+-IPClaim.ipam.be.kuid.dev/v1alpha1 kubenet.region1.us-east.node1.ipv4 
  +-IPEntry.ipam.be.kuid.dev/v1alpha1 kubenet.default.10.0.0.0-32 
+-SubInterface.device.network.kubenet.dev/v1alpha1 kubenet.region1.us-east.node1.0.0.system.0 
  +-Config.config.sdcio.dev/v1alpha1 kubenet.region1.us-east.node1.0.0.system.0 
Reconciler.choreo.kform.dev/v1alpha1 infra.kuid.dev.nodes.id 
Reconciler.choreo.kform.dev/v1alpha1 infra.kuid.dev.nodes.if-si 
```

## Add a node in the input

```yaml
apiVersion: infra.kuid.dev/v1alpha1
kind: Node
metadata:
  namespace: default
  name: kubenet.region1.us-east.node2
spec:
  node: node2
  partition: kubenet
  platformType: ixrd3
  provider: srlinux.nokia.com
  region: region1
  site: us-east
```

run the choreo

```bash
chorectl run once 
```

Now we should have subinterfaces for both nodes and IPClaims for both nodes

```bash
Node.infra.kuid.dev/v1alpha1 kubenet.region1.us-east.node1 
+-Interface.device.network.kubenet.dev/v1alpha1 kubenet.region1.us-east.node1.0.0.system 
  +-Config.config.sdcio.dev/v1alpha1 kubenet.region1.us-east.node1.0.0.system 
+-IPClaim.ipam.be.kuid.dev/v1alpha1 kubenet.region1.us-east.node1.ipv4 
  +-IPEntry.ipam.be.kuid.dev/v1alpha1 kubenet.default.10.0.0.0-32 
+-SubInterface.device.network.kubenet.dev/v1alpha1 kubenet.region1.us-east.node1.0.0.system.0 
  +-Config.config.sdcio.dev/v1alpha1 kubenet.region1.us-east.node1.0.0.system.0 
Node.infra.kuid.dev/v1alpha1 kubenet.region1.us-east.node2 
+-Interface.device.network.kubenet.dev/v1alpha1 kubenet.region1.us-east.node2.0.0.system 
  +-Config.config.sdcio.dev/v1alpha1 kubenet.region1.us-east.node2.0.0.system 
+-IPClaim.ipam.be.kuid.dev/v1alpha1 kubenet.region1.us-east.node2.ipv4 
  +-IPEntry.ipam.be.kuid.dev/v1alpha1 kubenet.default.10.0.0.1-32 
+-SubInterface.device.network.kubenet.dev/v1alpha1 kubenet.region1.us-east.node2.0.0.system.0 
  +-Config.config.sdcio.dev/v1alpha1 kubenet.region1.us-east.node2.0.0.system.0 
```

## Add IPv6 to the delegated IPIndex

```yaml
apiVersion: ipam.be.kuid.dev/v1alpha1
kind: IPIndex
metadata:
  name: kubenet.default
  namespace: default
spec:
  prefixes:
  - prefix: 10.0.0.0/24
    prefixType: pool
    labels:
      infra.kuid.dev/purpose: loopback
  - prefix: 1000::/32
    prefixType: pool
    labels:
      infra.kuid.dev/purpose: loopback
```

run the choreo

```bash
chorectl run once 
```

Now we have an IPv6 address for each node

```bash
Node.infra.kuid.dev/v1alpha1 kubenet.region1.us-east.node1 
+-Interface.device.network.kubenet.dev/v1alpha1 kubenet.region1.us-east.node1.0.0.system 
  +-Config.config.sdcio.dev/v1alpha1 kubenet.region1.us-east.node1.0.0.system 
+-IPClaim.ipam.be.kuid.dev/v1alpha1 kubenet.region1.us-east.node1.ipv4 
  +-IPEntry.ipam.be.kuid.dev/v1alpha1 kubenet.default.10.0.0.0-32 
+-IPClaim.ipam.be.kuid.dev/v1alpha1 kubenet.region1.us-east.node1.ipv6 
  +-IPEntry.ipam.be.kuid.dev/v1alpha1 kubenet.default.1000--1-128 
+-SubInterface.device.network.kubenet.dev/v1alpha1 kubenet.region1.us-east.node1.0.0.system.0 
  +-Config.config.sdcio.dev/v1alpha1 kubenet.region1.us-east.node1.0.0.system.0 
Node.infra.kuid.dev/v1alpha1 kubenet.region1.us-east.node2 
+-Interface.device.network.kubenet.dev/v1alpha1 kubenet.region1.us-east.node2.0.0.system 
  +-Config.config.sdcio.dev/v1alpha1 kubenet.region1.us-east.node2.0.0.system 
+-IPClaim.ipam.be.kuid.dev/v1alpha1 kubenet.region1.us-east.node2.ipv4 
  +-IPEntry.ipam.be.kuid.dev/v1alpha1 kubenet.default.10.0.0.1-32 
+-IPClaim.ipam.be.kuid.dev/v1alpha1 kubenet.region1.us-east.node2.ipv6 
  +-IPEntry.ipam.be.kuid.dev/v1alpha1 kubenet.default.1000---128 
+-SubInterface.device.network.kubenet.dev/v1alpha1 kubenet.region1.us-east.node2.0.0.system.0 
  +-Config.config.sdcio.dev/v1alpha1 kubenet.region1.us-east.node2.0.0.system.0 
```

## remove the iPv4 prefix from the IPIndex

```yaml
apiVersion: ipam.be.kuid.dev/v1alpha1
kind: IPIndex
metadata:
  name: kubenet.default
  namespace: default
spec:
  prefixes:
  - prefix: 1000::/32
    prefixType: pool
    labels:
      infra.kuid.dev/purpose: loopback
```

run the choreo

```bash
chorectl run once 
```

You see that the IPv4 address got removed from each node

```bash
Node.infra.kuid.dev/v1alpha1 kubenet.region1.us-east.node1 
+-Interface.device.network.kubenet.dev/v1alpha1 kubenet.region1.us-east.node1.0.0.system 
  +-Config.config.sdcio.dev/v1alpha1 kubenet.region1.us-east.node1.0.0.system 
+-IPClaim.ipam.be.kuid.dev/v1alpha1 kubenet.region1.us-east.node1.ipv6 
  +-IPEntry.ipam.be.kuid.dev/v1alpha1 kubenet.default.1000--1-128 
+-SubInterface.device.network.kubenet.dev/v1alpha1 kubenet.region1.us-east.node1.0.0.system.0 
  +-Config.config.sdcio.dev/v1alpha1 kubenet.region1.us-east.node1.0.0.system.0 
Node.infra.kuid.dev/v1alpha1 kubenet.region1.us-east.node2 
+-Interface.device.network.kubenet.dev/v1alpha1 kubenet.region1.us-east.node2.0.0.system 
  +-Config.config.sdcio.dev/v1alpha1 kubenet.region1.us-east.node2.0.0.system 
+-IPClaim.ipam.be.kuid.dev/v1alpha1 kubenet.region1.us-east.node2.ipv6 
  +-IPEntry.ipam.be.kuid.dev/v1alpha1 kubenet.default.1000---128 
+-SubInterface.device.network.kubenet.dev/v1alpha1 kubenet.region1.us-east.node2.0.0.system.0 
  +-Config.config.sdcio.dev/v1alpha1 kubenet.region1.us-east.node2.0.0.system.0 
```

## remove a node from the inventory

e.g. delete the node1 input from the input files e.g.

run the choreo

```bash
chorectl run once 
```

You can see the `IPClaim`, `Interface` and `SubInterface` resource for node1 get removed from the system

```bash
Node.infra.kuid.dev/v1alpha1 kubenet.region1.us-east.node2 
+-Interface.device.network.kubenet.dev/v1alpha1 kubenet.region1.us-east.node2.0.0.system 
  +-Config.config.sdcio.dev/v1alpha1 kubenet.region1.us-east.node2.0.0.system 
+-IPClaim.ipam.be.kuid.dev/v1alpha1 kubenet.region1.us-east.node2.ipv6 
  +-IPEntry.ipam.be.kuid.dev/v1alpha1 kubenet.default.1000---128 
+-SubInterface.device.network.kubenet.dev/v1alpha1 kubenet.region1.us-east.node2.0.0.system.0 
  +-Config.config.sdcio.dev/v1alpha1 kubenet.region1.us-east.node2.0.0.system.0 
```

Play around with other scenario's
