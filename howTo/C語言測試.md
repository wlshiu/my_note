C語言測試
---

# Q1： 預處理器 (Preprocessor)，用預處理指令 `#define` 宣告一個常數，用以表示 1 年中有多少秒 (忽略閏年問題)。


ANS：
```
#define SECONDS_PER_YEAR (60 * 60 * 24 * 365)UL
```

測試目的：
1. `#define` 語法的基本知識 。
2. 預處理器將為你計算常數表達式的值。
3. 意識到這個表達式將使一個 16 位元的機器產生整數型溢位，因此要用到長整型符號 L，告訴編譯器這個常數是的長整型數。
4. 表達式中用到 UL (表示無符號長整型)。

# Q2： 巨集 (Macro)，寫一個「標準」巨集 MIN ，這個巨集輸入兩個參數並回傳較小的一個。

ANS：
```
#define MIN(A, B) ((A) <= (B) ? (A) : (B))
```
測試目的︰
1. `#define` 在巨集中應用的基本知識，在 inline 運算子變為標準 C 的一部分之前，巨集是方便產生行內程式碼的唯一方法。對於嵌入式系統來說，為了能達到要求的性能，巨集程式碼經常是必須的方法。
2. 三元運算子的知識。
3. 在巨集中小心地把參數用括號括起來。


# Q3： 預處理器標識 `#error` 的作用是什麼？

ANS：
```
#error directive emits a user-specified error message at compile time and then terminates the compilation."> #error 指示詞會在編譯時期發出使用者指定的錯誤訊息並結束編輯。
```
測試目的︰
1. 測驗應試者對於冷僻的知識是否有瞭解。


# Q4： 無窮迴圈 (Infinite loops)，嵌入式系統中經常要用到無窮迴圈，怎麼樣用 C 編寫無窮迴圈呢？

ANS：
```
A1.while(1){ ... }
A2.for(;;){ ...}
A3.goto︰... Loop:... goto Loop;
```

測試目的︰
1. 迴圈的基本知識。
2. 對於迴圈的中止條件判斷的認識。


# Q5： 數據宣告 (Data declarations)，用變數 a 給出下面的定義：
+ Q1.一個整型數 (An integer)
+ Q2.一個指向整數的指標 (A pointer to an integer)
+ Q3.一個指向指標的指標，它指向的指標是指向一個整型數 (A pointer to a pointer to an integer)
+ Q4.一個有 10 個整數型的陣列 (An array of 10 integers)
+ Q5.一個有 10 個指標的陣列，該指標是指向一個整數型的 (An array of 10 pointers to integers)
+ Q6.一個指向有 10 個整數型陣列的指標 (A pointer to an array of 10 integers)
+ Q7.一個指向函式的指標，該函式有一個整數型參數並回傳一個整數(A pointer to afunction that takes an integer as an argument and returns an integer)
+ Q8.一個有 10 個指標的陣列，該指標指向一個函式，該函式有一個整數型參數並回傳一個整數(An array of ten pointers to functions that take an integer argument and return an integer)

ANS：
```
A1.int a; // An integer
A2.int *a; // A pointer to an integer
A3.int **a; // A pointer to a pointer to an integer
A4.int a[10]; // An array of 10 integers
A5.int *a[10]; // An array of 10 pointers to integers
A6.int (*a)[10]; // A pointer to an array of 10 integers
A7.int (*a)(int); // A pointer to a function a that takes an integer argument and returns an integer
A8.int (*a[10])(int); // An array of 10 pointers to functions that take an integer argument and return an integer
```

測試目的︰
1. 參數宣告的基本知識。
2. 指標的應用。
3. 函式指標的應用。

# Q6： 關鍵字 static 的作用是什麼？

ANS：
```
A1.在函式內 (in Function Block)，一個被宣告為靜態的變數，在這一函數被呼叫過程中維持其值不變。
A2.在一個 Block (ie. {...} ) 內 (但在函式外)，一個被宣告為靜態的變數可以被 Block 內所有的函式存取，但不能被 Block 外的其它函式存取，它是一個區域的全域變數。
A3.在 Block 內，一個被宣告為靜態的函式，只可被這 Block 內的其它函式呼叫。
```

測驗目的：
1. 靜態變數的宣告。
2. 靜態函式的宣告及使用。
3. 本地化資料和程式碼範圍的好處和重要性。


# Q7： 關鍵字 const 在下列式子中具備甚麼含意？
+ Q1.const int a;
+ Q2.int const a;
+ Q3.const int *a;
+ Q4.int * const a;
+ Q5.int const * a const;

ANS：
```
A1.a 是一個常數型整數。
A2.a 是一個常數型整數。
A3.a 是一個指向常數型整數的指標 (也就是，整型數是不可修改的，但指標可以)。
A4.a 是一個指向整數的常數型指標 (也就是說，指標指向的整數是可以修改的，但指標是不可修改的)。
A5.a 是一個指向常數型整數的常數型指標 (也就是說，指標指向的整數是不可修改的，同時指標也是不可修改的)。
```

測驗目的：
1. 關鍵字 const 的作用是給閱讀你程式碼的人傳達非常有用的訊息，實際上，宣告一個參數為常量是為了告訴了程式員這個參數的應用目的。
2. 透過給編譯器一些附加的訊息，使用關鍵字 const 也許能產生更優化的程式碼。
3. 合理地使用關鍵字 const 可以使編譯器很自然地保護那些不希望被改變的參數，防止其被無意的程式碼修改。


# Q8： 關鍵字 volatile 有什麼含意？

ANS：
```
一個定義為 volatile 的變數，是說這變數可能會被意想不到地改變，這樣，編譯器就不會去假設這個變數的值了。精確地說就是，編譯器在用到這個變數時，必須每次都小心地重新讀取這個變數的值，而不是使用保存在暫存器裡的備份。

下面是volatile變量的幾個例子︰
E1.並行設備的硬體暫存器 (如︰狀態暫存器)。
E2.一個中斷服務次程序中會訪問到的非自動變數 (Non-automatic variables)。
E3.多執行緒應用中被多個任務 (task) 共享的變數。
```

延伸 Question：
+ Q1.一個參數可以同時是 const 也是 volatile 嗎？
+ Q2.一個指標可以是 volatile 嗎？
+ Q3.下面的函式有什麼錯誤？

```
int square (volatile int *ptr)
{
    return *ptr * *ptr;
}
```
ANS：
+ A1.Yes (ex：唯讀的狀態暫存器，它是 volatile 因為它可能被意想不到地改變，它是 const 因為程式不應該試圖去修改它)。
+ A2.Yes (ex：一個執行中的次程序修改一個指向一個 buffer 的指標時)。
+ A3.這段程式碼的目的是用來返指標 `*ptr` 指向值的平方，由於 `*ptr` 指向一個 volatile 型參數，編譯器將產生類似下面的程式碼︰

```
int square (volatile int *ptr)
{
    int a, b;
    a = *ptr;
    b = *ptr;

    return a * b;
}
```
由於 *ptr 的值可能被意想不到地改變，因此 a 和 b 可能是不同的值。結果，這段程式碼可能返回不是你所期望的平方值。

正確的程式碼如下︰
```
long square (volatile int *ptr)
{
    int a;
    a = *ptr;

    return a * a;
}
```


# Q9： 位元操作 (Bit Manipulation)，給定一個整型變量 a，寫兩段程式碼，第一個設置 a 的 bit 3，第二個清除 a 的 bit 3，在以上兩個操作中，要保持其它位不變。

ANS：
```
#define BIT3 (0x1 << 3)

void set_bit3 (void)
{
    a |= BIT3;
}

void clear_bit3 (void)
{
    a &= ~BIT3;
}
```

測驗目的：
1. 位元運算，`=` 和 `&=~` 操作。

# Q10： 存取固定的記憶體位置 (Accessing fixed memory locations)，設定一個絕對位址為 0x67a9 的整數型變數的值為 0xaa55，編譯器是一個純粹的 ANSI 編譯器。

ANS：
```
A1.
int *ptr;
ptr = (int *)0x67a9;
*ptr = 0xaa55;

A2.
*(int * const)(0x67a9) = 0xaa55;
```

測驗目的：
1. 為了存取絕對位址把一個整數型強制轉型 (typecast) 為指標是合法的。


# Q11： 中斷 (Interrupts)，下面的程式碼使用了 `__interrupt` 關鍵字去定義了一個中斷服務次程序(ISR)，請評論一下這段程式碼的錯誤。

```
__interrupt double compute_area(double radius)
{
    double area = PI * radius * radius;
    printf("\nArea = %f"， area);

    return area;
}
```

ANS：

```
A1.ISR 不能回傳一個值。
A2.ISR 不能傳遞參數。
A3.有些處理器/ 編譯器就是不允許在 ISR 中做浮點運算。
A4.ISR 應該是短而有效率的，在 ISR 中做浮點運算是不明智的。
A5.printf() 經常有 I/O 和性能上的問題。
```


# Q12： 程式碼例子 (Code examples)，下面的程式碼輸出是什麼？

```
void foo(void)
{
    unsigned int a = 6;
    int b = -20;
    (a+b > 6) ? puts("> 6") : puts("<= 6") ;
}
```
ANS：
```
">6"
```

測驗目的：
1. 是否懂得 C 語言中的整數自動轉型原則


# Q13： 評價下面的程式碼片斷。

```
unsigned int zero = 0;
unsigned int compzero = 0xFFFF; /* 1's complement of zero */
```
ANS：
```
對於一個 int 型不是 16 位的處理器為說，上面的程式碼是不正確的，應編寫如下︰
unsigned int compzero = ~0;
```

測驗目的：
1. 是否懂得編譯器資料長度的重要性


# Q14： 動態記憶體分發 (Dynamic memory allocation)。
+ Q1.嵌入式系統中，動態分配記憶體可能發生的問題是什麼？
+ Q2.下面的程式碼片段的輸出是什麼，為什麼？

```
char *ptr;
if (( ptr = (char *)malloc(0)) == NULL)
    puts("Got a null pointer");
else
    puts("Got a valid pointer");
```

ANS：

```
A1.
1.記憶體的生命週期管理。
2.記憶體不足。

A2.
"Got a valid pointer"
```

測驗目的：
1. 記憶體碎片，碎片收集的問題。
2. 變數的生命週期。


# Q15： Typedef 在 C 語言中頻繁用以宣告一個已經存在的資料型態的同義字，也可以用預處理器做類似的事，例如，思考一下下面的例子︰

```
#define dPS struct s*
typedef struct s * tPS;
```
以上兩種情況的意圖都是要定義 dPS 和 tPS 作為一個指向結構 s 指標，哪種方法更好呢？

ANS︰
```
typedef更好。
dPS p1, p2;
tPS p3, p4;

第一個擴展為 struct s *p1, p2;
上面的程式碼定義 p1 為一個指向結構的指標，p2 為一個實際的結構。

第二個擴展為 struct s *p3, *p4;
第二個例子正確地定義了 p3 和 p4 兩個指標。
```


# Q16： 艱澀的語法，C語言允許一些令人震驚的結構，下面的結構是合法的嗎，如果是，它做些什麼？
```
int a = 5, b = 7, c;
c = a+++b;
```
ANS：

```
完全合法。
上面的程式碼被處理成︰
c = a++ + b;
因此，這段程式碼執行後：
a = 6, b = 7, c = 12
```

測驗目的：
1.編譯器如何處理
2.程式碼編寫風格，程式碼的可讀性/ 可修改性

