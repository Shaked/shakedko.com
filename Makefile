.PHONY: help serve build clean open stop logs shell down check-content check-feeds

# Default target
help:
	@echo "Available commands:"
	@echo "  make serve      - Start Jekyll server in Docker (http://localhost:4000)"
	@echo "  make build      - Build the site in Docker"
	@echo "  make clean      - Clean generated files"
	@echo "  make open       - Open the site in your browser"
	@echo "  make stop       - Stop the Docker container"
	@echo "  make down       - Stop and remove containers"
	@echo "  make logs       - Show container logs"
	@echo "  make shell      - Open a shell in the container"
	@echo "  make check-content - Validate X-post language routing"
	@echo "  make check-feeds - Validate language-specific Atom feeds"

# Start the Jekyll server with Docker Compose
serve:
	@echo "Starting Jekyll server in Docker..."
	@echo "Site will be available at http://localhost:4000"
	docker-compose up

# Start in detached mode (background)
serve-bg:
	@echo "Starting Jekyll server in Docker (background)..."
	docker-compose up -d
	@echo "Site available at http://localhost:4000"
	@echo "Run 'make logs' to view logs"
	@echo "Run 'make stop' to stop the server"

# Build the site using Docker
build:
	docker-compose run --rm jekyll jekyll build

# Validate X-post collection and language metadata.
check-content:
	scripts/check-x-post-language.sh
	scripts/test-check-x-post-language.sh
	scripts/test-check-x-embed-cards.sh

check-feeds:
	scripts/check-language-feeds.sh
	scripts/test-check-language-feeds.sh

# Clean generated files
clean:
	docker-compose run --rm jekyll jekyll clean
	@echo "Cleaned _site directory"

# Open the site in browser
open:
	open http://localhost:4000

# Stop the container
stop:
	docker-compose stop

# Stop and remove containers
down:
	docker-compose down

# View logs
logs:
	docker-compose logs -f

# Open shell in container
shell:
	docker-compose run --rm jekyll /bin/sh
