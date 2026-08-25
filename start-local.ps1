param(
    [string]$DistroName = "Debian",
    [string]$MongoBinPath = "E:\MongoDB\mongodb-win32-x86_64-windows-7.0.40\bin\mongod.exe",
    [string]$MongoDbPath = "E:\MongoDB\data\db",
    [int]$MongoPort = 27017,
    [int]$RedisPort = 6379
)

$ErrorActionPreference = "Stop"

function Test-PortOpen {
    param(
        [string]$HostName,
        [int]$Port
    )

    try {
        return Test-NetConnection -ComputerName $HostName -Port $Port -InformationLevel Quiet -WarningAction SilentlyContinue
    } catch {
        return $false
    }
}

function Wait-Port {
    param(
        [string]$HostName,
        [int]$Port,
        [int]$Retry = 20,
        [int]$DelaySeconds = 1
    )

    for ($i = 0; $i -lt $Retry; $i++) {
        if (Test-PortOpen -HostName $HostName -Port $Port) {
            return $true
        }
        Start-Sleep -Seconds $DelaySeconds
    }

    return $false
}

Write-Host "=== Local dependency check ===" -ForegroundColor Cyan

if (-not (Test-Path "src/main/resources/env.properties")) {
    Write-Host "env.properties not found. Creating from env.properties.example..." -ForegroundColor Yellow
    Copy-Item "src/main/resources/env.properties.example" "src/main/resources/env.properties"
}

if (-not (Test-PortOpen -HostName "localhost" -Port $MongoPort)) {
    Write-Host "MongoDB is not listening on localhost:$MongoPort. Starting mongod..." -ForegroundColor Yellow

    if (-not (Test-Path $MongoBinPath)) {
        throw "mongod.exe not found at $MongoBinPath. Update -MongoBinPath and re-run."
    }

    New-Item -ItemType Directory -Force -Path $MongoDbPath | Out-Null
    Start-Process -FilePath $MongoBinPath -ArgumentList @("--dbpath", $MongoDbPath, "--bind_ip", "127.0.0.1", "--port", "$MongoPort") -WindowStyle Minimized | Out-Null
}

if (-not (Wait-Port -HostName "localhost" -Port $MongoPort)) {
    throw "MongoDB did not become ready on localhost:$MongoPort"
}

Write-Host "MongoDB is ready on localhost:$MongoPort" -ForegroundColor Green

if (-not (Test-PortOpen -HostName "localhost" -Port $RedisPort)) {
    Write-Host "Redis is not listening on localhost:$RedisPort. Starting Redis in WSL distro '$DistroName'..." -ForegroundColor Yellow

    wsl -d $DistroName -e sh -lc "sudo service redis-server start" | Out-Host
}

if (-not (Wait-Port -HostName "localhost" -Port $RedisPort)) {
    throw "Redis did not become ready on localhost:$RedisPort. Check WSL redis service manually."
}

Write-Host "Redis is ready on localhost:$RedisPort" -ForegroundColor Green

Write-Host "=== Starting Spring Boot ===" -ForegroundColor Cyan

$mavenCmd = $null

try {
    $cachedMaven = Get-ChildItem "$env:USERPROFILE\.m2\wrapper\dists" -Recurse -Filter "mvn.cmd" -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1
    if ($cachedMaven) {
        $mavenCmd = $cachedMaven.FullName
    }
} catch {
    $mavenCmd = $null
}

if ($mavenCmd) {
    Write-Host "Using cached Maven: $mavenCmd" -ForegroundColor DarkCyan
    & $mavenCmd "spring-boot:run"
} else {
    Write-Host "Using Maven wrapper: .\\mvnw.cmd" -ForegroundColor DarkCyan
    .\mvnw.cmd spring-boot:run
}
