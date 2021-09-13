
build:
	docker build . -t acl2s-package:latest
	$(eval TMP_CONTAINER := $(shell docker create acl2s-package:latest))
	docker cp $(TMP_CONTAINER):/opt/acl2s.deb .
	docker rm -f $(TMP_CONTAINER)
