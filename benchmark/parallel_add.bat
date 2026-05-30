@ECHO OFF
SETLOCAL ENABLEDELAYEDEXPANSION
IF not "%1" == "" (
    SET "children=%2"
    SET "id=%3"
    GOTO :%1
)

CALL LOOM "%~F0" CREATE_TREE 10

%threads%

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