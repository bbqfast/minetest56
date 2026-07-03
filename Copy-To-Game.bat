@echo off
set /p confirm="Are you sure? This will overwrite your existing game files (Y/N): "
if /i not "%confirm%"=="Y" exit /b

xcopy basic_snacks C:\Minetest\v5.6\mods\basic_snacks\  /s /e /y
xcopy maidroid_ng C:\Minetest\v5.6\mods\maidroid_ng\  /s /e /y
xcopy lordofthetest C:\Minetest\v5.6\games\lordofthetest\  /s /e /y