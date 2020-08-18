#!/usr/bin/pwsh
param ( $dataFolder = '',
        $dockerFile = 'Dockerfile',
        $openBrowser = $False)

function BuildNotebook($tag) {
    Write-Host "Building notebook"
    docker build -f $dockerFile . -t $tag 2>&1 | Out-Null
}
function StartNotebook($tag) {
    if ($dataFolder -ne '')
    {
        $pathToMount = ((Resolve-Path $dataFolder).Path | Out-String).Replace("\", "/").Trim().TrimEnd('/')
        Write-Host "Starting jupyter notebook with folder ${pathToMount} as datafolder"
        $containerId = (docker run --rm --name jupyter_notebook -d -p 8888:8888 -v ${pathToMount}:/home/notebook/ $tag) 2>&1
    } else {
        Write-Host "Starting jupyter notebook with no mounted datafolder"
        $containerId = (docker run --rm --name jupyter_notebook -d -p 8888:8888 $tag)  2>&1
    }

    Write-Host $containerId

    return $containerId
}

function ExtractUrl($containerId) {

    $logs = (docker logs $containerId) 2>&1    
    $url = [regex]::match($logs,'(http:\/\/127\.0\.0\.1:[\S]+)').Groups[0].Value
    return $url
}

Try {
    $tag = 'local/jupyter:latest'

    BuildNotebook $tag
    $containerId = StartNotebook $tag

    # wait for 5 seconds and then try to extract browser url from container logs
    Start-Sleep 5

    if ($openBrowser -eq $True) {
        # get container logs
        $url = ExtractUrl($containerId)
        # open url
        Start-Process $url
    }

    # keep script active until stopped with Ctrl-C
    while ($True) 
    {
        Start-Sleep -Seconds 1 
    }
}
Finally {
    if ($containerId -ne '') {
        Write-Host "Removing jupyter notebook container"
        docker rm -f "$containerId" | Out-Null
    }
}