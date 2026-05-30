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
(WAITFOR scan%id%)>NUL

SET /P prefix=<"%TEMP%\%~n0_%id%.txt"
(ECHO %id% Prefix : "!prefix!")>CON
IF not "%children%" == "0" (
    CALL :SEND_VAL
)
EXIT

:SEND_VAL
SET "running=!prefix!!own.val!"
FOR %%C in (%children.id:.= %) DO (
    SET "out=!running!"
    (ECHO !out!)>"%TEMP%\%~n0_%%C.txt"
    SET "running=!running!!child.val.%%C!"
    (WAITFOR /SI scan%%C)>NUL
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