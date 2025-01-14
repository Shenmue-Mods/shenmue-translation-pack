@echo off

rem T_CAM_WS with CAM_DLL compile batch file for most console compilers
rem pause after each compiler if %1 not empty
rem call self on low env space condition
rem (c) 2003-2004 W.Ehrhardt

if exist CAM_DLL.DLL goto dll_found
echo CAM_DLL.DLL not found
goto ende

:dll_found

set SRC=T_CAM_WS

rem log file (may be con or nul)
rem ============================
::set LOG=nul
set LOG=%SRC%.LOD


rem parameters for test file
rem ========================
set PARA=test


rem test whether enough space in environment
rem ========================================
set PCB=A_rather_long_environment_string_for_testing
if  (%PCB%)==(A_rather_long_environment_string_for_testing) goto OK


rem call self with 4096 byte env
rem ============================
set PCB=
%COMSPEC% /E:4096 /C %0 %1 %2 %3 %4 %5 %6 %7 %8 %9
goto ende


:OK

echo Test %SRC% for all win32 compilers  >%LOG%
ver >>%LOG%

set PCB=call fpc2 -B -dUSEDLL
del %SRC%.exe >nul
%PCB% %SRC%.pas
if not (%1%)==() pause
echo. >>%LOG%
echo Results for %PCB% >>%LOG%
%SRC%.exe %PARA% >>%LOG%

set PCB=call fpc22 -B -dUSEDLL
del %SRC%.exe >nul
%PCB% %SRC%.pas
if not (%1%)==() pause
echo. >>%LOG%
echo Results for %PCB% >>%LOG%
%SRC%.exe %PARA% >>%LOG%

set PCB=call fpc222 -B -dUSEDLL
del %SRC%.exe >nul
%PCB% %SRC%.pas
if not (%1%)==() pause
echo. >>%LOG%
echo Results for %PCB% >>%LOG%
%SRC%.exe %PARA% >>%LOG%

set PCB=call fpc224 -B -dUSEDLL
del %SRC%.exe >nul
%PCB% %SRC%.pas
if not (%1%)==() pause
echo. >>%LOG%
echo Results for %PCB% >>%LOG%
%SRC%.exe %PARA% >>%LOG%

set PCB=call fpc240 -B -dUSEDLL
del %SRC%.exe >nul
%PCB% %SRC%.pas
if not (%1%)==() pause
echo. >>%LOG%
echo Results for %PCB% >>%LOG%
%SRC%.exe %PARA% >>%LOG%

set PCB=call vpc -b  -dUSEDLL
del %SRC%.exe >nul
%PCB% %SRC%.pas
if not (%1%)==() pause
echo. >>%LOG%
echo Results for %PCB% >>%LOG%
%SRC%.exe %PARA% >>%LOG%

set PCB=D:\DMX\M2\DCC32.EXE -b -dUSEDLL
del %SRC%.exe >nul
%PCB% %SRC%.pas
if not (%1%)==() pause
echo. >>%LOG%
echo Results for %PCB% >>%LOG%
%SRC%.exe %PARA% >>%LOG%

set PCB=D:\DMX\M3\DCC32.EXE -b -dUSEDLL
del %SRC%.exe >nul
%PCB% %SRC%.pas
if not (%1%)==() pause
echo. >>%LOG%
echo Results for %PCB% >>%LOG%
%SRC%.exe %PARA% >>%LOG%

set PCB=D:\DMX\M4\DCC32.EXE -b -dUSEDLL
del %SRC%.exe >nul
%PCB% %SRC%.pas
if not (%1%)==() pause
echo. >>%LOG%
echo Results for %PCB% >>%LOG%
%SRC%.exe %PARA% >>%LOG%

set PCB=D:\DMX\M5\DCC32.EXE -b -dUSEDLL
del %SRC%.exe >nul
%PCB% %SRC%.pas
if not (%1%)==() pause
echo. >>%LOG%
echo Results for %PCB% >>%LOG%
%SRC%.exe %PARA% >>%LOG%

set PCB=D:\DMX\M6\DCC32.EXE -b -dUSEDLL
del %SRC%.exe >nul
%PCB% %SRC%.pas
if not (%1%)==() pause
echo. >>%LOG%
echo Results for %PCB% >>%LOG%
%SRC%.exe %PARA% >>%LOG%

set PCB=D:\DMX\M7\DCC32.EXE -b -dUSEDLL
del %SRC%.exe >nul
%PCB% %SRC%.pas
if not (%1%)==() pause
echo. >>%LOG%
echo Results for %PCB% >>%LOG%
%SRC%.exe %PARA% >>%LOG%

set PCB=D:\DMX\M9\DCC32.EXE -b -dUSEDLL
del %SRC%.exe >nul
%PCB% %SRC%.pas
if not (%1%)==() pause
echo. >>%LOG%
echo Results for %PCB% >>%LOG%
%SRC%.exe %PARA% >>%LOG%

set PCB=D:\DMX\M10\DCC32.EXE -b -dUSEDLL
del %SRC%.exe >nul
%PCB% %SRC%.pas
if not (%1%)==() pause
echo. >>%LOG%
echo Results for %PCB% >>%LOG%
%SRC%.exe %PARA% >>%LOG%

if not (%OS%)==(Windows_NT) goto NO_D12
set PCB=D:\DMX\M12\DCC32.EXE -b -dUSEDLL
del %SRC%.exe >nul
%PCB% %SRC%.pas
if not (%1%)==() pause
echo. >>%LOG%
echo Results for %PCB% >>%LOG%
%SRC%.exe %PARA% >>%LOG%
:NO_D12

echo **** Log file: %LOG%

:ende

set PCB=
set SRC=
set LOG=
set PARA=


