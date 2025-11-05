.PHONY: bootstrap
bootstrap:
	@cd infra/bootstrap && terraform init && \
		terraform apply -auto-approve \
			-var org=jasoncorrea56 -var project=csfundamentals -var env=prod -var region=us-west-2

.PHONY: state-init
state-init:
	@cd infra/live/prod && terraform init -backend-config=backend.hcl -reconfigure

.PHONY: plan
plan:
	@cd infra/live/prod && terraform plan

.PHONY: apply
apply:
	@cd infra/live/prod && terraform apply -auto-approve
