# choreo Interface example

The goal of this exercise is to show, how you create an abstract `Interface` and `SubInterface` resource for a `Node`. We defined these resources as CRD(s) already in the crd folder 

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

```bash
&{apiresources choreo.kform.dev v1alpha1 APIResources  true []}
&{asclaims as.be.kuid.dev v1alpha1 ASClaim  true []}
&{asentries as.be.kuid.dev v1alpha1 ASEntry  true []}
&{asindexes as.be.kuid.dev v1alpha1 ASIndex  true []}
&{configgenerators choreo.kform.dev v1alpha1 ConfigGenerator  false [pkg knet]}
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

There is 2 reconcilers:

- `infra.kuid.dev.nodes.id reconciler`: claims IP addresses for each node in the system based on the address families that were delegated to us by the `IPIndex`. The `IPClaim` resource is used to perform the IP allocation

- `infra.kuid.dev.nodes.if-si reconciler`: creates a `Interface` and `Subinterface` resource with the claimed IP if the IP claim was successfull (IPClaim ready condition).

Both reconcilers have also delete logic

## running the business logic

```bash
chorectl run once
```

check if we get the proper result based on the input.

```bash
choreoctl get subinterfaces.device.network.kubenet.dev -o yaml
```


SubInterface output

```yaml
apiVersion: device.network.kubenet.dev/v1alpha1
items:
- apiVersion: device.network.kubenet.dev/v1alpha1
  kind: SubInterface
  metadata:
    creationTimestamp: "2024-10-03T07:04:39Z"
    name: kubenet.region1.us-east.node1.0.0.system.0
    namespace: default
    ownerReferences:
    - apiVersion: infra.kuid.dev/v1alpha1
      controller: true
      kind: Node
      name: kubenet.region1.us-east.node1
      uid: 7b96591b-452e-458d-a8f5-ea26147c8b67
    resourceVersion: "0"
    uid: fb5b3aad-98f5-40e4-8ced-605e182111e7
  spec:
    endpoint: 0
    id: 0
    ipv4:
      addresses:
      - 10.0.0.0/32
    name: system
    node: node1
    partition: kubenet
    port: 0
    region: region1
    site: us-east
    type: routed
kind: SubInterfaceList
```

lets check the dependency tree

```bash
choreoctl deps
```

You see that the `Node` resource got an `Interface`, `SubInterface` and `IPClaim` assigned and the IP address of the `IPClaim` is used in the `SubInterface` resource.

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
+-IPClaim.ipam.be.kuid.dev/v1alpha1 kubenet.region1.us-east.node1.ipv4 
  +-IPEntry.ipam.be.kuid.dev/v1alpha1 kubenet.default.10.0.0.0-32 
+-SubInterface.device.network.kubenet.dev/v1alpha1 kubenet.region1.us-east.node1.0.0.system.0 
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
+-IPClaim.ipam.be.kuid.dev/v1alpha1 kubenet.region1.us-east.node1.ipv4 
  +-IPEntry.ipam.be.kuid.dev/v1alpha1 kubenet.default.10.0.0.0-32 
+-SubInterface.device.network.kubenet.dev/v1alpha1 kubenet.region1.us-east.node1.0.0.system.0 
Node.infra.kuid.dev/v1alpha1 kubenet.region1.us-east.node2 
+-Interface.device.network.kubenet.dev/v1alpha1 kubenet.region1.us-east.node2.0.0.system 
+-IPClaim.ipam.be.kuid.dev/v1alpha1 kubenet.region1.us-east.node2.ipv4 
  +-IPEntry.ipam.be.kuid.dev/v1alpha1 kubenet.default.10.0.0.1-32 
+-SubInterface.device.network.kubenet.dev/v1alpha1 kubenet.region1.us-east.node2.0.0.system.0 
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
+-IPClaim.ipam.be.kuid.dev/v1alpha1 kubenet.region1.us-east.node1.ipv4 
  +-IPEntry.ipam.be.kuid.dev/v1alpha1 kubenet.default.10.0.0.0-32 
+-IPClaim.ipam.be.kuid.dev/v1alpha1 kubenet.region1.us-east.node1.ipv6 
  +-IPEntry.ipam.be.kuid.dev/v1alpha1 kubenet.default.1000---128 
+-SubInterface.device.network.kubenet.dev/v1alpha1 kubenet.region1.us-east.node1.0.0.system.0 
Node.infra.kuid.dev/v1alpha1 kubenet.region1.us-east.node2 
+-Interface.device.network.kubenet.dev/v1alpha1 kubenet.region1.us-east.node2.0.0.system 
+-IPClaim.ipam.be.kuid.dev/v1alpha1 kubenet.region1.us-east.node2.ipv4 
  +-IPEntry.ipam.be.kuid.dev/v1alpha1 kubenet.default.10.0.0.1-32 
+-IPClaim.ipam.be.kuid.dev/v1alpha1 kubenet.region1.us-east.node2.ipv6 
  +-IPEntry.ipam.be.kuid.dev/v1alpha1 kubenet.default.1000--1-128 
+-SubInterface.device.network.kubenet.dev/v1alpha1 kubenet.region1.us-east.node2.0.0.system.0 
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
+-IPClaim.ipam.be.kuid.dev/v1alpha1 kubenet.region1.us-east.node1.ipv6 
  +-IPEntry.ipam.be.kuid.dev/v1alpha1 kubenet.default.1000---128 
+-SubInterface.device.network.kubenet.dev/v1alpha1 kubenet.region1.us-east.node1.0.0.system.0 
Node.infra.kuid.dev/v1alpha1 kubenet.region1.us-east.node2 
+-Interface.device.network.kubenet.dev/v1alpha1 kubenet.region1.us-east.node2.0.0.system 
+-IPClaim.ipam.be.kuid.dev/v1alpha1 kubenet.region1.us-east.node2.ipv6 
  +-IPEntry.ipam.be.kuid.dev/v1alpha1 kubenet.default.1000--1-128 
+-SubInterface.device.network.kubenet.dev/v1alpha1 kubenet.region1.us-east.node2.0.0.system.0 
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
+-IPClaim.ipam.be.kuid.dev/v1alpha1 kubenet.region1.us-east.node2.ipv6 
  +-IPEntry.ipam.be.kuid.dev/v1alpha1 kubenet.default.1000--1-128 
+-SubInterface.device.network.kubenet.dev/v1alpha1 kubenet.region1.us-east.node2.0.0.system.0 
```

Play around with other scenario's
