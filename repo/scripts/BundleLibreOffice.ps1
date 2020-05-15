function GenerateSpellerSetup {
    param (
        $Name,
        $UUID,
        $Version,
        $LanguageTag
    )

    Write-Output @"
#define AppName "$Name"
#define AppId = "{{$UUID}"
#define AppVersion "$Version"
#define Prefix "$LanguageTag"

[Setup]
AppId={#AppId}
AppName={#AppName}
AppVersion={#AppVersion}
AppPublisher={{Universitetet i Troms� - Norges arktiske universitet}
AppPublisherURL={{http://www.divvun.no/}
CreateAppDir=no
OutputBaseFilename=speller-{#Prefix}-lo
Compression=lzma
SolidCompression=yes
SignedUninstaller=yes
SignTool=signtool
MinVersion=6.3.9200

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Files]
Source: ".\*.zhfst"; DestDir: "C:\voikko\3"; Flags: ignoreversion
"@ | Out-File -Encoding "UTF8" ".\setup.iss"

    #$utf8 = 
    #[IO.File]::WriteAllText(".\setup.iss", $template, System.Text.UTF8Encoding)
}

function InvokeIscc {
    param (
        $IssFile,
        $PfxPath,
        $PfxPassword
    )

    $isccPath = "C:\Program Files (x86)\Inno Setup 6\ISCC.exe"
    $signToolArg = '/S"signtool=C:\Program Files (x86)\Microsoft SDKs\ClickOnce\SignTool\signtool.exe sign /t http://timestamp.verisign.com/scripts/timstamp.dll /f ' + $PfxPath + ' /p ' + $PfxPassword + ' $f"'
    $isccArgs = @('/Qp', '/O.\output', $signToolArg, $IssFile)
    $process = Start-Process -FilePath $isccPath -ArgumentList $isccArgs -PassThru -Wait -NoNewWindow
    if ($process.ExitCode -ne 0) { throw }   
}
