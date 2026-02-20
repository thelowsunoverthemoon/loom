@ECHO OFF
SETLOCAL ENABLEDELAYEDEXPANSION
IF not "%1" == "" (
    SET "id=%2"
    SET "parent=%3"
    SET "children=%~4"
    SET "data=%~5"
    GOTO :%1
)

SET "id.save=1"
SET "inc.id=id=id.save, id.save+=1"

DEL /F /Q "%~dpn0.quit" *.ready 2>NUL

SET data.1="1, 1, 20000"
SET data.2="1, 1, 20000"
SET data.3="1, 1, 20000"
SET data.4="1, 1, 20000"
SET data.5="1, 1, 20000"
SET data.6="1, 1, 20000"
SET data.7="1, 1, 20000"
SET data.8="1, 1, 20000"
SET data.9="1, 1, 20000"
SET data.10="1, 1, 20000"

CALL :CREATE 10

ECHO Sequential Answer
FOR /L %%Q in (1, 1, 10) DO (
    FOR /L %%Q in (1, 1, 20000) DO (
        SET /A "seq+=%%Q"
    )
)
ECHO Total Sum !seq!

ECHO Parallel Answer
"%~F0" MAIN %ring%

PAUSE
EXIT /B

:MAIN

CALL :WAIT 10

FOR /L %%? in () DO (
    SET /P "msg="
    IF defined msg (
        FOR /F "tokens=1,*" %%A in ("!msg!") DO (
            IF "%%A" == "1" (
                (ECHO Total Sum : %%B)>CON
                COPY NUL "%~dpn0.quit" >NUL
                EXIT
            ) else (
                ECHO !msg!
            )
        )
        SET "msg="
    )
)

:WAIT <n>
FOR /L %%G in (1, 1, %1) DO (
    IF not exist %%G.ready (
        GOTO :WAIT
    )
    (PATHPING 127.0.0.1 -n -q 1 -p 100)>NUL
)
GOTO :EOF

:THREAD
COPY NUL %id%.ready >NUL
SET "need= %children%"
FOR /L %%X in (%data%) DO (
    SET /A "sum+=%%X"
)
IF "%children%" == "" (
    SET "send=1"
)
FOR /L %%? in () DO (
    IF exist "%~dpn0.quit" (
        EXIT
    )
    SET /P "msg="
    IF defined send (
        IF defined msg (
            ECHO !msg!
        )
        ECHO %id% !sum!
    ) else IF defined msg (
        FOR /F "tokens=1,*" %%A in ("!msg!") DO (
            IF "!need: %%A =!" == "!need!" (
                ECHO !msg!
            ) else (
                SET /A "sum+=%%B"
                SET "need=!need: %%A=!"
                IF "!need!" == " " (
                    SET "send=1"
                )
            )
        )
        SET "msg="
    )
)

:CREATE <n>
COPY NUL "%TEMP%\%~n0_sig.txt" >NUL
SET /A %inc.id%
CALL :CREATE_R %1 %id% 0
SET "ring=^< "%TEMP%\%~n0_sig.txt" %ring% ^> "%TEMP%\%~n0_sig.txt""
GOTO :EOF

:CREATE_R <n> <id> <parent> <child>
IF "%1" == "1" (
    COPY NUL "%TEMP%\%~n0_sig_%2.txt" >NUL
    SET "ring=!ring! > "%TEMP%\%~n0_sig_%2.txt" ^| "%~F0" THREAD %2 %3 %4 !data.%2! < "%TEMP%\%~n0_sig_%2.txt""
    GOTO :EOF
)
SET /A "left=%1 / 2", "right=%1 - left", %inc.id%, "id.temp=id"
SETLOCAL
CALL :CREATE_R %right% %id% %2 ""
ENDLOCAL & SET "id.save=%id.save%" & SET "ring=%ring%"
CALL :CREATE_R %left% %2 %3 "%id.temp% %~4"
GOTO :EOF
