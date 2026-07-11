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
CALL :WAIT_FOR %id%

(ECHO %id% Prefix : %prefix%)>CON
IF not "%children%" == "0" (
    CALL :SEND_MAX
)

EXIT

:WAIT_FOR <id>
FOR /F "tokens=1-2 delims==" %%A in ('DOSKEY /MACROS:loom') DO (
    IF "%%A" == "%1" (
        SET "prefix=%%B"
        GOTO :EOF
    )
)
GOTO :WAIT_FOR


:SEND_MAX
SET "running=!prefix!"
IF !own.max! GTR !running! (
    SET "running=!own.max!"
)
FOR %%C in (%children.id:.= %) DO (
    DOSKEY /EXENAME=loom %%C=!running!
    IF !child.max.%%C! GTR !running! (
        SET "running=!child.max.%%C!"
    )
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