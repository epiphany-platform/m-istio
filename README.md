# m-istio

Epiphany Module: Istio

Istio module is reponsible for deploying [Istio](https://istio.io/) on top of [(Amazon EKS)](https://aws.amazon.com/eks/) or [(Azure AKS)](https://docs.microsoft.com/en-us/azure/aks/) managed Kubernetes services deployed with Epiphany modules:

- [AWS Kubernetes Service](https://github.com/epiphany-platform/m-aws-kubernetes-service#run-module)
- [Azure Kubernetes Servicee](https://github.com/epiphany-platform/m-azure-kubernetes-service#run-module)

Istio is an open source platform which allows you to run a service mesh for distributed microservice architecture. It allows to connect, manage and run secure connections between microservices and brings a lot of features such as load balancing, monitoring and service-to-service authentication without any changes in service code.

# Basic usage

## Build image

In main directory run:

  ```shell
  make build
  ```

or directly using Docker:

  ```shell
  cd m-istio/
  docker build --tag epiphanyplatform/istio:latest .
  ```

## Run module

This module requires that you to already have a deployed EKS or AKS cluster using the following modules/instructions:

- [AWS Kubernetes Service](https://github.com/epiphany-platform/m-aws-kubernetes-service#run-module)
- [Azure Kubernetes Service](https://github.com/epiphany-platform/m-azure-kubernetes-service#run-module)

**Note : On AWS EKS make sure to have at least ```t.medium``` as node size**

At this stage you should have already /tmp/shared directory with your ssh-keys, module data from the AKS/EKS deployments and the kubeconf file.

* Initialize the Istio module:

  ```shell
  docker run --rm -v /tmp/shared:/shared -t epiphanyplatform/istio:latest init
  ```

  This commad will create configuration file of AwsKS module in /tmp/shared/istio/istio-config.yml. You can investigate what is stored in that file.
  Available parameters are listed in the [inputs](docs/INPUTS.adoc) document.

* Plan and apply Istio module:

**Note : The ```M_AWS_ACCESS_KEY``` and ```M_AWS_SECRET_KEY``` environment variables are only needed for EKS**

  ```shell
  docker run --rm -v /tmp/shared:/shared -t epiphanyplatform/istio:latest plan M_AWS_ACCESS_KEY="access key id" M_AWS_SECRET_KEY="access key secret"
  docker run --rm -v /tmp/shared:/shared -t epiphanyplatform/istio:latest apply M_AWS_ACCESS_KEY="access key id" M_AWS_SECRET_KEY="access key secret"
  ```
  Running those commands should install the Istio operator on the cluster and deploy the Istio control plane with the given specifications.

## Run module with provided examples

### EKS

* Prepare your own variables in vars.mk file to use in the building process. Sample file (examples/basic_flow_eks/vars.mk.sample):

  ```shell
  AWS_ACCESS_KEY_ID = "access key id"
  AWS_ACCESS_KEY_SECRET = "access key secret"
  ```

* Create environment

  ```shell
  cd examples/basic_flow_eks
  make apply
  ```

  This will use the [AWS Basic Infrastructure](https://github.com/epiphany-platform/m-aws-basic-infrastructure) and [AWS Kubernetes Service](https://github.com/epiphany-platform/m-aws-kubernetes-service) modules to deploy an EKS cluster using the and then deploy Istio on top of it.

* Destroy environment

  ```shell
  cd examples/basic_flow_eks
  make destroy
  ```

  This will remove Istio from the EKS cluster followed by destroying the cluster and basic infrastructure.

### AKS

* Prepare your own variables in vars.mk file to use in the building process. Sample file (examples/basic_flow_aks/vars.mk.sample):

  ```shell
  ARM_CLIENT_ID ?= "appId field"
  ARM_CLIENT_SECRET ?= "password field"
  ARM_SUBSCRIPTION_ID ?= "id field"
  ARM_TENANT_ID ?= "tenant field"
  ```

* Create environment

  ```shell
  cd examples/basic_flow_aks
  make apply
  ```

  This will use the [Azure Basic Infrastructure](https://github.com/epiphany-platform/m-azure-basic-infrastructure) and [Azure Kubernetes Service](https://github.com/epiphany-platform/m-azure-kubernetes-service) modules to deploy an AKS cluster using the and then deploy Istio on top of it.

* Destroy environment

  ```shell
  cd examples/basic_flow_aks
  make destroy
  ```

  This will remove Istio from the AKS cluster followed by destroying the cluster and basic infrastructure.

## How to set up service mesh for an application

The default Istio installation use automcatic sidecar injection. You need to label the namespace where application will be hosted:

```bash
kubectl label namespace default istio-injection=enabled
```

Once the proper namespaces are labeled and Istio is deployed, you can deploy your applications or restart existing ones.

You may need to make an application accessible from outside of your Kubernetes cluster. An Istio Gateway which was deployed using default profile is used for this purpose. Define the ingress gateway deploying gateway and virtual service specification. The gateway specification describes the L4-L6 properties of a load balancer and the virtual service specification describes the L7 properties of a load balancer.

Example of the gateway and virtual service specification (You have to adapt the entire specification to the application):

[Gateway](https://istio.io/latest/docs/reference/config/networking/gateway/):

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: httpbin-gateway
spec:
  selector:
    istio: ingressgateway # use Istio default gateway implementation
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - "httpbin.example.com"
```

[Virtual Service](https://istio.io/latest/docs/reference/config/networking/virtual-service/):

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: httpbin
spec:
  hosts:
  - "httpbin.example.com"
  gateways:
  - httpbin-gateway
  http:
  - match:
    - uri:
        prefix: /status
    - uri:
        prefix: /delay
    route:
    - destination:
        port:
          number: 8000
        host: httpbin
```

## Release module

  ```shell
  make release
  ```

or if you want to set different version number:

  ```shell
  make release VERSION=number_of_your_choice
  ```

## Module dependencies

| Component                       | Version | Repo/Website                                                                                                | License                                                           |
| ------------------------------- | ------- | ----------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------- |
| Make                            | 4.3     | https://www.gnu.org/software/make/                                                                          | [GNU General Public License](https://www.gnu.org/licenses/gpl-3.0.html) |
| yq                              | 3.3.4   | https://github.com/mikefarah/yq/                                                                            | [MIT License](https://github.com/mikefarah/yq/blob/master/LICENSE) |
| Istioctl                        | 1.8.1   | https://github.com/istio/istio                                                                              | [Apache License 2.0](https://github.com/istio/istio/blob/master/LICENSE) |
| Kubectl                         | 1.18.8  | https://github.com/kubernetes/                                                                              | [Apache License 2.0](https://github.com/kubernetes/kubectl/blob/master/LICENSE) |
