rem Dell PowerEdge Server - Fan Speed Control V2025.07.09
rem By Engineer Edan Boy Atun Pedragosa
rem Inspired by hernanccs script
rem Use at your own risks.

@echo OFF
setlocal EnableDelayedExpansion
cls
rem set Server IP address, Username and Password for the IPMI connection
set serverip=172.27.144.24
set username=thermal
set password=control

rem Parameters interval in seconds - offset by percentage
set checkInterval=30
set offsetSpeedBy=40
set prevTemp=0
set peakTemp=0

:monitor_temp
set Cnt=0
set currentTemp[3]=0
set currentTemp[4]=0


rem Setting Manual Fan Speed Control
ipmitool -I lanplus -H %serverip% -U %username% -P %password% raw 0x30 0x30 0x01 0x00


cls
echo ------------------------------------------------------------
echo =     Dell Poweredge Manual Fan Speed Control Script       =
echo ------------------------------------------------------------

rem Reading Temperature Sensors and Creating tmp.rdg file
rem Saves current temperatures to tmp.rdg file
ipmitool -I lanplus -H %serverip% -U %username% -P %password% sdr type temperature > tmp.rdg

echo = Reading Fan Speed Sensors and Other PSU and Temp Sensors =
echo ------------------------------------------------------------
ipmitool -I lanplus -H %serverip% -U %username% -P %password% sdr list full

rem Reads current temperature from tmp.rdg and Get the number of lines in the tmp.rdg file
for /F "tokens=3 delims= " %%i IN ('find /v /c "temp" tmp.rdg') DO set /a lines=%%i
set /a startLine=%lines%
for /F "tokens=9 delims= " %%A IN ('type tmp.rdg') DO (
rem  echo %%A
  call set currentTemp=%%A
  set /a Cnt+=1
  call set currentTemp[%%Cnt%%]=%%A
)

echo ------------------------------------------------------------
echo CURRENT TEMPERATURE READINGS:
echo      CPU 0 = %currentTemp[3]%
echo      CPU 1 = %currentTemp[4]%

set peakTemp=%currentTemp[3]%

if %currentTemp[4]% GTR %currentTemp[3]% set peakTemp=%currentTemp[4]%

echo.
echo      Current Peak Reading  = %peakTemp%
echo      Previous Peak Reading = %prevTemp%    

if %prevTemp% NEQ %peakTemp% goto setFanSpeed

echo ------------------------------------------------------------
echo No changes in temperature, keeping fan speeds at %fanSpeed%%%
echo.

timeout /t %checkInterval%
goto monitor_temp

goto end


:setFanSpeed
set /a fanSpeed=%peakTemp% - %peakTemp% * %offsetSpeedBy%/100

call :Dec2Hex %fanSpeed% HexValue
set hexFanSpeed=0x%HexValue%

echo.
echo Peak CPU Temperature is %peakTemp% degrees celcius
echo     Setting Fans Speed at %fanSpeed%%%
ipmitool -I lanplus -H %serverip% -U %username% -P %password% raw 0x30 0x30 0x02 0xff %hexFanSpeed%
set /A prevTemp=%peakTemp%

timeout /t %checkInterval%
goto monitor_temp


:Dec2Hex
set LOOKUP=0123456789abcdef
set HEXSTR=
set PREFIX=

if "%1" EQU "" (
set "%2=0"
goto:eof
)

set /a A=%1 || exit /b 1
if !A! LSS 0 set /a A=0xfffffff + !A! + 1 & set PREFIX=f

:loop
set /a B=!A! %% 16 & set /a A=!A! / 16
set HEXSTR=!LOOKUP:~%B%,1!%HEXSTR%
if %A% GTR 0 Goto :loop
set "%2=%PREFIX%%HEXSTR%"
goto:eof


:end
echo Nothing else to do...
pause
