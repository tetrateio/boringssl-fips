ARCH ?= amd64
BUILDER ?= boringssl-fips-builder:$(shell date "+%F")
NO_CACHE ?= --no-cache

# To allow overriding BoringSSL.
export BORINGSSL_VERSION ?= 853ca1ea1168dff08011e5d42d94609cc0ca2e27
export BORINGSSL_SHA256 ?= a4d069ccef6f3c7bc0c68de82b91414f05cb817494cd1ab483dcf3368883c7c2
export BORINGSSL_SOURCE ?= https://commondatastorage.googleapis.com/chromium-boringssl-fips/boringssl-$(BORINGSSL_VERSION).tar.xz

TAG ?= $(BORINGSSL_VERSION)

# build is the main target to build boringssl crypto and ssl modules.
build: builder
	$(eval CONTAINER_ID := $(shell docker create -it $(BUILDER)))
	@docker cp $(CONTAINER_ID):/boringssl/build/crypto/libcrypto.a ./libcrypto.a
	@docker cp $(CONTAINER_ID):/boringssl/build/ssl/libssl.a ./libssl.a
	@tar -cJf boringssl-fips-$(TAG)-$(ARCH).tar.xz libcrypto.a libssl.a
	@docker rm $(CONTAINER_ID)
	@docker rmi $(BUILDER)

# builder is a helper to build boringssl crypto and ssl modules inside a container.
builder:
	@docker buildx build \
		--file tools/builder.Dockerfile \
		--load \
		--tag $(BUILDER) \
		--platform linux/$(ARCH) $(NO_CACHE) .
