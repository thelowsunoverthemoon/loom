SET "caller=%~1"
CALL :%2 %3 %4 %5 %6 %7 %8 %9
EXIT /B

:: must be even number of threads
:CREATE_TREE <n>
SETLOCAL
SET /A "total=%1", "start=%1 - 1"
FOR /L %%Q in (%start%, -1, 0) DO (
    SET /A "has.child=0", "stride=1"
    SET "children.%%Q="
    CALL :CREATE_TREE_LOOP %%Q
)
SET "branch.0=(!branch.0!)^| "%caller%" MAIN !has.child! 0 !children.0!"
ENDLOCAL & SET "threads=%branch.0%"
GOTO :EOF

:CREATE_TREE_LOOP
IF %stride% GEQ %total% (
    GOTO :EOF
)
SET /A "need.child=%1 %% (2 * stride)"
IF "!need.child!" == "0" (
    SET /A "index=%1 + stride"
    IF !index! GEQ %total% (
        SET "branch.%1=((!branch.%1!)^|START /B "" "%caller%" THREAD !has.child! %1 !children.%1!)"
        GOTO :EOF
    )
    SET /A "has.child+=1"
    SET "children.%1=!children.%1!.!index!"
    FOR %%Q in (!index!) DO (
        SET "branch.%1=!branch.%1!^&!branch.%%Q!"
    )
    IF "!branch.%1:~0,1!" == "&" (
        SET "branch.%1=!branch.%1:~1!"
    )
    SET /A "stride*=2"
    GOTO :CREATE_TREE_LOOP
)
IF "!has.child!" == "0" (
    SET "branch.%1=START /B "" "%caller%" THREAD !has.child! %1 !children.%1!"
) else (
    SET "branch.%1=((!branch.%1!)^|START /B "" "%caller%" THREAD !has.child! %1 !children.%1!)"
)
GOTO :EOF

:CREATE_RING <n>
SET "id.save=1"
SET "inc.id=id=id.save, id.save+=1"
COPY NUL "%TEMP%\%~n0_sig.txt" >NUL
SET /A %inc.id%
CALL :CREATE_RING_LOOP %1 %id% 0
SET "ring=^< "%TEMP%\%~n0_sig.txt" %ring% ^> "%TEMP%\%~n0_sig.txt""
GOTO :EOF

:CREATE_RING_LOOP <n> <id> <parent> <child>
IF "%1" == "1" (
    COPY NUL "%TEMP%\%~n0_sig_%2.txt" >NUL
    SET "ring=!ring! > "%TEMP%\%~n0_sig_%2.txt" ^| "%caller%" THREAD %2 %3 %4 !data.%2! < "%TEMP%\%~n0_sig_%2.txt""
    GOTO :EOF
)
SET /A "left=%1 / 2", "right=%1 - left", %inc.id%, "id.temp=id"
SETLOCAL
CALL :CREATE_RING_LOOP %right% %id% %2 ""
ENDLOCAL & SET "id.save=%id.save%" & SET "ring=%ring%"
CALL :CREATE_RING_LOOP %left% %2 %3 "%id.temp% %~4"
GOTO :EOF
