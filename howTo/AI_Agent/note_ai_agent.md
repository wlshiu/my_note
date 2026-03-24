note_ai_agent
---

# Setup Local LLM module

目前常見的佈署工具包含 `Ollama`, `vLLM` 以及 `llama.cpp`

### LLM佈署工具比較表

| 特點     | Ollama |   vLLM |   llama.cpp (LM Studio) |
| :-:      | :-:    | :-:     | :-:  |
| 定位      | 提供簡單易用的本地 LLM 運行環境,支援多種模型一鍵安裝與管理 |   高效能推理框架,專注於伺服器端大規模部署 |   輕量化 C++ 實作,強調跨平台與低資源可用性
| 安裝與使用 |安裝簡單(brew install ollama/Windows installer),透過 ollama run 即可快速啟動模型 (只支援 CUDA) |  需要 Python 環境與 CUDA,部署流程相對複雜,需要自行下載模型權重 | 單一可執行檔,無需額外依賴,可直接在 CPU 上跑 (可使用內顯 GPU)
| 模型支援   | 內建支援 LLaMA、Mistral、Gemma 等主流模型,下載即用 |支援 Hugging Face Transformers 格式,適合自訓練或自定義模型 | 支援 GGUF 量化模型,特別適合資源有限的環境
| 效能優勢  | 啟動快,支援 GPU 加速與量化模型,適合快速試驗 | 針對大模型最佳化(PagedAttention 等技術),能高效處理大批量請求 | 可在無 GPU 環境下運行,記憶體需求低,支援 4-bit/8-bit 量化
| API/整合   | 提供 REST API,易於整合進 RAG、Agent 框架 | 需自行包裝 API 或搭配 FastAPI,適合進階使用者 |  無內建 API,需要自行包裝,適合低階控制或嵌入式場景
| 適合硬體  | 一般 PC(>=16GB RAM)即可跑中小模型; 若有 GPU(>=8GB VRAM)則能流暢運行 7B~13B 模型 |  需要較強硬體: GPU (>=24GB VRAM) + 大記憶體,適合伺服器環境 | CPU-only 也能執行: Raspberry Pi / MacBook Air 這類低功耗設備都可跑小模型
| 典型場景  | 個人開發者做 Demo、快速原型、RAG 測試 | 企業伺服器端,需處理多用戶、大流量請求 | 個人裝置、邊緣運算、沒有 GPU 的環境
| 社群與維護 | 活躍度高,官方提供 Windows/Mac/Linux 支援 | 主要由研究社群與企業維護,偏向 AI infra 領域使用 |  開發社群活躍,持續支援量化格式,特別適合開源愛好者

+ LM-Studio (llama.cpp) optimization

    - 勾選 `Use Flash Attention`
        > 透過演算法優化減少記憶體讀寫,不僅加快速度,也能稍微降低處理長文本時的壓力

    - `Keep Model in Memory` 開啟或改為較長時間 (-1: 永遠保留)
        > 能避免每次對話都要重新初始化 KV-cache

    - `CPU Threads`
        > CPU 分配資源協助運算, 設定為 CPU 物理核心數減 2(例如 12 核心就設 10), 這樣可以留一點效能給作業系統,避免 LM Studio 運算時整台電腦凍結

    - `Evaluation Batch Size`
        > 內顯頻寬較低,批次太大會導致輸入處理(Prompt ingestion)變得很卡, 可調低到 256 或更低

    - 確保 `GPU Offload` 數量盡量大,讓模型權重與 KV-cache 盡可能都留在顯存中,避免與系統記憶體（RAM）交換資料導致變慢
        > LLM model 內的運算層數,可放多少層在 GPU 中

    - 調整上下文長度 `Context Length`
        > `Context Length` 會影響到 `KV-cache` 的用量, 太大會撐爆 VRAM




### 模型大小與記憶體對照表

| 模型參數 | VRAM / 記憶體需求 |   代表模型                     |  回應速度
| :-:      | :-:               | :-:                          | :-:  |
| 1B – 3B  | 2 – 4GB          | llama3.2:1b、llama3.2:3b       | 快速,適合即時回應
| 7B       | 4 – 6GB          | mistral、gemma2:7b、qwen2.5:7b  | 流暢,日常使用足夠
| 8B       | 5 – 7GB          | llama3.1:8b                   | 流暢,品質略優於 7B
| 13B      | 8 – 10GB         | codellama:13b                 | 中等,需要好一點的硬體
| 70B      | 40GB+            | llama3.1:70b                  | 較慢,需要高階 GPU

+ 最低需求(可以跑,但會慢)：
    > + 8GB RAM
    > + 10GB 以上可用磁碟空間
    > + 任何現代 CPU (2018 年之後)
    > + 不需要獨立 GPU; CPU 模式也能運行,只是速度較慢

+ 建議規格(流暢體驗)：
    > + 16GB 以上 RAM
    > + 獨立 GPU, VRAM 8GB 以上
    >> NVIDIA RTX 3060 以上 (約12G VRAM),或 AMD 同級
    > + SSD 硬碟(模型載入速度差異明顯)

    ```
    # 查看 GPU 型號與顯示記憶體
    PS > nvidia-smi
    ```

### 本地模型特色



| 模型         | 參數大小         |  特色                   | 適合場景   |
| :-:          | :-:            | :-:                     | :-:   |
| llama3.2     | 1B / 3B        | Meta 最新輕量模型,速度快  | 快速問答、文字摘要、入門測試
| llama3.1:8b  | 8B             | 品質與速度的平衡點        | 日常對話、內容撰寫、翻譯
| LLaMA 2 7B   |  7B            | 中文能力中等            　| 英文任務佳,中文需要微調 (VRAM: 6~8GB)
| mistral      | 7B             | 歐洲團隊開發,推理能力不錯  | 分析、摘要、邏輯推理, 英文 QA、效能快 (VRAM: 6~8GB)
| Qwen 1.5 7B  | 7B             | 中文能力強               | 中文 QA、對話、RAG  (VRAM: 6~8GB)
| llama-3-taiwan-8b-instruct| 8B | 中文能力強              | 台灣語境微調, 強於在地語意理解   (VRAM: 6~8GB)
| LLaMA 2 13B  | 13B            | 中文能力中等              | 英文推理強,但中文弱,3060 效能吃緊 (VRAM: 12GB+)
| gemma2       | 2B/9B/27B      |  Google 開源,多種大小可選 |  研究、實驗、多語言任務
| Qwen2.5      | 0.5B ~ 72B     |  中文表現突出,多種大小可選 |  中文對話、中文內容生成
| CodeLlama    | 7B/13B/34B     |  Meta 程式碼專用模型      |  程式碼生成、程式碼解釋, 可支援 `C++/C#/Java` <br> `Python/Bash` <br> `PHP/Typescript/Javascript` <br> 等語言
| Phi-3.5/4 Mini | 3.8B         |  微軟最強小模型, 推理效率高 |
| Starcoder2   | 3B/7B/15B      |  專為程式碼生成與理解而設計 | 支援`C/C++/C#/Java` <br> `Python/Shell` <br>`JavaScript/TypeScript/Go/Rust/Ruby/Swift` <br>`R/Julia/MATLAB` <br>`HTML/CSS/SQL/PHP` <br>
| Qwen 2.5 Coder | 0.5B/1.5B/3B/7B/14B/32B | 提供最強大的開源程式碼生成、修復與推理能力 | 支援 `C/C++/C#/Java` <br> `Python/Shell/Lua` <br> `JavaScript//Go/Rust/TypeScript/PHP/Ruby/Swift` <br> `R/Julia/MATLAB` <br> `HTML/CSS/SQL/React` <br> `Haskell/Racket` <br> 等語言

+ 選模型的兩個原則
    - 先從小模型開始。llama3.2(3B)是最好的入門選擇——下載快、記憶體需求低、回應速度快。它的品質雖然不如 8B 以上的模型,但足以讓你體驗本地 AI 的運作方式,也能處理簡單的問答和摘要任務。

    - 根據語言需求選擇。如果你的主要用途是繁體中文,qwen2.5 是目前中文表現最好的開源模型之一。7B 版本在中文理解和生成上的品質,已經能應付多數日常場景。想了解各模型在不同任務上的詳細比較,可以參考OpenClaw AI 模型比較。




# Reference

+ [OpenClaw + Ollama 本地模型：完全免費的 AI 助理 | 好事發生數位](https://ohya.co/blog/openclaw-ollama-local-llm-guide)
+ [OpenClaw AI 模型比較 2026：選對模型省錢又好用 | 好事發生數位](https://ohya.co/blog/openclaw-ai-model-comparison)
+ [iT 邦幫忙::從 RAG 到 Agentic RAG：30 天打造本機智慧檢索系統](https://ithelp.ithome.com.tw/m/users/20178499/ironman/8472)
    - [iT 邦幫忙::在地端運行 LLM：Ollama、vLLM 與 llama.cpp 比較以及ollama安裝](https://ithelp.ithome.com.tw/m/articles/10390964)








