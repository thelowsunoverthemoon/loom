@ECHO OFF
SETLOCAL ENABLEDELAYEDEXPANSION
IF not "%1" == "" (
    SET "children=%2"
    SET "id=%3"
    GOTO :%1
)

SET /A "tasks=10", "last=tasks - 1"
FOR /L %%Q in (0, 1, %last%) DO (
    FOR /L %%G in (1, 1, 10) DO (
        SET "data.%%Q=!data.%%Q! !RANDOM!"
    )
)

CALL LOOM "%~F0" CREATE_TREE %tasks%

ECHO %tasks% Tasks to Complete
ECHO Sequential
SET /A "seq.min=99999", "seq.max=0"

FOR /L %%L in (0, 1, %last%) DO (
    FOR %%V in (!data.%%L!) DO (
        IF %%V LSS !seq.min! (
            SET "seq.min=%%V"
        )
        IF %%V GTR !seq.max! (
            SET "seq.max=%%V"
        )
    )
)

SET /A "seq.range=seq.max - seq.min"
ECHO Min : %seq.min%, Max : %seq.max%, Range : %seq.range%

ECHO Parallel
%threads%

PAUSE
EXIT /B

:MAIN
SET /A "min=99999", "max=0"
FOR %%V in (!data.%id%!) DO (
    IF %%V LSS !min! (
        SET "min=%%V"
    )
    IF %%V GTR !max! (
        SET "max=%%V"
    )
)
FOR /L %%G in (1, 1, %children%) DO (
    SET "line="
    SET /P "line="
    FOR /F "tokens=1,2 delims=:" %%A in ("!line!") DO (
        IF %%A LSS !min! (
            SET "min=%%A"
        )
        IF %%B GTR !max! (
            SET "max=%%B"
        )
    )
)
SET /A "range=max - min"
ECHO Min : %min%, Max : %max%, Range : %range%
EXIT

:THREAD
SET /A "min=99999", "max=0"
FOR %%V in (!data.%id%!) DO (
    IF %%V LSS !min! (
        SET "min=%%V"
    )
    IF %%V GTR !max! (
        SET "max=%%V"
    )
)
IF not "%children%" == "0" (
    FOR /L %%G in (1, 1, %children%) DO (
        SET "line="
        SET /P "line="
        FOR /F "tokens=1,2 delims=:" %%A in ("!line!") DO (
            IF %%A LSS !min! (
                SET "min=%%A"
            )
            IF %%B GTR !max! (
                SET "max=%%B"
            )
        )
    )
)
ECHO !min!:!max!
EXIT