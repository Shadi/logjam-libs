.PHONY: install install-usr-local install-opt-logjam clean

install: install-usr-local

install-usr-local:
	./bin/install-libs

install-opt-logjam:
	./bin/install-libs --prefix=/opt/logjam

clean:
	rm -rf builds/repos/*
	docker ps -a | awk '/Exited/ {print $$1;}' | xargs docker rm
	docker images | awk '/none|fpm-(fry|dockery)/ {print $$3;}' | xargs docker rmi

CONTAINERS:=container-bionic container-xenial container-bionic-usr-local container-xenial-usr-local
.PHONY: containers $(CONTAINERS)

containers: $(CONTAINERS)

container-bionic:
	docker build -t "stkaes/logjam-libs:bionic-latest" -f Dockerfile.bionic --build-arg prefix=/opt/logjam bin
container-xenial:
	docker build -t "stkaes/logjam-libs:xenial-latest" -f Dockerfile.xenial --build-arg prefix=/opt/logjam bin
container-bionic-usr-local:
	docker build -t "stkaes/logjam-libs:bionic-usr-local-latest" -f Dockerfile.bionic --build-arg prefix=/usr/local bin
container-xenial-usr-local:
	docker build -t "stkaes/logjam-libs:xenial-usr-local-latest" -f Dockerfile.xenial --build-arg prefix=/usr/local bin

TAG ?= latest
VERSION ?= $(shell ./bin/version)

RELEASE:=release-bionic release-xenial release-bionic-usr-local release-xenial-usr-local
.PHONY: release $(RELEASE)

release: $(RELEASE)

release-bionic:
	$(MAKE) $(MFLAGS) tag-bionic push-bionic TAG=$(VERSION)
release-xenial:
	$(MAKE) $(MFLAGS) tag-xenial push-xenial TAG=$(VERSION)
release-bionic-usr-local:
	$(MAKE) $(MFLAGS) tag-bionic-usr-local push-bionic-usr-local TAG=$(VERSION)
release-xenial-usr-local:
	$(MAKE) $(MFLAGS) tag-xenial-usr-local push-xenial-usr-local TAG=$(VERSION)

TAGS:=tag-bionic tag-xenial tag-bionic-usr-local tag-xenial-usr-local
.PHONY: tag $(TAGS)

tag: $(TAGS)

tag-bionic:
	docker tag "stkaes/logjam-libs:bionic-latest" "stkaes/logjam-libs:bionic-$(TAG)"
tag-xenial:
	docker tag "stkaes/logjam-libs:xenial-latest" "stkaes/logjam-libs:xenial-$(TAG)"
tag-bionic-usr-local:
	docker tag "stkaes/logjam-libs:bionic-usr-local-latest" "stkaes/logjam-libs:bionic-usr-local-$(TAG)"
tag-xenial-usr-local:
	docker tag "stkaes/logjam-libs:xenial-usr-local-latest" "stkaes/logjam-libs:xenial-usr-local-$(TAG)"


PUSHES:=push-bionic push-xenial push-bionic-usr-local push-xenial-usr-local
.PHONY: push $(PUSHES)

push: $(PUSHES)

push-bionic:
	docker push "stkaes/logjam-libs:bionic-$(TAG)"
push-xenial:
	docker push "stkaes/logjam-libs:xenial-$(TAG)"
push-bionic-usr-local:
	docker push "stkaes/logjam-libs:bionic-usr-local-$(TAG)"
push-xenial-usr-local:
	docker push "stkaes/logjam-libs:xenial-usr-local-$(TAG)"


PACKAGES:=package-bionic package-bionic-usr-local package-xenial package-xenial-usr-local
.PHONY: packages $(PACKAGES)

packages: $(PACKAGES)

package-bionic:
	LOGJAM_PREFIX=/opt/logjam bundle exec fpm-fry cook --update=always stkaes/logjam-libs:bionic-latest build_libs.rb
	mkdir -p packages/ubuntu/bionic && mv *.deb packages/ubuntu/bionic
package-xenial:
	LOGJAM_PREFIX=/opt/logjam bundle exec fpm-fry cook --update=always stkaes/logjam-libs:xenial-latest build_libs.rb
	mkdir -p packages/ubuntu/xenial && mv *.deb packages/ubuntu/xenial
package-bionic-usr-local:
	LOGJAM_PREFIX=/usr/local bundle exec fpm-fry cook --update=always stkaes/logjam-libs:bionic-usr-local-latest build_libs.rb
	mkdir -p packages/ubuntu/bionic && mv *.deb packages/ubuntu/bionic
package-xenial-usr-local:
	LOGJAM_PREFIX=/usr/local bundle exec fpm-fry cook --update=always stkaes/logjam-libs:xenial-usr-local-latest build_libs.rb
	mkdir -p packages/ubuntu/xenial && mv *.deb packages/ubuntu/xenial


LOGJAM_PACKAGE_HOST:=railsexpress.de
LOGJAM_PACKAGE_USER:=uploader

.PHONY: publish publish-bionic publish-xenial
publish: publish-bionic publish-xenial

publish-bionic:
	rsync -vrlptDz -e "ssh -l $(LOGJAM_PACKAGE_USER)" packages/ubuntu/bionic/* $(LOGJAM_PACKAGE_HOST):/var/www/packages/ubuntu/bionic/

publish-xenial:
	rsync -vrlptDz -e "ssh -l $(LOGJAM_PACKAGE_USER)" packages/ubuntu/xenial/* $(LOGJAM_PACKAGE_HOST):/var/www/packages/ubuntu/xenial/

.PHONY: all
all: containers tag push release packages publish
