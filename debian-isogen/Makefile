BUILD_DIR = build_dir
IMAGE_ID = none
.PHONY: test
test: $(BUILD_DIR)/output-metadata.yaml
	echo OK

$(BUILD_DIR)/output-metadata.yaml: $(BUILD_DIR)/image_id
	cp examples/user-data $(BUILD_DIR)
	cp examples/isogen.yaml $(BUILD_DIR)
	cp examples/network-config $(BUILD_DIR)
	docker run -ti --rm  -e BUILDER_CONFIG=/config/isogen.yaml -v ${PWD}/$(BUILD_DIR)/:/config/ $(shell cat $(BUILD_DIR)/image_id)


$(BUILD_DIR)/image_id:
	mkdir -p $(BUILD_DIR)
ifeq ($(IMAGE_ID), none)
	docker build . --quiet | sed 's/^sha256://' |tee  $(BUILD_DIR)/image_id
else
	echo $(IMAGE_ID) > $(BUILD_DIR)/image_id
endif

.PHONY: clean
clean:
ifeq ($(IMAGE_ID), none)
	if [ -f $(BUILD_DIR)/image_id ]; then  docker rmi $$(cat $(BUILD_DIR)/image_id); fi
endif
	rm -rf $(BUILD_DIR)

