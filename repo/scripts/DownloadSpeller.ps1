function DownloadSpeller {
    param (
        $From,
        $Match,
        $SourceFile,
        $OutFile    
    )

    New-Item -Path .\tmp-download -ItemType directory
    Set-Location .\tmp-download

    # list files using the $From url and
    # match the file we want to download using $Match
    $request = Invoke-WebRequest $From
    $filename = $request.ParsedHtml.getElementsByTagName("a") | Where-Object { $_.innerHTML -match $Match } | Select-Object -ExpandProperty innerHTML
    $fileurl = "$From/$filename"

    Invoke-WebRequest $fileurl -OutFile intermediate.deb
    
    Get-ChildItem ".\" -Filter *.deb | Foreach-Object {
        New-Item tmp -ItemType Directory
        Set-Location tmp
        7z x $_.FullName
        if ($LastExitCode -ne 0) { throw }
        tar xf .\data.tar
        if ($LastExitCode -ne 0) { throw }
        Move-Item $SourceFile ..\..\$OutFile
        Set-Location ..
        Remove-Item -Force -Recurse -ErrorAction Ignore tmp
    }

    Set-Location ..
    Remove-Item -Force -Recurse -ErrorAction Ignore tmp-download
}
