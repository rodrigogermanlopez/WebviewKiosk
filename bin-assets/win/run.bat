rem start WebViewWpfApp.exe -resW 1920 -resH 1080 -locX 0 -locY 0 -sendPort 9010 -recvPort 9011 -debug
@echo off
tasklist /fi "imagename eq iexplore.exe" > nul
if errorlevel 1 start iexplore -k http://10.0.1.5:8888/KaonCityscape
rem if errorlevel 1 start iexplore http://10.0.1.5:8888/KaonCityscape
exit


