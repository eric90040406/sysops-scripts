# Shell Script 撰寫風格規範（QC1 Style）

當使用者要求撰寫 Shell Script 時，**必須嚴格遵守**以下所有規範。

---

## 一、整體結構（三段式架構，固定順序）

```
[Block 1]  #################### init script + default variables ####################
[Block 2]  ################### your functions ####################
[Block 3]  ################### get Value from keyin ####################
           ####################################### main loop ############################################
```

- 每個區塊必須有 `##################` 分隔線標題
- 標題格式：`#################### 標題文字 ####################`（`#` 數量約 20 個）

---

## 二、Shebang

```sh
#! /bin/sh
```

- 固定使用 `#! /bin/sh`（注意 `!` 後有空格）

---

## 三、Init 區塊（Block 1）固定內容

```sh
current_path="$(realpath $(dirname $0))"
script_name="$(echo $(basename $0)|cut -d '.' -f1)"
if ! echo ${current_path}|grep -q 'log/tools' > /dev/null 2>&1; then
    main_script=0
    # 下載並執行 QC1_init.sh ...
    result_path="${INIT_CURRENT_PATH}"
    log_path="${INIT_LOG_PATH}"
else
    main_script=1
    source ${current_path}/../.bashrc > /dev/null 2>&1; INIT_EXPORT > /dev/null 2>&1
    result_path="$(INIT_GET_LOG_PATH ${current_path} ${script_name})"
    log_path="${result_path}"
fi
```

規則：
- 開頭**一定**先取得 `current_path` 與 `script_name`
- 用 `grep -q 'log/tools'` 判斷是否為主程式入口
- `main_script=0` / `main_script=1` 標記執行身份
- `source .bashrc` 執行**兩次**（確保環境變數完全載入）
- 呼叫 `INIT_EXPORT` 初始化路徑變數
- 雜訊一律加 `> /dev/null 2>&1`

---

## 四、預設變數宣告

- 緊接在 init 區塊之後，函數定義之前
- 字串值用雙引號包覆
- 數字不加引號
- 布林值用 `"yes"` / `"no"`（**不用** `true` / `false`）
- 注釋放同行尾端

```sh
main_log=${log_path}/main.log
upload_log="no"
io_monitor="no"
test_option="random"
count=0
max_stress_count=500
```

---

## 五、型號判斷（case/esac）

```sh
case ${INIT_MODEL_NAME} in
    MODEL_A)
        var1="value1"
        ;;
    MODEL_B | MODEL_C)
        var1="${INIT_MODEL_NAME}"
        ;;
    *)
        INIT_LOG -e "ERROR: 不支援的型號 ${INIT_MODEL_NAME}" ${main_log}
        exit 1
        ;;
esac
```

- `case` 縮排 4 個空格
- 多型號合併用 ` | ` 分隔（兩側有空格）
- `*)` 預設一定呼叫錯誤 log 並 `exit 1`

---

## 六、函數格式

```sh
Function_name(){  # 一行說明（可選）
    local var=${1}
    ...
}
```

規則：
- 函數名使用 **`Pascal_Case`**（單字首字母大寫，底線分隔）
- 函數名後緊接 `(){`，**不加空格**
- 同行右側可加 `# 說明` 註解
- 函數內區域變數一律用 `local` 宣告
- 參數用 `${1}`, `${2}` 取得
- 函數之間空一行，函數內不空行

---

## 七、命名慣例

| 類型 | 規則 | 範例 |
|------|------|------|
| 函數名 | `Pascal_Case` | `Target_Select`, `Get_sleep_interval` |
| 全域變數 | `snake_case` 小寫 | `main_log`, `upload_log`, `test_option` |
| 系統框架變數 | `INIT_` 前綴全大寫 | `INIT_MODEL_NAME`, `INIT_LOG_PATH` |
| 本地變數 | `local` + `snake_case` | `local sleep_time`, `local enc_amount` |
| 計數/旗標 | 單字小寫 | `count`, `host`, `eunit` |

---

## 八、Log 輸出

**一律使用 `INIT_LOG`，不直接用 `echo`**

```sh
INIT_LOG -i "***** 最高層級訊息 *****" ${main_log}      # 測試目標宣告
INIT_LOG -i "*** 次要層級訊息 ***" ${main_log}           # 狀態/進度
INIT_LOG -i "======== Round [${count}] ========" ${main_log}  # 迴圈輪次
INIT_LOG -e "ERROR 訊息" ${main_log}                     # 錯誤
```

層級規則：
- `***** ... *****` → 最高層級（測試目標/階段宣告）
- `*** ... ***` → 次要層級（狀態/進度）
- `======== ... ========` → 迴圈輪次標記
- `-i` = info，`-e` = error
- 第二參數固定傳入 `${main_log}`

---

## 九、條件判斷

```sh
# 字串比較
if [ "${variable}" == "value" ]; then

# 數字比較
if [ ${number} -eq 0 ]; then
if [ ${number} -ge 2000 ]; then

# grep 判斷存在（用 -c 搭配 -eq 1）
if [ "$(uname -a | grep keyword -c)" -eq 1 ]; then

# 複合條件
if [ condition1 ] && [ condition2 ]; then
```

- 變數**一律加雙引號**（字串比較）
- 使用 `[ ]` 而非 `[[ ]]`
- grep 判斷存在與否用 `grep xxx -c` 搭配 `-eq 1`

---

## 十、迴圈

```sh
# 主控迴圈（數值計數）
while [ ${count} -lt ${max_stress_count} ]; do
    ...
done

# 固定次數
for i in $(seq 1 ${count}); do
    ...
done
```

- `while` 條件用數值比較控制輪次
- `for` 迴圈用 `seq` 產生序列

---

## 十一、算術運算

```sh
count=$(expr ${count} + 1)
result=$(expr $((count - 1)) / ${enc_amount} % 2)
```

- 使用 `expr` 做算術（不用 `$(( ))` 風格）

---

## 十二、變數取用

```sh
${variable}   # 一律加大括號
```

---

## 十三、wget 下載模式

```sh
wget -N -r -l 0 --quiet -nd --timeout=30 \
    --directory-prefix=${INIT_TOOL_PATH} \
    --ftp-user=stressftp --ftp-password=ftp \
    ftp://qc1.synology.qc/qc1script2/...
chmod 777 ${INIT_TOOL_PATH}/*
```

- 固定參數：`-N -r -l 0 --quiet -nd --timeout=30`
- 下載後**立即** `chmod 777`

---

## 十四、Get_keyin() 參數解析（固定格式）

```sh
Get_keyin(){
    for this_arg in ${@}; do
        key=`echo ${this_arg} | cut -d= -f 1`
        value=`echo ${this_arg} | cut -d= -f 2`
        case ${key} in
            --flag)
                variable="value"
                ;;
            --param)
                variable=${value}
                ;;
            finish)
                QC1_remote_log_handler.sh finish
                exit
                ;;
            restore)
                Restore_all
                exit
                ;;
            reset)   #must have
                INIT_RESET_SCRIPT ${current_path} ${script_name}; exit
                ;;
            stop)   #must have
                QC1_remote_log_handler.sh finish
                INIT_STOP_SCRIPT ${current_path} ${script_name}; exit
                ;;
            *|--help)      #must have
                echo "=================== Here is the Usage for this script ==============="
                echo "reset                    Delete all files in ${result_path}"
                echo "stop                     Stop stress"
                echo "--param=value            Description"
                exit
                ;;
        esac
    done
}
```

**必備保留指令（每個 script 都要有）：**
- `reset` → 呼叫 `INIT_RESET_SCRIPT` 並 `exit`，加 `#must have` 注釋
- `stop` → 呼叫 `INIT_STOP_SCRIPT` 並 `exit`，加 `#must have` 注釋
- `finish` → 呼叫 `QC1_remote_log_handler.sh finish` 並 `exit`
- `*|--help` → 印出完整用法說明並 `exit`，加 `#must have` 注釋

---

## 十五、主程式入口（Block 3 最後幾行）

```sh
####################################### main loop ############################################
Get_keyin ${@} && if [ -f ${INIT_LOG_PATH}/process_running ]; then rm ${INIT_LOG_PATH}/process_running >/dev/null 2>&1; exit; fi
[ "${upload_log}" = "yes" ] && QC1_remote_log_handler.sh init --t=xxx --l=/root --n=${test_note} skip_console_log_cap_check
Main
[ "${upload_log}" = "yes" ] && QC1_remote_log_handler.sh finish
```

- `Get_keyin` 先執行，再判斷 lock file
- 條件式執行用 `[ condition ] && command`（不用 if）
- `Main` 是唯一業務邏輯入口

---

## 十六、錯誤處理原則

- **不使用** `set -e`
- 雜訊輸出全部 `> /dev/null 2>&1`
- 關鍵錯誤：`INIT_LOG -e` 記錄後 `exit 1`
- 非關鍵失敗：靜默忽略（`rm ... > /dev/null 2>&1`）

---

## 十七、其他細節

| 習慣 | 說明 |
|------|------|
| 標記檔 | 用 `touch` 空檔案作為狀態旗標 |
| 中文注釋 | 複雜硬體邏輯用中文說明（`#HD6500R1，無法支援...`） |
| 反引號 | 部分地方用反引號 `` ` ` `` 做命令替換（混用風格，保留） |
| 分隔線 | `#` 約 20 個字元 |
| 空行 | 函數之間空一行，函數內區塊不空行 |

---

## 十八、完整 Script 骨架 Template

```sh
#! /bin/sh
#################### init script + default variables ####################
current_path="$(realpath $(dirname $0))"
script_name="$(echo $(basename $0)|cut -d '.' -f1)"
# export script_list="..." #will auto download in QC1_init.sh
if ! echo ${current_path}|grep -q 'log/tools' > /dev/null 2>&1; then
    main_script=0
    wget -N -r -l 0 --quiet -nd --timeout=30 --directory-prefix=${current_path}/${script_name}/log/tools --ftp-user=stressftp --ftp-password=ftp ftp://qc1.synology.qc/qc1script2/QC1_init/QC1_init.sh > /dev/null 2>&1
    chmod +x ${current_path}/${script_name}/log/tools/QC1_init.sh > /dev/null 2>&1; ${current_path}/${script_name}/log/tools/QC1_init.sh "${current_path}" "${script_name}" "${$}"; source ${current_path}/${script_name}/log/.bashrc > /dev/null 2>&1; source ${current_path}/${script_name}/log/.bashrc > /dev/null 2>&1; INIT_EXPORT > /dev/null 2>&1
    result_path="${INIT_CURRENT_PATH}"
    log_path="${INIT_LOG_PATH}"
else
    main_script=1
    source ${current_path}/../.bashrc > /dev/null 2>&1; INIT_EXPORT > /dev/null 2>&1
    result_path="$(INIT_GET_LOG_PATH ${current_path} ${script_name})"
    log_path="${result_path}"
fi
################### your functions ####################
main_log=${log_path}/main.log
upload_log="no"
# [其他預設變數]
count=0
max_stress_count=500

case ${INIT_MODEL_NAME} in
    MODEL_A)
        # [型號設定]
        ;;
    *)
        INIT_LOG -e "ERROR: not supported model ${INIT_MODEL_NAME}" ${main_log}
        exit 1
        ;;
esac

Function_one(){  # 說明
    local param=${1}
    INIT_LOG -i "***** Function_one start *****" ${main_log}
}

Counter_control(){
    rm ${result_path}/count.${count} > /dev/null 2>&1
    count=$(expr ${count} + 1)
    INIT_LOG -i "======== Starting round [${count}] test ========" ${main_log}
    touch ${result_path}/count.${count}; chmod 777 ${result_path}/count.${count}
}

Main(){
    # 下載工具
    wget -N -r -l 0 --quiet -nd --timeout=30 --directory-prefix=${INIT_TOOL_PATH} --ftp-user=stressftp --ftp-password=ftp ftp://qc1.synology.qc/qc1script2/...
    chmod 777 ${INIT_TOOL_PATH}/*
    source ${INIT_TOOL_PATH}/function.sh

    while [ ${count} -lt ${max_stress_count} ]; do
        Counter_control
        Function_one
        Upload_log
    done
}

Upload_log(){
    if [ "${upload_log}" == "yes" ]; then
        INIT_LOG -i "uploading log..." ${main_log}
        QC1_remote_log_handler.sh save
        INIT_LOG -i "upload log end" ${main_log}
    fi
}
################### get Value from keyin ####################
Get_keyin(){
    for this_arg in ${@}; do
        key=`echo ${this_arg} | cut -d= -f 1`
        value=`echo ${this_arg} | cut -d= -f 2`
        case ${key} in
            --c|count)
                max_stress_count=${value}
                ;;
            --upload)
                upload_log=${value}
                ;;
            finish)
                QC1_remote_log_handler.sh finish
                exit
                ;;
            reset)   #must have
                INIT_RESET_SCRIPT ${current_path} ${script_name}; exit
                ;;
            stop)   #must have
                QC1_remote_log_handler.sh finish
                INIT_STOP_SCRIPT ${current_path} ${script_name}; exit
                ;;
            *|--help)      #must have
                echo "=================== Here is the Usage for this script ==============="
                echo "reset                    Delete all files in ${result_path}"
                echo "stop                     Stop stress"
                echo "--c=N                    Set round count (default: ${max_stress_count})"
                echo "--upload=yes             Enable log upload"
                exit
                ;;
        esac
    done
}
####################################### main loop ############################################
Get_keyin ${@} && if [ -f ${INIT_LOG_PATH}/process_running ]; then rm ${INIT_LOG_PATH}/process_running >/dev/null 2>&1; exit; fi
[ "${upload_log}" = "yes" ] && QC1_remote_log_handler.sh init --t=stress${max_stress_count} --l=/root --n=${test_note} skip_console_log_cap_check
Main
[ "${upload_log}" = "yes" ] && QC1_remote_log_handler.sh finish
```
