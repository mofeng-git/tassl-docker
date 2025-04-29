# 镜像名称和标签
IMAGE_NAME ?= silentwind0/tassl-nginx
IMAGE_TAG ?= latest

# 镜像仓库地址（如需推送到私有仓库，请修改此变量）
REGISTRY ?= 

# 要构建的架构
PLATFORMS ?= linux/amd64,linux/arm64,linux/arm/v7

# 完整的镜像名称
FULL_IMAGE_NAME = $(if $(REGISTRY),$(REGISTRY)/$(IMAGE_NAME),$(IMAGE_NAME)):$(IMAGE_TAG)

# 默认目标
.PHONY: all
all: build

# 创建并使用buildx构建器
.PHONY: buildx-setup
buildx-setup:
	docker buildx create --name multi-arch-builder --use || true
	docker buildx inspect --bootstrap

# 构建多架构镜像并推送到仓库
.PHONY: buildx-build-push
buildx-build-push: buildx-setup
	docker buildx build --platform $(PLATFORMS) \
		-t $(FULL_IMAGE_NAME) \
		--push .

# 构建多架构镜像但不推送
.PHONY: buildx-build
buildx-build: buildx-setup
	docker buildx build --platform $(PLATFORMS) \
		-t $(FULL_IMAGE_NAME) \
		.

# 常规构建（单一架构）
.PHONY: build
build:
	docker build -t $(FULL_IMAGE_NAME) .

# 推送镜像到仓库
.PHONY: push
push:
	docker push $(FULL_IMAGE_NAME)

# 清理
.PHONY: clean
clean:
	docker buildx rm multi-arch-builder || true

# 帮助信息
.PHONY: help
help:
	@echo "多架构Docker镜像构建Makefile"
	@echo ""
	@echo "用法:"
	@echo "  make build                - 构建单架构镜像（当前系统架构）"
	@echo "  make buildx-setup         - 创建并设置buildx构建器"
	@echo "  make buildx-build         - 构建多架构镜像但不推送"
	@echo "  make buildx-build-push    - 构建多架构镜像并推送到仓库"
	@echo "  make push                 - 推送镜像到仓库"
	@echo "  make clean                - 清理buildx构建器"
	@echo ""
	@echo "环境变量:"
	@echo "  IMAGE_NAME  - 镜像名称 (默认: tassl-nginx)"
	@echo "  IMAGE_TAG   - 镜像标签 (默认: latest)"
	@echo "  REGISTRY    - 镜像仓库地址 (默认: 空)"
	@echo "  PLATFORMS   - 构建架构 (默认: linux/amd64,linux/arm64,linux/arm/v7)"
	@echo ""
	@echo "示例:"
	@echo "  IMAGE_NAME=custom-tassl IMAGE_TAG=v1.0 make buildx-build-push" 