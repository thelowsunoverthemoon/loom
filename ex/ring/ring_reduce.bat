@ECHO OFF
SETLOCAL ENABLEDELAYEDEXPANSION
IF not "%1" == "" (
    SET "id=%2"
    SET "parent=%3"
    SET "children=%~4"
    SET "data=%~5"
    GOTO :%1
)

DEL /F /Q "%TEMP%\%~n0.quit" "%TEMP%\*.ready" 2>NUL

SET "tasks=4"

FOR /L %%L in (1, 1, %tasks%) DO (
    SET data.%%L="1, 1, 20000"
)

CALL LOOM "%~F0" CREATE_RING %tasks%

ECHO %tasks% Tasks to Complete
ECHO Sequential

FOR /L %%L in (1, 1, %tasks%) DO (
    FOR /L %%Q in (1, 1, 20000) DO (
        SET /A "seq+=%%Q"
    )
)
ECHO Total Sum %seq%

ECHO Parallel Answer
"%~F0" MAIN %ring%

PAUSE
EXIT /B

:MAIN

CALL :WAIT %tasks%

FOR /L %%? in () DO (
    SET /P "msg="
    IF defined msg (
        FOR /F "tokens=1,*" %%A in ("!msg!") DO (
            IF "%%A" == "1" (
                (ECHO Total Sum : %%B)>CON
                COPY NUL "%TEMP%\%~n0.quit" >NUL
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
    IF not exist "%TEMP%\%%G.ready" (
        GOTO :WAIT
    )
    (PATHPING 127.0.0.1 -n -q 1 -p 100)>NUL
)
GOTO :EOF

:THREAD
COPY NUL "%TEMP%\%id%.ready" >NUL
SET "need= %children%"
FOR /L %%X in (%data%) DO (
    SET /A "sum+=%%X"
)
IF "%children%" == "" (
    SET "send=1"
)
FOR /L %%? in () DO (
    IF exist "%TEMP%\%~n0.quit" (
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