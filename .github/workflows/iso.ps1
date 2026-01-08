$latest = "GITHUBRELEASE"
$latestkver = $latest.Replace("v","")
$latestkver = $latestkver.Substring(0, $latestkver.IndexOf("-"))

try
{
    $downloads = (New-Object -ComObject Shell.Application).NameSpace('shell:Downloads').Self.Path
} 
catch 
{
    Write-Output "Error: Unable to locate Downloads folder. Using current directory."
    $downloads = $PWD.Path
}

$flavinput = Read-Host -Prompt @"
Choose the flavour of Ubuntu you wish to install:

1. Ubuntu
2. Kubuntu
3. Ubuntu Unity

Type your choice (1, 2 etc.) from the above list and press return.
"@

switch ($flavinput) 
{
    1 
    { 
        $flavour="ubuntu" 
    }

    2 
    { 
        $flavour="kubuntu" 
    }

    3 
    { 
        $flavour="ubuntu-unity" 
    }

    Default 
    {
        Write-Output "Invalid input. Aborting!"
        pause
        exit
    }
} 

$verinput = Read-Host -Prompt @"
Choose the version of Ubuntu you wish to install:

1. 24.04 LTS - Noble Numbat
2. 25.10 - Questing Quokka

Type your choice (1 or 2) from the above list and press return.
"@

switch ($verinput) 
{
    1 
    { 
        $iso="$flavour-24.04-$latestkver-t2-noble"
        $ver="24.04 LTS - Noble Numbat" 
    }

    2 
    { 
        $iso="$flavour-25.10-$latestkver-t2-questing"
		$ver="25.10 - Questing Quokka" 
    }

    Default 
    {
        Write-Output "Invalid input. Aborting!"
        pause
        exit
    }
} 

try 
{
    Write-Output "Downloading Part 1 for $flavour $ver"
    Invoke-WebRequest -Uri "https://github.com/t2linux/T2-Ubuntu/releases/download/$latest/$iso.iso.00" -UseBasicParsing -OutFile "$downloads\0$iso.iso"

    Write-Output "Downloading Part 2 for $flavour $ver"
    Invoke-WebRequest -Uri "https://github.com/t2linux/T2-Ubuntu/releases/download/$latest/$iso.iso.01" -UseBasicParsing -OutFile "$downloads\1$iso.iso"

    Write-Output "Downloading Part 3 for $flavour $ver"
    Invoke-WebRequest -Uri "https://github.com/t2linux/T2-Ubuntu/releases/download/$latest/$iso.iso.02" -UseBasicParsing -OutFile "$downloads\2$iso.iso"

    $shortver = $ver.Substring(0, $ver.IndexOf(" "))
    $actual_iso_chksum = Invoke-RestMethod -Uri "https://github.com/t2linux/T2-Ubuntu/releases/download/$latest/sha256-$flavour-$shortver"
}
catch 
{
    Write-Output "Error: Downloading"
    pause
    exit
}

try 
{
    Write-Output "combining parts"
    Get-Content "$downloads\0$iso.iso","$downloads\1$iso.iso","$downloads\2$iso.iso" -Encoding Byte -Read 512 | Set-Content "$downloads\$iso.iso" -Encoding Byte

    Write-Output "cleaning up"
    Remove-Item -Path "$downloads\0$iso.iso"
    Remove-Item -Path "$downloads\1$iso.iso"
    Remove-Item -Path "$downloads\2$iso.iso"

    Write-Output "Verifying sha256 checksums"

    $actual_iso_chksum = $actual_iso_chksum.Substring(0, $actual_iso_chksum.IndexOf(" "))

    Write-Output $actual_iso_chksum

    $downloaded_iso_chksum = (Get-FileHash -Algorithm SHA256 -Path "$downloads\$iso.iso").Hash

    Write-Output $downloaded_iso_chksum

    if ($actual_iso_chksum -ne $downloaded_iso_chksum)
    {
        Write-Output "Error: Failed to verify sha256 checksums of the ISO"
        pause
        exit
    }

    Write-Output "ISO saved successfully"
}
catch 
{
    Write-Output "Error: Writing files"
}
finally
{
    pause
}