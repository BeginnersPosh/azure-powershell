[CmdletBinding()]
Param
(
    [Parameter()]
    [string]$BuildConfig
)

$output = Join-Path (Get-Item $PSScriptRoot).Parent.FullName "src\Package\$BuildConfig"
Write-Verbose "The output folder is set to $output"
$serviceManagementPath = Join-Path $output "ServiceManagement\Azure"
$resourceManagerPath = Join-Path $output "ResourceManager\AzureResourceManager"
$stackPath = "src\Stack\$BuildConfig\ResourceManager\AzureResourceManager"

Write-Verbose "Removing generated NuGet folders from $output"
$resourcesFolders = @("de", "es", "fr", "it", "ja", "ko", "ru", "zh-Hans", "zh-Hant")
Get-ChildItem -Include $resourcesFolders -Recurse -Force -Path $output | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue

Write-Verbose "Removing autogenerated XML help files, code analysis, config files, and symbols."
$exclude = @("*.dll-Help.xml", "Scaffold.xml", "RoleSettings.xml", "WebRole.xml", "WorkerRole.xml")
$include = @("*.xml", "*.lastcodeanalysissucceeded", "*.dll.config", "*.pdb")
Get-ChildItem -Include $include -Exclude $exclude -Recurse -Path $output | Remove-Item -Force -Recurse
Get-ChildItem -Recurse -Path $output -Include *.dll-Help.psd1 | Remove-Item -Force

Write-Verbose "Removing markdown help files and folders"
Get-ChildItem -Recurse -Path $output -Include *.md | Remove-Item -Force -Confirm:$false
Get-ChildItem -Directory -Include help -Recurse -Path $output | Remove-Item -Force -Confirm:$false

Write-Verbose "Removing unneeded web deployment dependencies"
$webdependencies = @("Microsoft.Web.Hosting.dll", "Microsoft.Web.Delegation.dll", "Microsoft.Web.Administration.dll", "Microsoft.Web.Deployment.Tracing.dll")
Get-ChildItem -Include $webdependencies -Recurse -Path $output | Remove-Item -Force

$resourceManagerFolders = Get-ChildItem -Path $resourceManagerPath -Directory
foreach ($RMFolder in $resourceManagerFolders)
{
    $psd1 = Get-ChildItem -Path $RMFolder.FullName -Filter "$($RMFolder.Name).psd1"
    Import-LocalizedData -BindingVariable ModuleMetadata -BaseDirectory $psd1.DirectoryName -FileName $psd1.Name
    
    $acceptedDlls = @()
    $acceptedDlls += $ModuleMetadata.NestedModules
    $acceptedDlls += $ModuleMetadata.RequiredAssemblies

    $acceptedDlls = $acceptedDlls | where { $_ -ne $null } | % { $_.Substring(2) }
    
    Write-Verbose "Removing redundant dlls in $($RMFolder.Name)"
    $removedDlls = Get-ChildItem -Path $RMFolder.FullName -Filter "*.dll" | where { $acceptedDlls -notcontains $_.Name}
    $removedDlls | % { Write-Verbose "Removing $($_.Name)"; Remove-Item $_.FullName -Force }

    Write-Verbose "Removing scripts and psd1 in $($RMFolder.FullName)"
    if (Test-Path -Path "$($RMFolder.FullName)\StartupScripts")
    {
        $scriptName = "$($RMFolder.FullName)$([IO.Path]::DirectorySeparatorChar)StartupScripts$([IO.Path]::DirectorySeparatorChar)$($RMFolder.Name.replace('.', ''))Startup.ps1"
        Write-Verbose $scriptName
        $removedScripts = Get-ChildItem -Path "$($RMFolder.FullName)\StartupScripts" -Filter "*.ps1" | where { $_.FullName -ne $scriptName }
        $removedScripts | % { Write-Verbose "Removing $($_.FullName)"; Remove-Item $_.FullName -Force }
    }
    $removedPsd1 = Get-ChildItem -Path "$($RMFolder.FullName)" -Filter "*.psd1" | where { $_.FullName -ne "$($RMFolder.FullName)$([IO.Path]::DirectorySeparatorChar)$($RMFolder.Name).psd1" }
    $removedPsd1 | % { Write-Verbose "Removing $($_.FullName)"; Remove-Item $_.FullName -Force }
}

$stackFolders = Get-ChildItem -Path $stackPath -Directory
foreach ($stackFolder in $stackFolders)
{
    $psd1 = Get-ChildItem -Path $stackFolder.FullName -Filter "$($stackFolder.Name).psd1"
    Import-LocalizedData -BindingVariable ModuleMetadata -BaseDirectory $psd1.DirectoryName -FileName $psd1.Name
    
    $acceptedDlls = @()
    $acceptedDlls += $ModuleMetadata.NestedModules
    $acceptedDlls += $ModuleMetadata.RequiredAssemblies

    $acceptedDlls = $acceptedDlls | where { $_ -ne $null } | % { $_.Substring(2) }
    
    Write-Verbose "Removing redundant dlls in $($stackFolder.Name)"
    $removedDlls = Get-ChildItem -Path $stackFolder.FullName -Filter "*.dll" | where { $acceptedDlls -notcontains $_.Name}
    $removedDlls | % { Write-Verbose "Removing $($_.Name)"; Remove-Item $_.FullName -Force }

    Write-Verbose "Removing scripts and psd1 in $($stackFolder.FullName)"
    if (Test-Path -Path "$($stackFolder.FullName)\StartupScripts")
    {
        $scriptName = "$($stackFolder.FullName)$([IO.Path]::DirectorySeparatorChar)StartupScripts$([IO.Path]::DirectorySeparatorChar)$($stackFolder.Name.replace('.', ''))Startup.ps1"
        Write-Verbose $scriptName
        $removedScripts = Get-ChildItem -Path "$($stackFolder.FullName)\StartupScripts" -Filter "*.ps1" | where { $_.FullName -ne $scriptName }
        $removedScripts | % { Write-Verbose "Removing $($_.FullName)"; Remove-Item $_.FullName -Force }
    }
    $removedPsd1 = Get-ChildItem -Path "$($stackFolder.FullName)" -Filter "*.psd1" | where { $_.FullName -ne "$($stackFolder.FullName)$([IO.Path]::DirectorySeparatorChar)$($stackFolder.Name).psd1" }
    $removedPsd1 | % { Write-Verbose "Removing $($_.FullName)"; Remove-Item $_.FullName -Force }
}
