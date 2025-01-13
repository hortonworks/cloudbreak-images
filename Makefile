show-image-name:
	./make.sh show-image-name

build-aws-centos7-base:
	./make.sh build-aws-centos7-base

build-aws-centos7:
	./make.sh build-aws-centos7

build-aws-redhat8:
	./make.sh build-aws-redhat8

build-azure-redhat8:
	./make.sh build-azure-redhat8

build-gc-redhat8:
	./make.sh build-gc-redhat8

copy-aws-images:
	./make.sh copy-aws-images

build-aws-gov-redhat8:
	./make.sh build-aws-gov-redhat8

copy-aws-gov-images:
	./make.sh copy-aws-gov-images

build-gc-tar-file:
	./make.sh build-gc-tar-file

build-gc-centos7:
	./make.sh build-gc-centos7

build-azure-centos7:
	./make.sh build-azure-centos7

build-azure-redhat7:
	./make.sh build-azure-redhat7

generate-aws-centos7-changelog:
	./make.sh generate-aws-centos7-changelog

generate-aws-redhat8-changelog:
	./make.sh generate-aws-redhat8-changelog

generate-azure-centos7-changelog:
	./make.sh generate-azure-centos7-changelog

generate-azure-redhat8-changelog:
	./make.sh generate-azure-redhat8-changelog

generate-gc-centos7-changelog:
	./make.sh generate-gc-centos7-changelog

generate-gc-redhat8-changelog:
	./make.sh generate-gc-redhat8-changelog

get-azure-storage-accounts:
	./make.sh get-azure-storage-accounts

copy-azure-images:
	./make.sh copy-azure-images

docker-build-centos79:
	./make.sh docker-build-centos79

docker-build-redhat88:
	./make.sh docker-build-redhat88

docker-build-redhat8:
	./make.sh docker-build-redhat8

docker-build-yarn-loadbalancer:
	./make.sh docker-build-yarn-loadbalancer

docker-build:
	./make.sh docker-build

push-docker-image-to-hwx-registry:
	./make.sh push-docker-image-to-hwx-registry

build-in-docker:
	./make.sh build-in-docker

cleanup-metadata-repo:
	./make.sh cleanup-metadata-repo

push-to-metadata-repo:
	./make.sh push-to-metadata-repo

upload-package-list:
	./make.sh upload-package-list

copy-manifest-to-s3-bucket:
	./make.sh copy-manifest-to-s3-bucket

copy-changelog-to-s3-bucket:
	./make.sh copy-changelog-to-s3-bucket

generate-last-metadata-url-file:
	./make.sh generate-last-metadata-url-file

generate-image-properties:
	./make.sh generate-image-properties

check-image-regions:
	./make.sh check-image-regions
