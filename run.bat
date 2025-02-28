@echo off
net session >nul 2>&1
if %errorlevel% neq 0 (
    powershell Start-Process "%~f0" -Verb RunAs
    exit
)

powershell -ExecutionPolicy Bypass -NoProfile -File "%~dp0main.ps1"
