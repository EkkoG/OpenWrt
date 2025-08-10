#!/usr/bin/env pwsh

param(
    [string]$Image,
    [string]$Profile,
    [string]$Output = "./bin",
    [string]$CustomModules = "./custom_modules",
    [string]$Mirror = "mirrors.pku.edu.cn",
    [switch]$WithPull,
    [switch]$RmFirst,
    [switch]$UseMirror,
    [switch]$Help
)

function Show-Usage {
    Write-Host "--image: specify imagebuilder docker image, find it in https://hub.docker.com/r/openwrt/imagebuilder/tags or https://hub.docker.com/r/immortalwrt/imagebuilder/tags"
    Write-Host "--profile: specify profile"
    Write-Host "--output: specify output directory for build results (default: ./bin)"
    Write-Host "--custom-modules: specify custom modules directory (default: ./custom_modules)"
    Write-Host "--with-pull: pull image before build"
    Write-Host "--rm-first: remove container before build"
    Write-Host "--use-mirror: use mirror"
    Write-Host "--mirror: specify mirror url, like mirrors.jlu.edu.cn, do not add http:// or https://"
    Write-Host "-h|--help: print this help"
    exit 1
}

function Invoke-DockerCompose {
    # Check if docker-compose is available, otherwise use docker compose
    if (Get-Command docker-compose -ErrorAction SilentlyContinue) {
        & docker-compose @args
    } else {
        & docker compose @args
    }
}

# Handle help parameter
if ($Help) {
    Show-Usage
}

# Validate required parameters
if (-not $Image) {
    Write-Error "ERROR: no image specified"
    Show-Usage
}

# Set default values
if (-not $UseMirror) {
    $UseMirror = $true
}

Write-Host "IMAGEBUILDER_IMAGE: $Image PROFILE: $Profile"
Write-Host "CUSTOM_MODULES_PATH: $CustomModules"

# Determine build directory based on image type
if ($Image -match "immortalwrt") {
    $BuildDir = "/home/build/immortalwrt"
} else {
    $BuildDir = "/builder"
}

# Verify Docker is available
if (!(Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Error "错误: 未找到 Docker，请确保 Docker Desktop 已安装并运行"
    Write-Host "请从以下地址下载并安装 Docker Desktop for Windows:"
    Write-Host "  - https://www.docker.com/products/docker-desktop"
    exit 1
}

# Generate docker-compose.yml content
$dockerComposeContent = @"
version: "3.5"
services:
  imagebuilder:
    image: "$Image"
    container_name: imagebuilder
    environment:
      - PROFILE=$Profile
      - USE_MIRROR=$([int]$UseMirror)
      - MIRROR=$Mirror
      - IMAGEBUILDER_IMAGE=$Image
      - ENABLE_MODULES=$env:ENABLE_MODULES
      - CONFIG_TARGET_ROOTFS_PARTSIZE=$env:CONFIG_TARGET_ROOTFS_PARTSIZE
    env_file:
      - ./.env
    volumes:
      - ${Output}:${BuildDir}/bin
      - ./build.sh:${BuildDir}/build.sh
      - ./setup:${BuildDir}/setup
      - ./modules:${BuildDir}/modules_in_container
      - ${CustomModules}:${BuildDir}/custom_modules_in_container
      - ./.env:${BuildDir}/.env
    command: "./build.sh"
"@

# Write docker-compose.yml file
$dockerComposeContent | Out-File -FilePath "docker-compose.yml" -Encoding UTF8

# Pull image if requested
if ($WithPull) {
    Write-Host "Pulling Docker image..."
    Invoke-DockerCompose pull
}

# Remove existing container if requested
if ($RmFirst) {
    Write-Host "Removing existing container..."
    try {
        & docker stop imagebuilder 2>$null
        & docker rm imagebuilder 2>$null
    } catch {
        # Container might not exist, ignore errors
    }
}

# Create output directory
if (!(Test-Path $Output)) {
    New-Item -ItemType Directory -Path $Output -Force | Out-Null
}

# Check if .env file exists
if (!(Test-Path ".env")) {
    Write-Warning "WARNING: .env file not found, using default values"
    "" | Out-File -FilePath ".env" -Encoding UTF8
}

# Run the build
Write-Host "Starting build process..."
Invoke-DockerCompose up --exit-code-from imagebuilder --remove-orphans
$buildStatus = $LASTEXITCODE

# Cleanup
Invoke-DockerCompose rm -f
Remove-Item "docker-compose.yml" -Force

if ($buildStatus -ne 0) {
    Write-Error "build failed with exit code $buildStatus"
    exit 1
} else {
    Write-Host "Build completed successfully!"
    Get-ChildItem $Output -Recurse | Format-Table Name, Length, LastWriteTime
}