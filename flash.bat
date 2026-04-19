@echo off
echo Flashar UK101 till permanent flash...
"C:\msys64\ucrt64\bin\openFPGALoader.exe" -b tangnano20k --write-flash "C:\pon\uk101\impl\pnr\uk101.fs"
echo Klar!
pause
