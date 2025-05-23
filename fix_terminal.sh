#!/bin/bash

echo "=== Terminal Diagnostic and Fix Script ==="
echo

echo "1. Current shell information:"
echo "   Shell: $SHELL"
echo "   Term: $TERM"
echo "   User: $(whoami)"
echo

echo "2. Current terminal dimensions:"
stty -a | head -1
echo "   tput lines: $(tput lines)"
echo "   tput cols: $(tput cols)"
echo "   LINES env: $LINES"
echo "   COLUMNS env: $COLUMNS"
echo

echo "3. Checking for problematic processes:"
ps aux | grep -E "(fish|tmux|screen)" | grep -v grep | head -5
echo

echo "4. Testing character input (type 'test' and press enter):"
read -p "Input: " user_input
echo "   You entered: '$user_input'"
echo

echo "5. Attempting to fix terminal dimensions:"
export LINES=24
export COLUMNS=80
stty rows 24 cols 80 2>/dev/null || echo "   stty command failed"
echo "   After fix attempt:"
stty -a | head -1
echo

echo "6. Key binding check for problematic characters:"
bind -p | grep -E "(q|\\C-c)" | head -5
echo

echo "7. Recommendations:"
if [ "$(tput lines)" -eq 1 ]; then
    echo "   ❌ Terminal dimensions are corrupted (1 row detected)"
    echo "   💡 This is likely a remote terminal/SSH issue"
    echo "   💡 Try resizing your terminal window or reconnecting"
    echo "   💡 The 'q' and ctrl-c insertion is likely due to display corruption"
else
    echo "   ✅ Terminal dimensions appear normal"
fi

echo
echo "8. Character corruption test:"
echo "   If you see random 'q' characters or ctrl-c appearing, it's likely"
echo "   due to the terminal dimension issue causing display corruption."
echo
echo "=== End of Diagnostic ===" 