@ECHO OFF
SETLOCAL ENABLEDELAYEDEXPANSION
IF not "%1" == "" (
    SET "children=%2"
    SET "id=%3"
    SET "children.id=%4"
    GOTO :%1
)

SET /A "tasks=10", "num.max=10"

CALL LOOM "%~F0" CREATE_TREE %tasks%

DEL /F /Q "%TEMP%\%~n0_out.txt" 2>NUL 1>NUL

%threads%

PAUSE>NUL
EXIT /B

:MAIN

CALL :RECEIVE_MAX

(ECHO Total Max : %max%)>CON

SET "prefix=0"
(ECHO %id% Prefix : %prefix%)>CON
CALL :SEND_MAX

EXIT

:THREAD

CALL :RECEIVE_MAX

ECHO %id%:%max%
(WAITFOR scan%id%)>NUL

SET /P prefix=<"%TEMP%\%~n0_%id%.txt"
(ECHO %id% Prefix : %prefix%)>CON
IF not "%children%" == "0" (
    CALL :SEND_MAX
)

EXIT

:SEND_MAX
SET "running=!prefix!"
IF !own.max! GTR !running! (
    SET "running=!own.max!"
)
FOR %%C in (%children.id:.= %) DO (
    (ECHO !running!)>"%TEMP%\%~n0_%%C.txt"
    IF !child.max.%%C! GTR !running! (
        SET "running=!child.max.%%C!"
    )
    (WAITFOR /SI scan%%C)>NUL
)
GOTO :EOF

:RECEIVE_MAX
SET "max=0"
SET "values="
FOR /L %%G in (1, 1, %num.max%) DO (
    SET /A "val=id * %%G"
    SET "values=!values! !val!"
    IF !val! GTR !max! (
        SET "max=!val!"
    )
)
SET "own.max=!max!"
(ECHO Process %id% values:!values!, local max=!own.max!)>CON
IF not "%children%" == "0" (
    FOR %%C in (%children.id:.= %) DO (
        SET "child.max.%%C=0"
    )
    FOR /L %%G in (1, 1, %children%) DO (
        SET "line="
        SET /P "line="
        FOR /F "tokens=1,2 delims=:" %%A in ("!line!") DO (
            SET "c.id=%%A"
            SET "c.max=%%B"
        )
        SET "child.max.!c.id!=!c.max!"
        IF !c.max! GTR !max! (
            SET "max=!c.max!"
        )
    )
)
GOTO :EOF