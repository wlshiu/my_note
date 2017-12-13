C++11
---

+ `auto`
    > 在編譯時自動對變量進行了類型推導，所以不會對程序的運行效率造成不良影響; 可方便使用於 template
    ```
    auto a; // 錯誤，auto是通過初始化表達式進⾏類型推導，如果沒有初始化表達式，就無法確定 a 的類型
    auto i = 1;
    auto d = 1.0;
    auto str = "Hello World";
    auto ch = 'A';
    ```

    > 不能用於函數傳參數, 但可以用在 Lambda函數
    ```
    int add(auto x, auto y);        // error

    auto add = [](auto x, auto y) { return x+y; };  // ok
    ```

+ `decltype`
    > 通過一個變量(或表達式)回推型別, 可方便使用於 template


+ `後置 return type`
    > 這樣的語法用於在編譯時返回類型還不確定的場合 <\br>
    > 比如有模版的場合中，兩個類型相加的最終類型只有運行時才能確定

    ```
    int adding_func(int lhs, int rhs);

    // 後置 return type
    auto adding_func(int lhs, int rhs) -> int
    ```

+ `nullptr`
    > C++11 的一個關鍵字，一個內建的標識符(空指針標識), 應與 常用的 NULL 宏相區別
    >> 通常 NULL會被當作 0, 但 0 本身可能有其他意義

+ `支援 range-based for loop`
    > 類似 javascript 簡化 for loop

    ```
    int my_array[5] = {1, 2, 3, 4, 5};
    for (auto &x : my_array) {
        x *= 2;
    }
    ```

+ `Lambda函數 or Lambda表達式`
    > 在需要一個函數，但是又不想費神去命名一個函數的場合下使用，也就是指匿名函數

    ```
    static bool my_cmp (int i,int j)
    {
        return (i<j);
    }

    void main ()
    {
        ...
        std::sort (myvector.begin(), myvector.end(), my_cmp);
    }

    // Lambda
    sort(myvector.begin(), myvector.end(), [](int i, int j) { return i< j; });
    ```

    - 語法
        > 以方括號開頭
        ```
        [ captures ] ( input_arguments ) -> ret { func_body }
        [ captures ] ( input_arguments ) { func_body }
        [ captures ] { func_body }

        /**
         * captures (use external variable): cnt
         * input argument: int &x
         * no return:
         * function instance: { ... }
         */
        int foo()
        {
            int cnt = 2;

            ...

            [cnt](int &x){ cout<<(x + cnt) << endl; });
        }

        /**
         * captures (use external variable): all external variables, '=' means 'all'
         * input argument: int &x
         * return: int
         * function instance: { ... }
         */
        [=](int &x)->int{ return x * (a + b); }
        ```

    - captures
        1. description
            ```
            []        // 沒有定義任何變量，但必須列出空的方括號。在 Lambda表達式中嘗試使用任何外部變量都會導致編譯錯誤。
            [x, &y]   // x 是按值傳遞，y 是按引用傳遞
            [&]       // 任何被使用到的外部變量都按引用傳入。
            [=]       // 任何被使用到的外部變量都按值傳入。
            [&, x]    // x 按值傳入。其它變量按引用傳入。
            [=, &z]   // z 按引用傳入。其它變量按值傳入。
            ```
        1. captured by copy
            > 類似 call by value

            ```
            void learn_lambda_func_1()
            {
                int value_1 = 1;

                // captured by copy, value_1 已被 copy_value_1 保存
                auto copy_value_1 = [value_1] {
                    return value_1;
                };

                value_1 = 100;
                auto stored_value_1 = copy_value_1();

                // 這時, stored_value_1 == 1, 而 value_1 == 100.
                // 因為 copy_value_1 在創建時就保存了一份 value_1 的拷貝
            }
            ```

        1. captured by reference
            > 類似 call by reference

            ```
            void learn_lambda_func_2()
            {
                int value_2 = 1;

                // captured by reference, 呼叫時,會 run-time 參考 value_2
                auto copy_value_2 = [&value_2] {
                    return value_2;
                };

                value_2 = 100;
                auto stored_value_2 = copy_value_2();

                // 這時, stored_value_2 == 100, value_1 == 100.
                // 因為 copy_value_2 保存的是引用
            }
            ```


+ `Raw string literals`
    > 自動判別轉義(escape)操作符(反斜線 `\`)

    ```
    /**
     * pattern: '\w\\w'
     */

    string s = "\\w\\\\\\w";

    // C++11
    string s = R"(\w\\\w)";
    ```

+ `Initializer lists`
    > 可使用列表來初始化

    ```
    auto x = max( {x,y,z}, Nocase() );

    struct myclass {
        myclass (int, int);
        myclass (initializer_list<int>);
        /* definitions ... */
    };

    myclass bar (10,20);  // calls first constructor

    myclass foo {10,20};  // calls std::initializer_list (template) constructor

    ```

+ `constexpr`
    > 編譯期計算, 提升程序執行時的效果

    ```
    constexpr int multiply (int x, int y)
    {
        return x * y;
    }

    // 將在編譯時計算
    const int val = multiply( 10, 10 );
    cin >> x;
    // 由於輸入參數x只有在運行時確定，所以以下這個不會在編譯時計算，但執行沒問題
    const int val2 = mutliply（x,x)
    ```

+ `using`
    > 別名宣告(Alias Declaration), 類似 `typedef`, 但可以對 template 定義一個新名稱

    ```
    typedef int (*process)(void *);  // 定義了一個返回類型為 int，參數為 void* 的函數指針類型，名字叫做 process
    using process = void(*)(void *); // 同上, 更加直觀

    typedef SuckType<std::vector, std::string> NewType;  // 不合法
    using NewType = SuckType<std::vector, std::string>;  // template
    ```

+ Smart pointe

    - `std::shared_ptr`
        > 能夠記錄多少個 shared_ptr 共同指向一個 object，當 ref_cnt 變為零的時候就會將 object 自動刪除。

        ```
        #include <memory>

        void foo(std::shared_ptr<int> i) { (*i)++; }

        int main()
        {
            // auto pointer = new int(10); // 非法, 不允許直接賦值
            // 構造了一個 std::shared_ptr
            auto pointer = std::make_shared<int>(10);

            foo(pointer);

            std::cout << *pointer << std::endl; // ouptu 11

            // 離開作用域前，shared_ptr 會被析構，從而釋放內存
            return 0;
        }
        ```

        1. method
            a. `get()`
                > 獲取原始指針

                ```
                auto pointer = std::make_shared<int>(10);
                auto pointer2 = pointer;    // 引用計數+1
                auto pointer3 = pointer;    // 引用計數+1
                int *p = pointer.get();             // 這樣不會增加引用計數
                ```

            a. `reset()`
                > 減少一個 ref_cnt
            a. `get_count()`
                > 查看一個 object 的 ref_cnt


    - `std::unique_ptr`
        > 獨佔的 Smart pointe，它禁止其他 Smart pointe 與其共享同一個 object，從而保證代碼的安全

        > std::unique_pt 不可複製。但可以利用 std::move 將其轉移給其他的 unique_ptr

        ```
        /**
         * make_unique 從 C++14 引入
         * C++11 沒有提供 std::make_unique, 因為被忘記了
         */
        std::unique_ptr<int> pointer = std::make_unique<int>(10);
        std::unique_ptr<int> pointer2 = pointer;    // 非法
        ```

        ```
        /**
         * implement 'std::make_unique'
         */
        template<typename T, typename ...Args>
        std::unique_ptr<T> make_unique( Args&& ...args ) {
            return std::unique_ptr<T>( new T( std::forward<Args>(args)... ) );
        }
        ```

    - `std::weak_ptr`
        > std::weak_ptr 是一種弱引用(相比較而言 std::shared_ptr 就是一種強引用)。弱引用不會引起引 ref_cnt 增加



+ 委託構造函數(Delegating constructors)
    > 簡化一個 class 中的 constructor 調用另一個 constructor (多型)
    ```
    class foo {
        int a;
        // 實現一個初始化函數
        validate(int x) {
            if (0<x && x<=max) a=x;
            else throw bad_X(x);
        }
    public:
        // 三個構造函數都調用validate()，完成初始化工作
        foo(int x) { validate(x); }
        foo() { validate(42); }
        foo(string s) {
            int x = lexical_cast<int>(s); validate(x);
        }
        // …
    };


    /** C++11 **/
    class foo {
        int a;
    public:
        foo(int x) {
            if (0<x && x<=max) a=x;
            else throw bad_X(x);
        }

        // 構造函數 foo()調用構造函數 foo(int x)
        foo() : foo{42} { }

        // 構造函數 foo(string s)調用構造函數 foo(int x)
        foo(string s) : foo{lexical_cast<int>(s)} { }
        // …
    };
    ```


+ `override`
    > 告知編譯器進行重載，編譯時期, 將檢查 parent (base) class 是否存在這樣的 virtual function

    ```
    struct Base {
        virtual void foo(int);
    };

    struct SubClass: Base {
        virtual void foo(int) override; // 合法
        virtual void foo(float) override; // 非法, 父類沒有此虛函數
    };
    ```

+ `final`
    > 防止 class 被繼續繼承以及終止 virtual function 繼續重載引入

    ```
    struct Base {
            virtual void foo() final;
    };
    struct SubClass1 final: Base {
    };                  // 合法


    struct SubClass2 : SubClass1 {
    };                  // 非法, SubClass1 已 final

    struct SubClass3: Base {
            void foo(); // 非法, foo 已 final
    };
    ```

+ `enum class`
    > 實現了類型安全，首先他不能夠被隱式的轉換為整數，同時也不能夠將其與整數數字進行比較，
    > 更不可能對不同的枚舉類型的枚舉值進行比較。但相同枚舉值之間可以進行比較

    ```
    enum class my_enum : unsigned int {
        value1,
        value2,
        value3 = 100,
        value4 = 100
    };
    ```

+ `explicit`
    > 只對構造函數(constructor)起作用，用來抑制隱式轉換, 可以有效得防止構造函數的隱式轉換帶來的錯誤或者誤解
    ```
    class String {
        explicit String ( int n ); // 本意是預先分配n個字節給字符串
        String ( const char* p ); // 用C風格的字符串p作為初始化值
        //…
    }

    下面兩種寫法仍然正確：
        String s2 ( 10 );           //OK 分配10個字節的空字符串
        String s3 = String ( 10 );  //OK 分配10個字節的空字符串

    下面兩種寫法就不允許了：
        String s4 = 10;   //編譯不通過，不允許隱式的轉換; 若允許隱式的轉換, 則分配10個字節的空字符串
        String s5 = 'a';  //編譯不通過，不允許隱式的轉換; 若允許隱式的轉換, 則分配 int('a') 個字節的空字符串
    ```

+ `delete` 與 `default`
    > 控制預設函式

    - 開發者自己定義一個新的類別的話，就算在什麼都沒有寫的情況下，編譯器也會自動產生一些預設的函式。 <\br>
      所以，我們定義的類別才可以很方便地直接被建構、刪除、複製。 <\br>
      而這些函式包括了：

        1. 預設建構函式(default constructor)
            > `sampleClass()`
        1. 複製建構函式(copy constructor)
            > `sampleClass( const sampleClass& )`
        1. 複製指派運算子(copy assignment operator)
            > `sampleClass& operator= ( const sampleClass& )`
        1. 解構函式(destructor)
            > `~sampleClass()`

    ```
    class NonCopyable
    {
    public:
        NonCopyable() = default;
        NonCopyable(const NonCopyable&) = delete;
        NonCopyable& operator=(const NonCopyable&) = delete;
    };

    在 copy constructor 與 copy assignment operator 的宣告後面都加上了 "= delete"，
    藉此讓編譯器知道這兩個函式是不需要的，之後如果呼叫的話，就會產生編譯階段的錯誤。

    在 default constructor 後面加上了 "= default"，是告訴編譯器這邊雖然重新宣告了 default constructor，
    但是還是要使用編譯器預設產生的版本。
    ```

+ `struct` and `class`
    > In C++, `struct` defaults to public access and `clas`s defaults to private access.
    >> more people rarely declare `struct` just to save on typing the *public* keyword.



