# Parallel Computation in Batch Script

My goal was to implement the *reduce* operation in Batch Script, something commonly used in parallel programming, for fun. The basic idea is to create a parallel version of combining all the values in an array using some combining function. For example, given an array of numbers and an addition function:

    1 2 3 4 5

Becomes
    
    1 + 2 + 3 + 4 + 5

Doing this in parallel is intuitive. The naive way would be to have more processes than leaves, in a tree structure. For example, if we split our array into 4 parts, we would have:

```
    P
   / \
  P   P
 / \ / \
P  P P  P
```

Where P denotes a processor. The leaf nodes calculate the combination of the parts of the array, and send those values up to the parent, where it will be combined with the other leafs, and so on. However, a more conservative way would be to have the leaf nodes also do the work of combining the other leaves. For example, given the same parameters as above, we could have this tree instead:

```
P
|\
P P
  |
  P 
```
Each of the processors does work, instead of having to wait like the non leaf nodes above, and also combines with the children. To implement this idea in Batch Script, I wanted to avoid creating temporary files to communicate. It is slow, is a messy side effect, but more importantly, it makes the problem much easier to implement. All you would need to do is start some processes (```START /B```, pipes, etc.) with an arbitrary id that identifies their child or parent; each process reads from their children files (eg. ```result_<children_id>```) and writes to a file (eg. ```result_<own_id>```). Some ideas I had was using the little known [waitFor](https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/waitfor) command, however it is not portable and has limitations, so I thought of a better idea.

This idea stems from constructing the tree itself using pipes and ampersands. Pipes send stdout to the stdin of two commands. For example:

```Batch
ECHO Hi | SOMETHING
```

The ```SOMETHING``` command would receive "Hi". Now, if ```SOMETHING``` was a Batch Script, you could read this using ```SET /P``` (typically used for user input) because it is blocking. Ampersands chain two commands together. For example:

```Batch
ECHO Hi & ECHO Bye
```

Would print Hi and Bye on separate lines. This separation is key. That means that it will consume exactly 2 ```SET /P``` commands. Therefore, we can imagine using ampersands to "group" children together, and send those values using pipes to the parent. For example:

```Batch
(ECHO Child1 & ECHO Child2 & ECHO Child3) | PARENT
```

Where parent has exactly 3 ```SET /P```s to consume each of those outputs. Because it is a reduce operation, the ordering of the children does not matter. Thus, one can see how this can form a tree. A larger example:

```Batch
(((ECHO Child1 & ECHO Child2) | PARENT) & ((ECHO Child3 & ECHO Child4) | PARENT)) | PARENT
```

This represents the tree seen above:

```
    P
   / \
  P   P
 / \ / \
P  P P  P
```

The great thing about this solution is that it is naturally blocking. There is no need for code to *wait* until the children are finished. The ```SET /P```s handle it for you. Furthermore, the great thing about Batch Script is that everything is a string; we can build this tree as a string, then run it by using the variable directly. Thus, the greatest difficulty is in actually constructing this tree.

```Batch
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
```

This is a common algorithm to build this sort of tree, that doesn't rely on recursion. For leaf nodes, we can use

```Batch
START /B "" "%~F0" THREAD !has.child! %1
```

This command creates a starts a process with ```/B```. This means that it is non blocking, so you can run multiple processes at once. The ```%~F0``` refers to the batch file itself, and the parameters allow the Batch Script to navigate to different parts of its own code. This is because at the start of the file, we have:

```Batch
IF not "%1" == "" (
    SET "children=%2"
    SET "id=%3"
    GOTO :%1
)
```

In this way, we can run multiple different processes without needing different files. ```!has.child!``` refers to how many children we have (how many ```SET /P```s to wait for) and the ```%1``` refers to the id of the thread. This is purely for debugging purposes, and is not needed. Overall, ```CREATE_THREADS``` takes in a parameter ```n``` (must be even) that generates ```n``` threads, and constructs this tree into the ```%threads%``` variable. Here's the variable value with ```n = 4```:

```Batch
(START /B "" "C:\Users\test\parallel.bat" THREAD 0 1&((START /B "" "C:\Users\test\parallel.bat" THREAD 0 3)|START /B "" "C:\Users\test\parallel.bat" THREAD 1 2))| "C:\Users\test\parallel.bat" MAIN 2
```

Which corresponds to other example tree above:

```
P
|\
P P
  |
  P
```

Inside ```THREAD``` and ```MAIN``` is very simple code. All we need to do is do the portion of work, and read the values using ```SET /P```.

```Batch
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
```

What's left is actually running it. Since this is just a variable, you can generate it once, and run it whenever:

```Batch
CALL :CREATE_THREADS 4
%threads%
```

The full script is available to see [here](https://github.com/thelowsunoverthemoon/parallel.bat/blob/main/parallel.bat). There is a problem, however. While this works well, it is specialized to the ```reduce``` operation. If one were to want to implement a ```scan``` operation, which typically has both a upward and downward pass, then this solution falls apart. The reason is that pipes are unidirectional in Batch Script, so there is no way to send information "back".

An interesting solution to this problem (and it is probably faster to use temporary files, but I just think this is neat) is to implement message passing. We can emulate a ring network topology, and imagine that the pipes are unidirectional links between the processes. To loop back, we can simply redirect to a file at the end, and direct that file into the first process. In this way, there is no need to create and delete temporary files as messages; there will only be ```n``` files created (in the case of a theoretical ```scan``` operation, at least). We can pass in information about parents, children, etc. as parameters to the processes so they know who to send messages to. Thus, for ```n = 2```, we get
```
"C:\Users\test\parallel.bat" MAIN < "C:\Users\test\AppData\Local\Temp\parallel_sig.txt" > "C:\Users\test\AppData\Local\Temp\parallel_sig_2.txt" | "C:\Users\test\parallel.bat" THREAD 2 1 "" "1, 1, 20000" <"C:\Users\test\AppData\Local\Temp\parallel_sig_2.txt" > "C:\Users\test\AppData\Local\Temp\parallel_sig_1.txt" | "C:\Users\test\parallel.bat" THREAD 1 0 "2 " "1, 1, 20000" < "C:\Users\test\AppData\Local\Temp\parallel_sig_1.txt" > "C:\Users\test\AppData\Local\Temp\parallel_sig.txt"
```

Furthermore, each process will need to have the previous processes file directed into them, and be directed into their own file. The reason is because we don't want ```SET /P``` to be blocking. This is because we still want the process to loop in case of something (for example, the computation has ended so the process needs to exit). The idea is, we can ```ECHO``` a message with an id. If the process doesn't match the id, it can ```ECHO``` it again to the next process, and the next, until it reaches the correct process. If not, it can just consume the message. Naturally, this is a pretty ugly solution because messages can be lost easily. Hence, we don't just send 1 message, but many messages. In this case, I think it is more natural to use a recursive solution to create this structure:

```Batch
:CREATE <n>
COPY NUL "%TEMP%\%~n0_sig.txt" >NUL
SET /A %inc.id%
CALL :CREATE_R %1 %id% 0
SET "ring=^< "%TEMP%\%~n0_sig.txt" %ring% ^> "%TEMP%\%~n0_sig.txt""
GOTO :EOF

:CREATE_R <n> <id> <parent> <child>
IF "%1" == "1" (
    COPY NUL "%TEMP%\%~n0_sig_%2.txt" >NUL
    SET "ring=!ring! > "%TEMP%\%~n0_sig_%2.txt" ^| "%~F0" THREAD %2 %3 %4 !data.%2! < "%TEMP%\%~n0_sig_%2.txt""
    GOTO :EOF
)
SET /A "left=%1 / 2", "right=%1 - left", %inc.id%, "id.temp=id"
SETLOCAL
CALL :CREATE_R %right% %id% %2 ""
ENDLOCAL & SET "id.save=%id.save%" & SET "ring=%ring%"
CALL :CREATE_R %left% %2 %3 "%id.temp% %~4"
GOTO :EOF
```

In ```THREAD```, the code is much uglier. We use string substitution as a way to check for children messages without loops; once we get all the children loops, we continually send messages of our results. Because we need to continually send messages, we also need a mechanism to detect when the computation is finished. I use a temporary file for this.

```Batch
:THREAD
COPY NUL %id%.ready >NUL
SET "need= %children%"
FOR /L %%X in (%data%) DO (
    SET /A "sum+=%%X"
)
IF "%children%" == "" (
    SET "send=1"
)
FOR /L %%? in () DO (
    IF exist "%~dpn0.quit" (
        EXIT
    )
    SET /P "msg="
    IF defined send (
        IF defined msg (
            ECHO !msg!
        )
        ECHO %id% !sum!
    ) else IF defined msg (
        FOR /F "tokens=1,*" %%A in ("!msg!") DO (
            IF "!need: %%A =!" == "!need!" (
                ECHO !msg!
            ) else (
                SET /A "sum+=%%B"
                SET "need=!need: %%A=!"
                IF "!need!" == " " (
                    SET "send=1"
                )
            )
        )
        SET "msg="
    )
)
```

Note that in ```MAIN``` I use the (slightly) obscure ```CON``` device, which refers to the console directly. This is because we have redirected stdin into a file. The full file can be found [here](https://github.com/thelowsunoverthemoon/parallel.bat/blob/main/ring.bat).
