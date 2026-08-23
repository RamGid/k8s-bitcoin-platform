.PHONY: all up down verify lint test

all: up

up:
	@chmod +x scripts/*.sh
	@./scripts/up.sh

down:
	@./scripts/down.sh

verify:
	@./scripts/verify.sh

lint:
	cd terraform && terraform fmt -check && terraform validate
	helm lint charts/generic-app -f config/application-values.yaml

test: lint
	helm template test-release charts/generic-app -f config/application-values.yaml > /dev/null
	@echo "Helm template successfully rendered."
