@Echo Off
SetLocal EnableDelayedExpansion
Title QoS Policy Manager
Set Version=1.0
Color 0F

REM Variables
Set "MyPath=%~dp0"
Set "A=[92m[ACTION][0m"
Set "I=[96m[INFO][0m"
Set Pwsh=^>Nul 2>&1 Powershell -NoProfile -NonInteractive -ExecutionPolicy Bypass -Command

REM Run As Trusted Installer Via MinSudo
Cd %Temp%
Dism >Nul || (Where MinSudo >Nul 2>&1 || (
Curl -L "https://github.com/M2Team/NanaRun/releases/download/1.0.92.0/NanaRun_1.0_Preview3_1.0.92.0.zip" -O "NanaRun.zip" -S || ^
Echo Failed To Download MinSudo, Run This Script As An Administrator. && Pause && Exit
%Pwsh% "Add-Type -A 'System.IO.Compression.FileSystem'; [IO.Compression.ZipFile]::ExtractToDirectory('NanaRun.zip', '.\NanaRun');"
Move /Y .\NanaRun\x64\MinSudo.exe MinSudo.exe >Nul
Del /F NanaRun.zip
Rmdir /S /Q NanaRun
) & MinSudo -NoL -TI -P "%~f0" && Exit)
Cls

REM Initialization
Echo %I% Welcome To QoS Policy Manager
Echo %I% This Script Configures QoS Policies To Optimize Network Traffic And Prioritize Application Bandwidth

REM Enable QoS Packet Scheduler And Configure Registry
Echo.
Echo %A% Configuring Multiple Parameters To Ensure That QoS Policies Run Smooth
Reg.exe Add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\StandardProfile" /v "EnableFirewall" /t REG_DWORD /d "0" /f >Nul 2>&1
Reg.exe Add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\PrivateProfile" /v "EnableFirewall" /t REG_DWORD /d "0" /f >Nul 2>&1
Reg.exe Add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\DomainProfile" /v "EnableFirewall" /t REG_DWORD /d "0" /f >Nul 2>&1
Reg.exe Add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\PublicProfile" /v "EnableFirewall" /t REG_DWORD /d "0" /f >Nul 2>&1
Reg.exe Add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\Psched\DiffServByteMappingNonConforming" /v "ServiceTypeNetworkControl" /t REG_DWORD /d "56" /f >Nul 2>&1
Reg.exe Add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\Psched\DiffServByteMappingConforming" /v "ServiceTypeNetworkControl" /t REG_DWORD /d "56" /f >Nul 2>&1
Reg.exe Add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\Psched\DiffServByteMappingNonConforming" /v "ServiceTypeGuaranteed" /t REG_DWORD /d "5" /f >Nul 2>&1
Reg.exe Add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\Psched\DiffServByteMappingConforming" /v "ServiceTypeGuaranteed" /t REG_DWORD /d "46" /f >Nul 2>&1
Reg.exe Add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\Psched\UserPriorityMapping" /v "ServiceTypeNetworkControl" /t REG_DWORD /d "7" /f >Nul 2>&1
Reg.exe Add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\Psched" /v "MaxOutstandingSends" /t REG_DWORD /d "65000" /f >Nul 2>&1
Reg.exe Add "HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows\Psched" /V "NonBestEffortLimit" /t REG_DWORD /d "0" /F >Nul 2>&1
Reg.exe Add "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\Tcpip\QoS" /V "Do not use NLA" /t REG_SZ /d "1" /F >Nul 2>&1
Powershell -Command "Enable-NetAdapterBinding -Name '*' -ComponentID Ms_Pacer" >Nul 2>&1
Netsh Int TCP Set Global AutoTuningLevel=Disabled >Nul 2>&1
Netsh AdvFireWall Set AllProfiles State Off >Nul 2>&1
SC Config Psched Start= Auto >Nul 2>&1
SC Start Psched >Nul 2>&1

REM Clear Existing QoS Policies
Echo.
Echo %A% Clearing Existing QoS Policies
Powershell -Command "Get-NetQosPolicy | ForEach-Object { Remove-NetQosPolicy -Name $_.Name -Confirm:$False }" >Nul 2>&1

REM Create New QoS Policies
Echo.
Echo %A% Creating New QoS Policies
Powershell -Command "New-NetQosPolicy -Name 'Fortnite' -AppPathNameMatchCondition 'FortniteClient-Win64-Shipping.exe' -DscpAction 46 -Precedence 255 -NetworkProfile 'All'" >Nul 2>&1
Powershell -Command "New-NetQosPolicy -Name 'Minecraft' -AppPathNameMatchCondition 'javaw.exe' -DscpAction 46 -Precedence 255 -NetworkProfile 'All'" >Nul 2>&1
Powershell -Command "New-NetQosPolicy -Name 'CS2' -AppPathNameMatchCondition 'cs2.exe' -DscpAction 46 -Precedence 255 -NetworkProfile 'All'" >Nul 2>&1
Powershell -Command "New-NetQosPolicy -Name 'Valorant' -AppPathNameMatchCondition 'riotclientservices.exe' -DscpAction 46 -Precedence 255 -NetworkProfile 'All'" >Nul 2>&1

REM Refresh Network Settings
Echo.
Echo %A% Restarting Network
GPUpdate /Force >Nul 2>&1
IPConfig /Flushdns >Nul 2>&1
IPConfig /Release >Nul 2>&1
IPConfig /Renew >Nul 2>&1
%Pwsh% "Get-NetAdapter | Where-Object {$_.Status -eq 'Up'} | Restart-NetAdapter"

REM Completion Message
Echo.
Echo %A% QoS Policies Applied Successfully^!

REM Hide Pause And Wait For Any Key Press To Close
Echo.
Set "ExitPrompt= %I% Press Any Key To Exit..."
<Nul 2>&1 Set /P= %ExitPrompt%
Pause >Nul 2>&1
EndLocal
Exit
