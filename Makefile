build:
	docker build -t erighetto/drupal-dev:latest .

run:
	docker run --rm -it \
	-e APPLICATION_PATH='/app' \
	-e WEB_DOCUMENT_ROOT='/app' \
	-v "${PWD}/index.php:/app/index.php" -p 8080:80 -p 8443:443 erighetto/drupal-dev