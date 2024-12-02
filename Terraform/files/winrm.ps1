Write-Host "Delete any existing WinRM listeners"
winrm delete winrm/config/listeners?Address=*+Transport=HTTP 2>$null
winrm delete winrm/config/listeners?Address=*+Transport=HTTPS 2>$null

Write-Host "Create a new WinRM listeners and configure"
winrm create winrm/config/listeners?Address=*+Transport=HTTP
winrm set winrm/config/winrs '@{MaxMemoryPerShellMB="0"}'
winrm set winrm/config '@{MaxTimeoutms="7200000"}'
winrm set winrm/config/service '@{AllowUnencrypted="true}'
winrm set winrm/config/service '@{MaxConcurrentOperationsPerUser="12000"}'
winrm set winrm/config/service/auth '@{Basic="true"}'
winrm set winrm/config/client/auth '@{Basic="true"}'

Write-Host "Configure UAC to allow privilage elevation in remote shells"
$Key ='HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System'
$Setting = 'LocalAccountTokenFilterPolicy'
Set-ItemProperty -Path $Key -Name $Setting -Value 1 -Force

Write-Host "turn off powershell execution policy restrictions"
Set-ExecutionPolicy -ExecutionPolicy Unrestricted

Set-Item WsMan:\localhost\Client\TrustedHosts -Value "aalomsfrk004,aaltrffrk001,aaltrfparc001,sla80408.srv.allianz" -Force

Write-Host "Configure and restart the WinRm Service; Enable the required firewall exception"
Stop-Service -Name WinRM
Set-Service -Name WinRM -StartupType Automatic
netsh advfirewall firewall set rule name="Windows Remote Management (HTTP-In)" new action=allow localip=any remoteip=any
Start-Service -Name WinRM
