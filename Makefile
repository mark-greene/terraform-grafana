.ONESHELL:
.PHONEY: help set-env init update plan plan-destroy show graph apply output state-init state-update state-plan state-plan-destroy state-apply state-destroy

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

set-env:
	@if [ -z $(ENVIRONMENT) ]; then\
		 echo "ENVIRONMENT was not set. Valid environments are [dev]"; exit 10;\
	 fi

state-init: set-env
	@cd ./state
	@if [ ! -f variables.tf ]; then\
		ln -s ../variables/variables.tf .;\
	fi
	@terraform init -backend-config=../variables/environments/$(ENVIRONMENT)/backend.config

state-update: state-init  ## Gets any modules / updates for Remote State
	@cd ./state
	@terraform get -update=true 1>/dev/null

state-plan: state-update ## Runs a plan to see what will be applied for Remote State
	@cd ./state
	@terraform plan -input=false -refresh=true -module-depth=-1\
	 								-var-file=../variables/environments/$(ENVIRONMENT)/terraform.tfvars\
									-var-file=../variables/environments/$(ENVIRONMENT)/backend.config

state-apply: state-update ## Apply changes for Remote State
	@cd ./state
	@terraform apply -input=true -refresh=true\
	 								-var-file=../variables/environments/$(ENVIRONMENT)/terraform.tfvars\
									-var-file=../variables/environments/$(ENVIRONMENT)/backend.config

state-plan-destroy: state-update ## Runs a plan to show what will be destroyed for Remote State
	@cd ./state
	@terraform plan -input=false -refresh=true -module-depth=-1 -destroy\
	 								-var-file=../variables/environments/$(ENVIRONMENT)/terraform.tfvars\
									-var-file=../variables/environments/$(ENVIRONMENT)/backend.config

state-destroy: state-update ## DANGER! Destroys Remote State
	@cd ./state
	@terraform destroy\
	 								-var-file=../variables/environments/$(ENVIRONMENT)/terraform.tfvars\
									-var-file=../variables/environments/$(ENVIRONMENT)/backend.config


init: set-env
	@cd ./terraform
	@if [ ! -h variables.tf ]; then\
		ln -s ../variables/variables.tf .;\
	fi
	@terraform init -backend-config=../variables/environments/$(ENVIRONMENT)/backend.config

update: ## Gets a newer version of the state
	@cd ./terraform
	@terraform get -update=true 1>/dev/null

plan: init update ## Runs a plan to show proposed changes.
	@cd ./terraform
	@terraform plan -input=false -refresh=true -module-depth=-1\
	 								-var-file=../variables/environments/$(ENVIRONMENT)/terraform.tfvars\
									-var-file=../variables/environments/$(ENVIRONMENT)/backend.config

apply: init update ## DANGER! Runs changes against your environment
	@cd ./terraform
	@terraform apply -input=true -refresh=true\
	 								-var-file=../variables/environments/$(ENVIRONMENT)/terraform.tfvars\
									-var-file=../variables/environments/$(ENVIRONMENT)/backend.config

plan-destroy: init update ## Runs a plan to show what will be destroyed
	@cd ./terraform
	@terraform plan -input=false -refresh=true -module-depth=-1 -destroy\
	 								-var-file=../variables/environments/$(ENVIRONMENT)/terraform.tfvars\
									-var-file=../variables/environments/$(ENVIRONMENT)/backend.config

destroy: init update ## DANGER! Destroys a set of resources
	@cd ./terraform
	@terraform destroy\
	 								-var-file=../variables/environments/$(ENVIRONMENT)/terraform.tfvars\
									-var-file=../variables/environments/$(ENVIRONMENT)/backend.config

destroy-target: init update ## Specifically choose a resource to destroy
	@cd ./terraform
	@echo "Specifically destroy a piece of Terraform data"
	@echo "Example: module.rds.aws_route53_record.rds-master"
	@read -p "Destroy this: " DATA &&\
		terraform destroy\
		 								-var-file=../variables/environments/$(ENVIRONMENT)/terraform.tfvars\
										-var-file=../variables/environments/$(ENVIRONMENT)/backend.config -target=$$DATA

output: init update
	@cd ./terraform
	@if [ -z $(MODULE) ]; then\
		terraform output;\
	 else\
		terraform output -module=$(MODULE);\
	 fi

show: init
	@cd ./terraform
	@terraform show -module-depth=-1

graph: ## Creates a graph of the resources that Terraform is aware of
	@cd ./terraform
	@rm -f graph.png
	@terraform graph -draw-cycles -module-depth=-1 | dot -Tpng > graph.png
	@open graph.png
