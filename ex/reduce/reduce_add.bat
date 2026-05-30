@ECHO OFF
SETLOCAL ENABLEDELAYEDEXPANSION
IF not "%1" == "" (
    SET "children=%2"
    SET "id=%3"
    GOTO :%1
)

SET "tasks=10"

CALL LOOM "%~F0" CREATE_TREE %tasks%

ECHO %tasks% Tasks to Complete
ECHO Sequential
FOR /L %%L in (1, 1, %tasks%) DO (
    FOR /L %%G in (1, 1, 20000) DO (
        SET /A "seq.sum+=%%G"
    )
)
ECHO Total Sum : %seq.sum%

ECHO Parallel
%threads%

PAUSE
EXIT /B

:MAIN
FOR /L %%G in (1, 1, 20000) DO (
    SET /A "sum+=%%G"
)
FOR /L %%G in (1, 1, %children%) DO (
    SET /P "add="
    SET /A "sum+=add"
)
ECHO Total Sum : %sum%
EXIT

:THREAD
FOR /L %%G in (1, 1, 20000) DO (
    SET /A "sum+=%%G"
)
IF not "%children%" == "0" (
    FOR /L %%G in (1, 1, %children%) DO (
        SET /P "add="
        SET /A "sum+=add"
    )
)
ECHO %sum%
EXIT