@ECHO off

curl -Is https://github.com >nul 2>&1
if errorlevel 1 (
    echo Please connect to the internet
    exit /b 1
)

SET latest=GITHUBRELEASE
SET latestkver=%latest%
CALL SET latestkver=%%latestkver:v=%%
FOR /f "tokens=1,2 delims=-" %%a IN ("%latestkver%") DO (
  SET latestkver=%%a
)

SET downloads=%userprofile%\Downloads

ECHO.
ECHO Choose the flavour of Ubuntu you wish to install:
ECHO.
ECHO 1. Ubuntu
ECHO 2. Kubuntu
ECHO 3. Ubuntu Unity
ECHO 4. Ubuntu Budgie
ECHO 5. Ubuntu Cinnamon
ECHO 6. Ubuntu MATE
ECHO 7. Xubuntu
ECHO.
ECHO Type your choice (1, 2 etc.) from the above list and press return.
SET /P flavinput=

IF "%flavinput%"=="1" (
    SET flavour=ubuntu
    SET flavourcap=Ubuntu
) ELSE (
    IF "%flavinput%"=="2" (
        SET flavour=kubuntu
        SET flavourcap=Kubuntu
    ) ELSE (
        IF "%flavinput%"=="3" (
            SET flavour=ubuntu-unity
            SET flavourcap=Ubuntu Unity
        ) ELSE (
            IF "%flavinput%"=="4" (
                SET flavour=ubuntu-budgie
                SET flavourcap=Ubuntu Budgie
            ) ELSE (
                IF "%flavinput%"=="5" (
                    SET flavour=ubuntucinnamon
                    SET flavourcap=Ubuntu Cinnamon
                ) ELSE (
                    IF "%flavinput%"=="6" (
                        SET flavour=ubuntu-mate
                        SET flavourcap=Ubuntu MATE
                    ) ELSE (
                        IF "%flavinput%"=="7" (
                            SET flavour=xubuntu
                            SET flavourcap=Xubuntu
                        ) ELSE (
                            ECHO Invalid input. Aborting!
                            EXIT
                        )
                    )
                )
            )
        )
    )
)

ECHO.
ECHO Choose the version of Ubuntu you wish to install:
ECHO.
ECHO 1. 24.04 LTS - Noble Numbat
ECHO 2. 25.10 - Questing Quokka
ECHO.
ECHO Type your choice (1 or 2) from the above list and press return.
SET /P verinput=

IF "%verinput%"=="1" (
    SET iso=%flavour%-24.04-%latestkver%-t2-noble
    SET ver=24.04 LTS - Noble Numbat
) ELSE (
    IF "%verinput%"=="2" (
        SET iso=%flavour%-25.10-%latestkver%-t2-questing
        SET ver=25.10 - Questing Quokka
    ) ELSE (
        ECHO "Invalid input. Aborting!"
        EXIT
    )
)

ECHO.
ECHO Downloading Part 1 for %flavourcap% %ver%
ECHO.
curl -#L https://github.com/t2linux/T2-Ubuntu/releases/download/%latest%/%iso%.iso.00 > %downloads%\%iso%.iso

ECHO.
ECHO Downloading Part 2 for %flavourcap% %ver%
ECHO.
curl -#L https://github.com/t2linux/T2-Ubuntu/releases/download/%latest%/%iso%.iso.01 >> %downloads%\%iso%.iso

ECHO.
ECHO Downloading Part 3 for %flavourcap% %ver%
ECHO.
curl -#L https://github.com/t2linux/T2-Ubuntu/releases/download/%latest%/%iso%.iso.02 >> %downloads%\%iso%.iso

ECHO.
ECHO Downloading Part 4 for %flavourcap% %ver%
ECHO.
curl -#L https://github.com/t2linux/T2-Ubuntu/releases/download/%latest%/%iso%.iso.03 >> %downloads%\%iso%.iso

FOR /f "tokens=1,2 delims= " %%a IN ("%ver%") DO (
  SET shortver=%%a
)

curl -s -L https://github.com/t2linux/T2-Ubuntu/releases/download/%latest%/sha256-%flavour%-%shortver% -o shafile.txt

FOR /F "DELIMS=" %%A IN (shafile.txt) DO (
    SET actual_iso_chksum=%%A
    GOTO :break_loop
)
:break_loop

DEL shafile.txt

FOR /f "tokens=1,2 delims= " %%a IN ("%actual_iso_chksum%") DO (
  SET actual_iso_chksum=%%a
)

ECHO.
ECHO Verifying sha256 checksums

FOR /f "tokens=1" %%i IN ('certutil -hashfile %downloads%\%iso%.iso SHA256 ^| findstr /v "hash"') DO (
    SET "downloaded_iso_chksum=%%i"
)

IF "%actual_iso_chksum%" NEQ "%downloaded_iso_chksum%" (
    ECHO.
    ECHO Error: Failed to verify sha256 checksums of the ISO
    DEL %downloads%\%iso%.iso
    EXIT
)

ECHO.
ECHO ISO saved to Downloads
