# Neon Arcade theme color reference
# Apply these in Godot editor: Project Settings > GUI > Theme > Custom (shared/theme.tres)
# Panel BG:           #0d0d1a
# Button Normal BG:   #1a1a2e
# Button Hover BG:    #2d2d5a
# Button Pressed BG:  #7c83ff
# Label Font Color:   #e0e0ff
# Background (hub):   #070714
class_name NeonTheme
extends RefCounted

const BG_DARK: Color = Color(0.027, 0.027, 0.102)        # #070714
const BG_PANEL: Color = Color(0.051, 0.051, 0.102)       # #0d0d1a
const ACCENT_PRIMARY: Color = Color(0.486, 0.514, 1.0)   # #7c83ff
const ACCENT_GREEN: Color = Color(0.486, 1.0, 0.620)     # #7cff9e
const ACCENT_RED: Color = Color(1.0, 0.486, 0.486)       # #ff7c7c
const TEXT_PRIMARY: Color = Color(0.878, 0.878, 1.0)     # #e0e0ff
const TEXT_GOLD: Color = Color(1.0, 0.85, 0.0)           # gold for combos
