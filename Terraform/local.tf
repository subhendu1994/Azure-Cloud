locals {
  #virtual_machine_fqdn = join(",", [var.vm_name, var.ad_domain_name])
  auto_logon_data = "<AutoLogon><Password><Value>${var.admin_password}</Value></Password><Enabled><LogonCount>1</LogonCount></LogonCount><Username>${var.admin_username}</Username></Autologon>"
  first_logon_data = file("${path.module}/files/FirstLogonCommands.xml")
  adduser_command = "Add-LocalGroupMember -Group Administrator -Member ${var.domain_techuser}"
  enable_command = "enable-wsmanCredSSP -role Server -Force"
  configure_command = "Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope LocalMachine -Force -Confirm:$False"
  cleanup-command = "Remove-Item C:/Terraform/ -Recurse"
  move-cdrom = "Get-WmiObject -Calss Win32_volume -Filter 'DriveType=5' | Select-Object -First 1 | Set-WmiInstance -Arguments @{DriveLetter= 'A:'}"
  format_diskd = "Get-Disk|Where-object partitionstyle -eq 'raw' |Intialize-Disk -PartitionStyle GPT -PassThru|New-Partition -AssignDriveLetter -UseMaximumSize|Format-Volume -FileSystem NTFS -NewFileSystemLabel 'New Volume' -Confirm:$false"
  reboot_command = "Shutdown -r -t 30"
  exit_code = "exit 0"
  powershell_command = "${local.adduser_command}; ${local.enable_command}; ${local.configure_command}; ${local.cleanup_command}; ${local.move_cdrom}; ${local.format_diskd}; ${local.reboot_command}; ${local.exit_code}" 
}