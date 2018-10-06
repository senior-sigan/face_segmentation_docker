TAG = sigan/face-segmentation:latest

build: Dockerfile
	nvidia-docker build --tag $(TAG) --rm .

run:
	nvidia-docker run -it $(TAG) bash

push:
ifdef REGISTRY
	docker tag $(TAG) $(REGISTRY)/$(TAG)
	docker push $(REGISTRY)/$(TAG)
else
	docker push $(TAG)
endif

purge:
	docker ps -a -q | xargs docker rm -f --volumes || true
	docker images -q | xargs docker rmi -f