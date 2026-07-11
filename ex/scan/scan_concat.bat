@ECHO OFF
SETLOCAL ENABLEDELAYEDEXPANSION
IF not "%1" == "" (
    SET "children=%2"
    SET "id=%3"
    SET "children.id=%4"
    GOTO :%1
)

SET "tasks=12"

CALL LOOM "%~F0" CREATE_TREE %tasks%

DEL /F /Q "%TEMP%\%~n0_out.txt" 2>NUL 1>NUL

%threads%

PAUSE>NUL
EXIT /B


:MAIN

CALL :RECEIVE_VAL

(ECHO Total Concat : !val!)>CON

SET "prefix="
(ECHO %id% Prefix : "!prefix!")>CON
CALL :SEND_VAL

EXIT

:THREAD

CALL :RECEIVE_VAL

ECHO %id%:!val!
CALL :WAIT_FOR %id%

(ECHO %id% Prefix : "!prefix!")>CON
IF not "%children%" == "0" (
    CALL :SEND_VAL
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

:SEND_VAL
SET "running=!prefix!!own.val!"
FOR %%C in (%children.id:.= %) DO (
    DOSKEY /EXENAME=loom %%C=!running!
    SET "running=!running!!child.val.%%C!"
)
GOTO :EOF

:RECEIVE_VAL
SET "own.val=[!id!]"
(ECHO Process %id%, local val=!own.val!)>CON
SET "val=!own.val!"
IF not "%children%" == "0" (
    FOR %%C in (%children.id:.= %) DO (
        SET "child.val.%%C="
    )
    FOR /L %%G in (1, 1, %children%) DO (
        SET "line="
        SET /P "line="
        FOR /F "tokens=1,2 delims=:" %%A in ("!line!") DO (
            SET "c.id=%%A"
            SET "c.val=%%B"
        )
        SET "child.val.!c.id!=!c.val!"
    )
    SET "val=!own.val!"
    FOR %%C in (%children.id:.= %) DO (
        SET "val=!val!!child.val.%%C!"
    )
)
GOTO :EOF