@ECHO OFF
SETLOCAL ENABLEDELAYEDEXPANSION
IF not "%1" == "" (
    SET "children=%2"
    SET "id=%3"
    GOTO :%1
)

SET "tasks=12"

:: must be even number of threads
CALL :CREATE_THREADS %tasks%

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

:CREATE_THREADS <n>
SETLOCAL
SET /A "total=%1", "start=%1 - 1"
FOR /L %%Q in (%start%, -1, 0) DO (
    SET /A "has.child=0", "stride=1"
    CALL :CREATE_THREADS_LOOP %%Q

)
SET "branch.0=(!branch.0!)^| "%~F0" MAIN !has.child!"
ENDLOCAL & SET "threads=%branch.0%"
GOTO :EOF

:CREATE_THREADS_LOOP
IF %stride% GEQ %total% (
    GOTO :EOF
)
SET /A "need.child=%1 %% (2 * stride)"
IF "!need.child!" == "0" (
    SET /A "index=%1 + stride"
    IF !index! GEQ %total% (
        SET "branch.%1=((!branch.%1!)^|START /B "" "%~F0" THREAD !has.child! %1)"
        GOTO :EOF
    )
    SET /A "has.child+=1"
    FOR %%Q in (!index!) DO (
        SET "branch.%1=!branch.%1!^&!branch.%%Q!"
    )
    IF "!branch.%1:~0,1!" == "&" (
        SET "branch.%1=!branch.%1:~1!"
    )
    SET /A "stride*=2"
    GOTO :CREATE_THREADS_LOOP
)
IF "!has.child!" == "0" (
    SET "branch.%1=START /B "" "%~F0" THREAD !has.child! %1"
) else (
    SET "branch.%1=((!branch.%1!)^|START /B "" "%~F0" THREAD !has.child! %1)"
)
GOTO :EOF
