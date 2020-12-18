define M_METADATA_CONTENT
labels:
  version: $(M_VERSION)
  name: Istio
  short: $(M_MODULE_SHORT)
  kind: configuration
  provider: none
endef

define M_CONFIG_CONTENT
kind: $(M_MODULE_SHORT)-config
$(M_MODULE_SHORT):
  hub: $(M_HUB)
  tag: $(M_TAG)
  operator_namespace : $(M_OPERATOR_NAMESPACE)
  istio_namespace : $(M_ISTIO_NAMESPACE)
  watched_namespaces : $(M_WATCHED_NAMESPACES)
  controlplane_name : $(M_CONTROLPLANE_NAME)
  controlplane_profile : $(M_CONTROLPLANE_PROFILE)
endef

define M_STATE_INITIAL
kind: state
$(M_MODULE_SHORT):
  status: initialized
endef

define M_CONFIG_NAMESPACE_CONTENT
---
apiVersion: v1
kind: Namespace
metadata:
  name: $(1)
  labels:
    name: $(1)
endef

define M_CONFIG_CONTROLPLANE_CONTENT
---
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
metadata:
  namespace: $(M_FIRST_WATCHED_NAMESPACES)
  name: $(M_CONTROLPLANE_NAME)
spec:
  profile: $(M_CONTROLPLANE_PROFILE)
  values:
    global:
       istioNamespace: $(M_ISTIO_NAMESPACE)
endef
