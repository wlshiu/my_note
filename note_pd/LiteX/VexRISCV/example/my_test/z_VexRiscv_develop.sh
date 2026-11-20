#!/bin/bash

set -e

#
# + switch-window: Ctrl+b 方向鍵
# + delete window: Ctrl+b x
# + scroll history: Ctrl+b [ (leave scroll mode: press q or ESC)
#

# ================= 設定區 =================
SESSION_NAME="vexriscv_debug"
WINDOW_NAME="DebugEnv"
OPENOCD_BIN="openocd"
OPENOCD_CFG="$HOME/Working/vexriscv/VexRiscv/murax.cfg"
GDB_BIN="cgdb -d riscv32-unknown-elf-gdb"
# GDB_BIN="riscv32-unknown-elf-gdb -tui"
# GDB_BIN="$HOME/Toolchain/xpack-riscv-none-embed-gcc-8.2.0-3.1/bin/riscv-none-embed-gdb"
GDB_PORT="3333"
ELF_FILE="$HOME/Working/vexriscv/VexRiscv/src/main/c/murax/my_test/build/my_test.elf"
# ==========================================


echo "Start tmux ..."
tmux kill-session -t $SESSION_NAME 2>/dev/null || true

# 1. 建立 Session 與初始視窗(此時只有 1 個全螢幕 Pane)
tmux new-session -d -s $SESSION_NAME -n "$WINDOW_NAME"

# 2. 左右分割 (-h)：切出「右半部」
# -p 50 代表右半部佔 50% 寬度(可依需求調整,例如 -p 40)
tmux split-window -h -p 35 -t "$SESSION_NAME:$WINDOW_NAME"

# --- 此時的 Pane 編號分布 ---
# .0 = 左上
# .1 = 左下
# .2 = 右半部
# 3. 選取左邊的 Pane (編號 0),再進行上下分割 (-v): 切出左下
# tmux select-pane -t "$SESSION_NAME:$WINDOW_NAME.0"
# tmux split-window -v -p 50 -t "$SESSION_NAME:$WINDOW_NAME.0"

# tmux send-keys -t "$SESSION_NAME:$WINDOW_NAME.0" "./sim_jtag_soc.py --sim-speed" C-m
# tmux send-keys -t "$SESSION_NAME:$WINDOW_NAME.1" "echo 'Wait Simulator...'; sleep 3; $OPENOCD_BIN -f $OPENOCD_CFG" C-m
# tmux send-keys -t "$SESSION_NAME:$WINDOW_NAME.2" "echo 'Wait OpenOCD Link...'; while ! nc -z localhost $GDB_PORT >/dev/null 2>&1; do sleep 1; done; $GDB_BIN $ELF_FILE -ex 'set remotetimeout 60' -ex 'target extended-remote localhost:3333'" C-m


# --- 此時的 Pane 編號分布 ---
# .0 = 左半部
# .1 = 右上
# .2 = 右下
# 3. 選取right 邊的 Pane (編號 1),再進行上下分割 (-v): 切出左下
tmux select-pane -t "$SESSION_NAME:$WINDOW_NAME.1"
tmux split-window -v -p 50 -t "$SESSION_NAME:$WINDOW_NAME.1"


tmux send-keys -t "$SESSION_NAME:$WINDOW_NAME.1" "cd $HOME/Working/vexriscv/VexRiscv/src/test/cpp/murax; make clean run" C-m
tmux send-keys -t "$SESSION_NAME:$WINDOW_NAME.2" "echo 'Wait Simulator...'; sleep 10; $OPENOCD_BIN -f $OPENOCD_CFG" C-m
tmux send-keys -t "$SESSION_NAME:$WINDOW_NAME.0" "echo 'Wait OpenOCD Link...'; while ! nc -z localhost $GDB_PORT >/dev/null 2>&1; do sleep 1; done; $GDB_BIN $ELF_FILE -ex 'set remotetimeout 60' -ex 'target extended-remote localhost:3333'" C-m



# 進入 tmux 畫面
tmux attach-session -t $SESSION_NAME



