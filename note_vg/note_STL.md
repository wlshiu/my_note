C++ STL
---

# Container Categories

屬於這個 category 的 class, 都有定義自己的 iterator, 以做遍尋 items

```
for(xxx<...>::iterator pIter = y.begin(); pIter != y.end(); pIter++)
{
    ...
}
```

+ the basis iterator methods

    - `begin()`
        > 回傳一個 iterator, 它指向第一個元素
    - `end()`
        > 回傳一個 iterator, 它指向最後一個元素的下一個位置(它不是最末元素)
    - `rbegin()`
        > 回傳一個反向 iterator, 它指向最後一個元素
    - `rend()`
        > 回傳一個 iterator, 它指向的第一個元素
    - `size()`
        > 取得目前持有的元素個數

    - `max_size()`
    - `empty()`
        > 如果內部為空, 則傳回 true 值
    - `front()`
        > Returns the first element in the container
    - `back()`
        > Returns the last element in the container.
    - `assign()`
        > Replaces the contents of the container

        ```c++
        vector<char>    characters;
        characters.assign(5, 'a');      // output: a a a a a
        characters.assign({'\n', 'C', '+', '+', '1', '1', '\n'}); // output: C++11
        ```

    - `swap()`


+ `pair` template class
    > a simple container with 2-tuple objects.
    >> this class has not iterator.

    ```c++
    paie<x_obj, y_obj>      my_pair;

    cout << my_pair.first << endl;
    cout << my_pair.second << endl;
    ```

    ```c++
    // initialize
    paie<int, string>(3, "test")
    ```

+ `vector` template class
    > dynamic array like array of C langrange and support `random access`

    ```c++
    #include <vector>
    vector<x_obj>       my_vec;
    ```

    - `push_back()`
        > push the object to the next empty element of a vector

        ```c++
        my_vec.push_back(obj);
        ```

    - `pop_back()`
        > Removes the last element of the container

    - `capacity()`
        > 得 vector 目前可容納的最大元素個數.
        這個方法與記憶體的配置有關, 它通常只會增加, 不會因為元素被刪減而隨之減少

    - `reserve()`
        > 如有必要, 可改變 vector 的容量大小(配置更多的記憶體).
        在眾多的 STL 實做, 容量只能增加, 不可以減少

    - `at()`
        > return the element at specified position with bounds checking

        ```c++
        for(unsigned int i = 0; i < my_vec.size(); i++ )
            cout << my_vec.at(i) << endl;
        ```

    - operator `[]`
        > directly access like array of C-langrange, it doesn't check the bounds

    - `data()`
        > Returns pointer to the underlying array

    - `erase()`
        > Erases the specified elements from the container.
        The iterator pos must be valid and dereferenceable.

    - example

        ```c++
        vector<int>     my_vec; // Array Random Access

        cout << "start: cap= " << my_vec.capacity() << endl;
        for(int i = 0; i < 5; i++)
        {
            my_vec.push_back(i);
            cout << "cap= " << my_vec.capacity() << endl;
        }

        cout << "size= " << my_vec.size() << endl;
        for(unsigned int i = 0; i < my_vec.size(); i++ )
            cout << my_vec.at(i) << endl;
        ```

+ `queue` template class
    > first input first output

    ```c++
    #include <queue>
    queue<x_obj>       my_q;
    ```

+ `map` template class
    > + use red-black tree to implement
    > + use key-value data structure (自動按Key升序排序)
    > + compare with `unordered_map`
    >> - memory 需求較小些
    >> - performance 穩定, 在數量小於 1000 時,
    與 `unordered_map` 差不多 (需要 maintain RB-Tree)

    ```c++
    #include <map>
    map<key_obj, value_obj>     my_map;
    ```

+ `unordered_map` template class
    > + use hash table to implement
    > + key-value data structure
    >> 無排序, 且key是唯一, 同樣的 key, value 都會被取代
    > + compare with `map`
    >> - memory 需求較大
    >> - performance 較好 (直接存取)

    ```c++
    #include <unordered_map>
    unordered_map<key_obj, value_obj>      umap;
    ```

    - `insert()`
        > Inserts new elements in the unordered_map.

        ```c++
        umap.insert(make_pair<int, string>(3, "I am 3"));
        ```

    - `find()`
        > find the element with specified key.
        If no exsit, return the `unordered_map::end()`

    - `count()`
        > search the element with specified key and return the amount.
        Because use key-value pair, it will return 1 if an element with that key exists in the container,
        and zero otherwise

    - example

        ```c++
        #include <unordered_map>
        unordered_map<int, string>      umap;

        umap.insert(make_pair<int, string>(3, "I am 3"));
        umap.insert(make_pair<int, string>(5, "I am 5"));
        for(unordered_map<int, string>::iterator pIter = umap.begin(); pIter != umap.end(); pIter++)
        {
            cout << pIter->first << ": " << pIter->second << endl;
        }
        ```

+ `list` template class
    > doubly linked list

    ```c++
    #include <list>
    ```

+ `stack` template class
+ `set` template class
+ `deque` template class

# Concept

+ Call by ...

    - Call by value
        > 參數以數值方式傳遞, 複製一個副本給另一個副程式, 兩個參數各自獨立互不影響
    - Call by pointer
        > Call by value的變形, 將變數的address傳到副程式, 而副程式使用一個 pointer 接住這個address,
        因此副程式的這個 pointer 可以指向並修改這個數值
    - Call by reference (C++ support)
        > 目的和 `Call by pointer`是一樣的, 都是想要指回原本的變數並且可以修改.
        不過 `Call by reference` 寫起來更簡單
        >> `call by pointer`在每次傳 address 都要加個 `&`, 而在副程式裡需要加 `*` 來指向原本的實體.
        因此，C++新增了 `Call by reference` 的方式, 讓在丟變數到副程式時, `不用加 &`,
        而在副程式參做此變數也`不用加 *`號就可以直接修改其變數.
        **唯一要寫的是: 在副程式 interface 中的參數裡加上 &**, 代表是 `Call by reference`

        ```
        void foo(int &x)
        {
            x++; // 修改此x就是修改main的x
        }

        int main()
        {
            int     x = 5;
            foo(x); // 不用加&
        }
        ```

# MISC

+ windows show process memory

```
#include <psapi.h>
#pragma comment(lib,"psapi.lib")

void showMemoryInfo(void)
{
	HANDLE                      handle = GetCurrentProcess();
	PROCESS_MEMORY_COUNTERS     pmc;
	GetProcessMemoryInfo(handle, &pmc, sizeof(pmc));
	cout << "Memory Use:"
         << pmc.WorkingSetSize / 1024.0f << "KB/"
         << pmc.PeakWorkingSetSize / 1024.0f << "KB"
         << "Virtual Memory Use:"
         << pmc.PagefileUsage / 1024.0f << "KB/" << pmc.PeakPagefileUsage / 1024.0f << "KB"
         << endl;
}

```


# reference

+ [CppReference](https://en.cppreference.com/w/)
+ [Standard Containers](http://www.cplusplus.com/reference/stl/)
+ [Standard Template Library](https://en.wikipedia.org/wiki/Standard_Template_Library#Containers)
+ [Sequence container C++](https://en.wikipedia.org/wiki/Sequence_container_(C%2B%2B)#Vector)
+ [G. T. Wang blog](https://blog.gtwang.org/programming/)
    - [auto 自動變數類型](https://blog.gtwang.org/programming/cpp-auto-variable-tutorial/)

