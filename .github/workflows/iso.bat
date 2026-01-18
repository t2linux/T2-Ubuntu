@ECHO off

SET latest=GITHUBRELEASE
SET latestkver=%latest%
CALL SET latestkver=%%latestkver:v=%%
FOR /f "tokens=1,2 delims=-" %%a IN ("%latestkver%") DO (
  SET latestkver=%%a
)

SET downloads=%userprofile%\Downloads

ECHO Choose the flavour of Ubuntu you wish to install: 
ECHO.
ECHO 1. Ubuntu 
ECHO 2. Kubuntu 
ECHO 3. Ubuntu Unity 
ECHO.
SET /P flavinput=Type your choice (1, 2 etc.) from the above list and press return.:
::todo fix milti line string in this ass language

IF "%flavinput%"=="1" (
    SET flavour=ubuntu
) ELSE (
    IF "%flavinput%"=="2" (
        SET flavour=kubuntu
    ) ELSE (
        IF "%flavinput%"=="3" (
            SET flavour=ubuntu-unity
        ) ELSE (
            ECHO Invalid input. Aborting!
            PAUSE 
            EXIT
        )
    )
)

ECHO Choose the version of Ubuntu you wish to install: 
ECHO.
ECHO 1. 24.04 LTS - Noble Numbat 
ECHO 2. 25.10 - Questing Quokka 
ECHO.
SET /P verinput=Type your choice (1 or 2) from the above list and press return.
::todo fix milti line string in this ass language

IF "%flavinput%"=="1" (
    SET iso=%flavour%-24.04-%latestkver%-t2-noble
    SET ver=24.04 LTS - Noble Numbat
) ELSE (
    IF "%flavinput%"=="2" (
        SET iso=%flavour%-25.10-%latestkver%-t2-questing
        SET ver=25.10 - Questing Quokka 
    ) ELSE (
        ECHO "Invalid input. Aborting!"
        PAUSE 
        EXIT
    )
)

ECHO Downloading Part 1 for %flavour% %ver%
curl -A "Mozilla/5.0 (compatible; MSIE 9.0; Windows NT 6.1; WOW64)" -L https://github.com/t2linux/T2-Ubuntu/releases/download/%latest%/%iso%.iso.00 -o %downloads%\0%iso%.iso

ECHO Downloading Part 2 for %flavour% %ver%
curl -A "Mozilla/5.0 (compatible; MSIE 9.0; Windows NT 6.1; WOW64)" -L https://github.com/t2linux/T2-Ubuntu/releases/download/%latest%/%iso%.iso.01 -o %downloads%\1%iso%.iso

ECHO Downloading Part 3 for %flavour% %ver%
curl -A "Mozilla/5.0 (compatible; MSIE 9.0; Windows NT 6.1; WOW64)" -L https://github.com/t2linux/T2-Ubuntu/releases/download/%latest%/%iso%.iso.02 -o %downloads%\2%iso%.iso

FOR /f "tokens=1,2 delims= " %%a IN ("%ver%") DO (
  SET shortver=%%a
)

curl -s -A "Mozilla/5.0 (compatible; MSIE 9.0; Windows NT 6.1; WOW64)" -L https://github.com/t2linux/T2-Ubuntu/releases/download/%latest%/sha256-%flavour%-%shortver% -o shafile.txt

FOR /F "DELIMS=" %%A IN (shafile.txt) DO (
    SET actual_iso_chksum=%%A
    GOTO :break_loop
)
:break_loop

DEL shafile.txt

FOR /f "tokens=1,2 delims= " %%a IN ("%actual_iso_chksum%") DO (
  SET actual_iso_chksum=%%a
)

ECHO combining parts

COPY /B %downloads%\0%iso%.iso + %downloads%\1%iso%.iso + %downloads%\2%iso%.iso %downloads%\%iso%.iso

ECHO cleaning up

DEL %downloads%\0%iso%.iso
DEL %downloads%\1%iso%.iso
DEL %downloads%\2%iso%.iso

ECHO Verifying sha256 checksums

FOR /f "tokens=1" %%i IN ('certutil -hashfile %downloads%\%iso%.iso SHA256 ^| findstr /v "hash"') DO (
    SET "downloaded_iso_chksum=%%i"
)

ECHO %actual_iso_chksum%
ECHO %downloaded_iso_chksum%

IF "%actual_iso_chksum%" NEQ "%downloaded_iso_chksum%" (
    ECHO Error: Failed to verify sha256 checksums of the ISO
    PAUSE 
    EXIT
)

ECHO ISO saved successfully

PAUSE
