Write-Host "Select location: "
$location = Read-Host

Write-Host "Set resource group name: "
$group = Read-Host;

$groupExist = "az group exists $group"

if (!$groupExist) {
    "az group create -l $location -n $group" | cmd
} else {
    Write-Host "Group exists";
}

Start-Process -FilePath "D:\bin\terraform.exe" -ArgumentList "apply"