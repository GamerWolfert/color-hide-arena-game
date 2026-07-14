@echo off
setlocal

if not defined COLOR_HIDE_ARENA_PORT set "COLOR_HIDE_ARENA_PORT=24590"
if not defined GODOT_BIN set "GODOT_BIN=godot"

echo Lokale Windows headless server op poort %COLOR_HIDE_ARENA_PORT%
"%GODOT_BIN%" --path "%~dp0" --headless "res://scenes/multiplayer/dedicated_server.tscn" -- --server --port=%COLOR_HIDE_ARENA_PORT%
