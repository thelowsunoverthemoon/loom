@ECHO OFF

FOR /L %%L in (1, 1, 10) DO (
    FOR /L %%G in (1, 1, 20000) DO (
        SET /A "seq.sum+=%%G"
    )
)

EXIT /B