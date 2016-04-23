call :focus TestApp
exit /b

:focus
setlocal EnableDelayedExpansion

    if ["%~1"] equ [""] (
        echo Please give the window's title.
        exit /b
    )

    set pr=%~1
    set pr=!pr:"=!

    echo CreateObject("wscript.shell").appactivate "!pr!" > "%tmp%\focus.vbs"
    call "%tmp%\focus.vbs"
    del "%tmp%\focus.vbs"

goto :eof
endlocal
