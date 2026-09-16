@echo off
chcp 65001 >nul
title PLAYLIST 360 - Offline
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0server.ps1"
