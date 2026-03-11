@echo off
setlocal enabledelayedexpansion

:: Mouse tıklamasını engelle (QuickEdit kapat)
reg add "HKCU\Console" /v QuickEdit /t REG_DWORD /d 0 /f >nul 2>&1

title TIGERMAN - MSSQL Otomatik Yedekleme - CALISIYOR
color 0A

:: =============================================
:: AYARLAR
:: =============================================
set Sunucu=
set HedefKlasor=D:\testDEEE
set BeklemeSaniye=5

if not exist "%HedefKlasor%" mkdir "%HedefKlasor%"

cls
echo.
echo  ================================================================
echo  =                                                              =
echo  =   _____ ___ ____ _____ ____  __  __    _    _   _            =
echo  =  ^|_   _^|_ _/ ___^| ____^|  _ \^|  \/  ^|  / \  ^| \ ^| ^|           =
echo  =    ^| ^|  ^| ^| ^|  _^|  _^| ^| ^|_) ^| ^|\/^| ^| / _ \ ^|  \^| ^|           =
echo  =    ^| ^|  ^| ^| ^|_^| ^| ^|___^|  _ ^<^| ^|  ^| ^|/ ___ \^| ^|\  ^|           =
echo  =    ^|_^| ^|___\____^|_____^|_^| \_\_^|  ^|_/_/   \_\_^| \_^|           =
echo  =                                                              =
echo  =          MSSQL OTOMATIK YEDEKLEME SISTEMI                    =
echo  =                                                              =
echo  ================================================================
echo  =  Durum   : AKTIF                                             =
echo  =  Sunucu  : %Sunucu%
echo  =  Hedef   : %HedefKlasor%
echo  =  Aralik  : Her %BeklemeSaniye% saniyede bir
echo  =  Format  : yyyy-MM-dd_HH-mm-ss.zip
echo  =  Cikis   : CTRL+C
echo  ================================================================
echo.

:: =============================================
:: SONSUZ DONGU
:: =============================================
:DONGU

    :: Tarih ve saati PowerShell ile al (bölgesel ayardan etkilenmez)
    for /f %%T in ('powershell -NoProfile -Command "Get-Date -Format \"yyyy-MM-dd_HH-mm-ss\""') do set ZD=%%T

    set TurKlasor=%HedefKlasor%\%ZD%
    set ZipDosyasi=%HedefKlasor%\%ZD%.zip

    echo.
    echo ============================================================
    echo  YEDEKLEME BASLADI : %ZD%
    echo ============================================================

    mkdir "%TurKlasor%" >nul 2>&1

    :: DB listesini al
    set TempDB=%TEMP%\dblist_%RANDOM%.txt
    sqlcmd -S %Sunucu% -E -h -1 -W -Q "SET NOCOUNT ON; SELECT name FROM sys.databases WHERE name NOT IN ('master','tempdb','model','msdb') AND state_desc='ONLINE' ORDER BY name" > "%TempDB%" 2>&1

    if %ERRORLEVEL% NEQ 0 (
        echo  [HATA] SQL Server'a baglanamadi! Sunucu: %Sunucu%
        rmdir "%TurKlasor%" >nul 2>&1
        goto BEKLE
    )

    set BasariliSayi=0
    set HataSayi=0

    for /f "usebackq skip=1 tokens=*" %%D in ("%TempDB%") do (
        set DB=%%D
        set DB=!DB: =!
        if not "!DB!"=="" (
            set BakDosya=!DB!_%ZD%.bak
            set BakYol=%TurKlasor%\!BakDosya!
            echo  [-->] Yedekleniyor : !DB!
            sqlcmd -S %Sunucu% -E -h -1 -Q "BACKUP DATABASE [!DB!] TO DISK='!BakYol!' WITH FORMAT, COMPRESSION" >nul 2>&1
            if !ERRORLEVEL! EQU 0 (
                echo        [OK]   Basarili : !BakDosya!
                set /a BasariliSayi+=1
            ) else (
                echo        [!!]   Basarisiz: !DB!
                set /a HataSayi+=1
            )
        )
    )

    del "%TempDB%" >nul 2>&1

    echo.
    echo  Sonuc  ^> Basarili: !BasariliSayi!  /  Hatali: !HataSayi!

    :: ZIP oluştur
    echo.
    echo  [ZIP] Arsiv olusturuluyor: %ZD%.zip
    powershell -NoProfile -Command "Compress-Archive -Path '%TurKlasor%\*' -DestinationPath '%ZipDosyasi%' -Force"

    if exist "%ZipDosyasi%" (
        rmdir /s /q "%TurKlasor%"
        for %%F in ("%ZipDosyasi%") do set /a BoyutMB=%%~zF / 1048576
        echo  [ZIP] Tamamlandi : %ZD%.zip  ^(!BoyutMB! MB^)
    ) else (
        echo  [HATA] ZIP olusturulamadi! BAK klasoru korunuyor.
    )

    echo.
    echo  Bitis : %ZD%
    echo ============================================================

:: =============================================
:: GERI SAYIM
:: =============================================
:BEKLE
    set /a Kalan=%BeklemeSaniye%
    :GERI
    if !Kalan! GTR 0 (
        echo  Sonraki yedekleme : !Kalan! saniye sonra...
        ping -n 2 127.0.0.1 >nul
        set /a Kalan-=1
        goto GERI
    )

goto DONGU
