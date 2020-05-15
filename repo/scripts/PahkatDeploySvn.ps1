function PahkatDeploySvn {
    param (
        $SvnUrl,
        $Artifact,
        $Package,
        $Version
    )

    if (!$Env:DEPLOY_SVN_USER) {
        Write-Error "DEPLOY_SVN_USER variable not set"
        throw
    }

    if (!$Env:DEPLOY_SVN_PASSWORD) {
        Write-Error "DEPLOY_SVN_PASSWORD variable not set"
        throw
    }

    # make sure artifact exists
    if (-not (Test-Path $Artifact)) { throw }

    $intermediateRepo = "intermediate-svn"
    $retries = 0
    $maxRetries = 5

    while($retries -lt $maxRetries) {
        # remove intermediate repo
        Remove-Item -Force -Recurse -ErrorAction Ignore $intermediateRepo

        # checkout the svn repo to use for deployment
        svn checkout --depth immediates $SvnUrl $intermediateRepo
        if ($LastExitCode -ne 0) { throw }
        Set-Location $intermediateRepo
        svn up packages --set-depth=infinity
        if ($LastExitCode -ne 0) { throw }
        svn up virtuals --set-depth=infinity
        if ($LastExitCode -ne 0) { throw }
        svn up index.nightly.json
        if ($LastExitCode -ne 0) { throw }
        
        $deployExtension = [System.IO.Path]::GetExtension($Artifact)
        $deployAs = "$Package-$((Get-Date).ToUniversalTime().ToString('yyyyMMddTHHmmssZ'))$deployExtension"
        
        Copy-Item $Artifact .\artifacts\$deployAs
        svn add .\artifacts\$deployAs
        if ($LastExitCode -ne 0) { throw }
        
        # update the pahkat package description
        $fileSize = (Get-Item $Artifact).length
        
        # mangle the pahkat json
        # NOTE: this is a rather bad method of doing this (for instance we assume that the
        #       lines we mangle end with , which might not be the case). however, we will
        #       probably move this to pahkat in the end
        $template = Get-Content ".\packages\$Package\index.nightly.json" -Raw
        $versionString = '"version": "' + $Version + '",'
        $template = $template -replace '"version".*', $versionString
        $urlString = '"url": "' + $SvnUrl + '/artifacts/' + $deployAs + '",'
        $template = $template -replace '"url".*', $urlString
        $sizeString = '"size": ' + $fileSize + ','
        $template = $template -replace '"size".*', $sizeString

        # write updated package description to repo
        $utf8 = New-Object System.Text.UTF8Encoding $false
        Set-Content -Value $utf8.GetBytes($template) -Encoding Byte -Path ".\packages\$Package\index.nightly.json"

        # re-index using pahkat
        pahkat repo index
        if ($LastExitCode -ne 0) { throw }

        svn status
        if ($LastExitCode -ne 0) { throw }

        # run svn status to get the changes logged
        # then optionally commit changes
        if ($Env:DEPLOY_SVN_COMMIT -eq "1") {
            svn commit -m "Automated Deploy: $Package" --username=$Env:DEPLOY_SVN_USER --password=$Env:DEPLOY_SVN_PASSWORD
            if ($LastExitCode -eq 0) { 
                Write-Output "Successfully deployed $Artifact to $SvnUrl"
                exit 0
            }
            if ($retries -lt $maxRetries) {
                $sleepTime=$(Get-Random -Maximum 60)
                Write-Output "Retrying in $sleepTime second(s).."
                Start-Sleep -Seconds 60
            }
            $retries += 1
        }
        else {
            Write-Host "Warning: DEPLOY_SVN_COMMIT not set, ie. changes to repo will not be committed"
            exit 0
        }
    }

    Write-Output "Max retries reached while deploying $Artifact to $SvnUrl"
    throw
}
