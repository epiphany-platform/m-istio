include $(M_RESOURCES)/templates.mk
include $(M_RESOURCES)/consts.mk
include $(M_RESOURCES)/defaults.mk

export AWS_ACCESS_KEY_ID=$(M_AWS_ACCESS_KEY)
export AWS_SECRET_ACCESS_KEY=$(M_AWS_SECRET_KEY)
export KUBECONFIG=$(M_KUBECONF_FILE_PATH)

export

#medatada method is printing static metadata information about module
metadata: guard-M_RESOURCES
	#Istio | metadata | should print component metadata
	@echo "$$M_METADATA_CONTENT"

#init method is used to initialize module configuration and check if state is providing strong (and weak) dependencies
#TODO should also validate state if strong requirements are met
init: guard-M_RESOURCES guard-M_SHARED setup ensure-state-file template-config-file template-controlplane-config-file initialize-state-file display-config-file

#plan method would get config file and environment state file and compare them and calculate what would be done o apply stage
plan: guard-M_RESOURCES guard-M_SHARED setup ensure-validate-needed-files module-plan istioctl-plan

#apply method runs module provider logic using config file
apply: guard-M_RESOURCES guard-M_SHARED setup module-plan ensure-validate-needed-files istioctl-apply update-state-after-apply

#audit method should call logic to check if remote components are in "known" state
#TODO implement validation if remote resources are as expected
audit: istioctl-analyze

destroy: guard-M_RESOURCES guard-M_SHARED ensure-validate-needed-files istioctl-destroy update-state-after-destroy

plan-destroy: guard-M_RESOURCES guard-M_SHARED ensure-validate-needed-files istioctl-plan-destroy

istioctl-plan:
	#Istio | istioctl-plan | will do a dry run of apply
	@HUB=$$(yq r $(M_CONFIG_PATH) 'istio.hub');\
	ARGS="--dry-run \
		--tag=$$(yq r $(M_CONFIG_PATH) 'istio.tag') \
		--operatorNamespace=$$(yq r $(M_CONFIG_PATH) 'istio.operator_namespace') \
		--istioNamespace=$$(yq r $(M_CONFIG_PATH) 'istio.istio_namespace') \
		--watchedNamespaces=$$(yq r $(M_CONFIG_PATH) 'istio.watched_namespaces')" ;\
	if [ $$HUB != "unknown" ]; then \
		ARGS="$$ARGS --hub=$$HUB/istio" ;\
	fi ;\
	istioctl operator init $$ARGS

istioctl-apply:
	#Istio | istioctl-apply | will run apply
	@HUB=$$(yq r $(M_CONFIG_PATH) 'istio.hub');\
	ARGS="--tag=$$(yq r $(M_CONFIG_PATH) 'istio.tag') \
		--operatorNamespace=$$(yq r $(M_CONFIG_PATH) 'istio.operator_namespace') \
		--istioNamespace=$$(yq r $(M_CONFIG_PATH) 'istio.istio_namespace') \
		--watchedNamespaces=$$(yq r $(M_CONFIG_PATH) 'istio.watched_namespaces')" ;\
	if [ $$HUB != "unknown" ]; then \
		ARGS="$$ARGS --hub=$$HUB/istio" ;\
	fi ;\
	istioctl operator init $$ARGS;
	@echo "deploying Istio controlplane";\
	kubectl apply \
		-f $(M_CONTROLPLANE_CONFIG_PATH)

istioctl-plan-destroy:
	#Istio | istioctl-plan-destroy | will do a dry run of destroy
	@kubectl delete \
		--dry-run=server \
		-f $(M_CONTROLPLANE_CONFIG_PATH)
	@OPERATOR_NAMESPACE=$$(yq r $(M_CONFIG_PATH) 'istio.operator_namespace');\
	ISTIO_NAMESPACE=$$(yq r $(M_CONFIG_PATH) 'istio.istio_namespace') ;\
	istioctl operator remove \
		--dry-run \
		--force \
		--istioNamespace=$$ISTIO_NAMESPACE \
		--operatorNamespace=$$OPERATOR_NAMESPACE
	@OPERATOR_NAMESPACE=$$(yq r $(M_CONFIG_PATH) 'istio.operator_namespace');\
	kubectl delete ns $$OPERATOR_NAMESPACE --dry-run=server

istioctl-destroy:
	#Istio | istioctl-destroy | istioctl-destroy is just about to begin ...
	@kubectl delete \
		-f $(M_CONTROLPLANE_CONFIG_PATH)
	@OPERATOR_NAMESPACE=$$(yq r $(M_CONFIG_PATH) 'istio.operator_namespace');\
	ISTIO_NAMESPACE=$$(yq r $(M_CONFIG_PATH) 'istio.istio_namespace') ;\
	istioctl operator remove \
		--force \
		--istioNamespace=$$ISTIO_NAMESPACE \
		--operatorNamespace=$$OPERATOR_NAMESPACE
	@OPERATOR_NAMESPACE=$$(yq r $(M_CONFIG_PATH) 'istio.operator_namespace');\
	kubectl delete ns $$OPERATOR_NAMESPACE

istioctl-analyze:
	#Istio | istioctl-analyze | analyse Istio deployment
	@istioctl analyze -A
	
setup: $(M_SHARED)/$(M_MODULE_SHORT)
	#Istio | setup | ensure required directories

template-config-file:
	#Istio | template-config-file | will template config file (and backup previous if exists)
	@if test -f $(M_CONFIG_PATH); then mv $(M_CONFIG_PATH) $(M_CONFIG_PATH).backup ; fi
	@echo "$$M_CONFIG_CONTENT" > $(M_CONFIG_PATH)
	#Istio | template-config-file | will replace arguments with values from state file
	@yq r $(M_STATE_PATH) '$(M_MODULE_SHORT).output[hub.value]' \
	| xargs -r yq w -i $(M_CONFIG_PATH) '.hub'
	@yq r $(M_STATE_PATH) '$(M_MODULE_SHORT).output[tag.value]' \
	| xargs -r yq w -i $(M_CONFIG_PATH) '$(M_MODULE_SHORT).tag'
	@yq r $(M_STATE_PATH) '$(M_MODULE_SHORT).output[operator_namespace.value]' \
	| xargs -r yq w -i $(M_CONFIG_PATH) '$(M_MODULE_SHORT).operator_namespace'
	@yq r $(M_STATE_PATH) '$(M_MODULE_SHORT).output[istio_namespace.value]' \
	| xargs -r yq w -i $(M_CONFIG_PATH) '$(M_MODULE_SHORT).istio_namespace'
	@yq r $(M_STATE_PATH) '$(M_MODULE_SHORT).output[watched_namespaces.value]' \
	| xargs -r yq w -i $(M_CONFIG_PATH) '$(M_MODULE_SHORT).watched_namespaces'
	@yq r $(M_STATE_PATH) '$(M_MODULE_SHORT).output[controlplane_name.value]' \
	| xargs -r yq w -i $(M_CONFIG_PATH) '$(M_MODULE_SHORT).controlplane_name'
	@yq r $(M_STATE_PATH) '$(M_MODULE_SHORT).output[controlplane_profile.value]' \
	| xargs -r yq w -i $(M_CONFIG_PATH) '$(M_MODULE_SHORT).controlplane_profile'

COMMA:= ,
EMPTY:=
SPACE:= $(empty) $(empty)
M_FIRST_WATCHED_NAMESPACES := $(firstword $(subst $(COMMA),$(SPACE),$(M_WATCHED_NAMESPACES)))
M_ALL_NAMESPACES := $(sort $(subst $(COMMA),$(SPACE),$(M_WATCHED_NAMESPACES)) $(M_ISTIO_NAMESPACE))
template-controlplane-config-file:
	#Istio | template-controlplane-config-file | will template controlplane config file
	@$(file >$(M_CONTROLPLANE_CONFIG_PATH)) $(foreach ns,$(M_ALL_NAMESPACES),$(file >>$(M_CONTROLPLANE_CONFIG_PATH),$(call M_CONFIG_NAMESPACE_CONTENT,$(ns))))
	@@HUB=$$(yq r $(M_CONFIG_PATH) 'istio.hub');\
	if [ $$HUB != "unknown" ]; then \
		echo "$$M_CONFIG_CONTROLPLANE_CUSTOMHUB_CONTENT" >> $(M_CONTROLPLANE_CONFIG_PATH);\
	else \
		echo "$$M_CONFIG_CONTROLPLANE_CONTENT" >> $(M_CONTROLPLANE_CONFIG_PATH);\
	fi

display-config-file:
	#Istio | display-config-file | config file content is:
	@cat $(M_CONFIG_PATH)

ensure-state-file: $(M_STATE_PATH)
	#Istio | ensure-state-file | checks if state file exists

ensure-config-file: $(M_CONFIG_PATH)
	#Istio | ensure-config-file | checks if state file exists

ensure-kubeconf-file: $(M_KUBECONF_FILE_PATH)
	#Istio | ensure-kubeconf-file | checks if kubeconf file exists

ensure-controlplane-deploy-file: $(M_CONTROLPLANE_CONFIG_PATH)
	#Istio | ensure-controlplane-deploy-file | checks if controlplane deployment file exists

#TODO validate if state file is correct
#TODO consider https://github.com/santhosh-tekuri/jsonschema as it's small
#For now we only validate if state is a propper YAML
validate-state:
	#Istio | validate-state | will perform state file validation
	@yq v $(M_STATE_PATH) || (echo "State file is not a valid YAML"; exit 1)

#TODO validate if config is correct
#TODO consider https://github.com/santhosh-tekuri/jsonschema as it's small
#For now we only validate if state is a propper YAML and of needed fields are at least present
validate-config:
	#Istio | validate-config | will perform config validation
	@yq v $(M_CONFIG_PATH) || (echo "Config file is not a valid YAML"; exit 1)
	@if [ "$$(yq r $(M_CONFIG_PATH) 'istio.hub')" = "" ]; then echo "istio.hub missing"; exit 1; fi
	@if [ "$$(yq r $(M_CONFIG_PATH) 'istio.tag')" = "" ]; then echo "istio.tag missing"; exit 1; fi
	@if [ "$$(yq r $(M_CONFIG_PATH) 'istio.operator_namespace')" = "" ]; then echo "istio.operator_namespace missing"; exit 1; fi
	@if [ "$$(yq r $(M_CONFIG_PATH) 'istio.istio_namespace')" = "" ]; then echo "istio.istio_namespace missing"; exit 1; fi
	@if [ "$$(yq r $(M_CONFIG_PATH) 'istio.watched_namespaces')" = "" ]; then echo "istio.watched_namespaces missing"; exit 1; fi
	@if [ "$$(yq r $(M_CONFIG_PATH) 'istio.controlplane_name')" = "" ]; then echo "istio.controlplane_name missing"; exit 1; fi
	@if [ "$$(yq r $(M_CONFIG_PATH) 'istio.controlplane_profile')" = "" ]; then echo "istio.controlplane_profile missing"; exit 1; fi

#TODO validate if controlplane deploy  file is correct
#TODO consider https://github.com/santhosh-tekuri/jsonschema as it's small
#For now we only validate if state is a propper YAML
validate-controlplane-deploy-file:
	#Istio | validate-controlplane-deploy-file | will perform state file validation
	@yq v $(M_STATE_PATH) || (echo "Controlplane deploy file is not a valid YAML"; exit 1)

ensure-validate-needed-files: ensure-state-file ensure-kubeconf-file ensure-config-file ensure-controlplane-deploy-file validate-state validate-config validate-controlplane-deploy-file

initialize-state-file:
	#Istio | initialize-state-file | will initialize state file
	@echo "$$M_STATE_INITIAL" > $(M_SHARED)/$(M_MODULE_SHORT)/$(M_MODULE_SHORT)-state.tmp
	@yq m -i -x $(M_STATE_PATH) $(M_SHARED)/$(M_MODULE_SHORT)/$(M_MODULE_SHORT)-state.tmp
	@rm $(M_SHARED)/$(M_MODULE_SHORT)/$(M_MODULE_SHORT)-state.tmp

update-state-after-apply:
	#Istio | update-state-after-apply | will update state file after apply
	@cp $(M_CONFIG_PATH) $(M_SHARED)/$(M_MODULE_SHORT)/$(M_MODULE_SHORT)-config.tmp.yml
	@yq d -i $(M_SHARED)/$(M_MODULE_SHORT)/$(M_MODULE_SHORT)-config.tmp.yml kind
	@yq m -x -i $(M_STATE_PATH) $(M_SHARED)/$(M_MODULE_SHORT)/$(M_MODULE_SHORT)-config.tmp.yml
	@yq w -i $(M_STATE_PATH) $(M_MODULE_SHORT).status applied
	@rm $(M_SHARED)/$(M_MODULE_SHORT)/$(M_MODULE_SHORT)-config.tmp.yml

update-state-after-destroy:
	#Istio | update-state-after-destroy | will clean state file after destroy
	@yq d -i $(M_STATE_PATH) '$(M_MODULE_SHORT)'
	@yq w -i $(M_STATE_PATH) $(M_MODULE_SHORT).status destroyed

#TODO check if there is state file
#TODO check if there is config
assert-init-completed:
	#Istio | assert-init-completed | will check if all initialization steps are completed

module-plan:
	#Istio | module-plan | will perform module plan
	@yq m -x $(M_STATE_PATH) $(M_CONFIG_PATH) > $(M_SHARED)/$(M_MODULE_SHORT)/$(M_MODULE_SHORT)-future-state.tmp
	@yq w -i $(M_SHARED)/$(M_MODULE_SHORT)/$(M_MODULE_SHORT)-future-state.tmp kind state
	@- yq compare $(M_STATE_PATH) $(M_SHARED)/$(M_MODULE_SHORT)/$(M_MODULE_SHORT)-future-state.tmp
	@rm $(M_SHARED)/$(M_MODULE_SHORT)/$(M_MODULE_SHORT)-future-state.tmp

guard-%:
	@if [ "${${*}}" = "" ]; then \
		echo "Environment variable $* not set"; \
		exit 1; \
	fi

$(M_STATE_PATH):
	@mkdir -p $(dir $@)
	@touch $@

$(M_SHARED)/$(M_MODULE_SHORT):
	@mkdir -p $@
