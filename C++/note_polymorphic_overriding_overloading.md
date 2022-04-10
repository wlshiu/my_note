polymorphism(多型), overriding(覆寫), overloading(多載)
---

```c++
// Superclass(父類別)
class Animal()
{
    void sound()
    {
    }
}

// Subclass(子類別)
class Dog extends Animal
{
    // 覆寫 Animal.sound()
    void sound()
    {
        汪汪();
    }

    // 多載 Dog.sound()
    void sound(int i)
    {
    }

    // 多載 Dog.sound()
    void sound(String s, int i)
    {
    }
}

// Subclass(子類別)
class Cat extends Animal
{
    // 覆寫 Animal.sound()
    void sound()
    {
        喵喵();
    }
}

// main
void main()
{
    // 以父類建立具有子類方法的物件
    Animal dog = new Dog();
    Animal cat = new Cat();

    // 以子類建立具有父類方法的物件, 執行產生錯誤(runtime error)
    Dog d = (Dog)new Animal();
    ..
    ..
    dog.sound(); // 將會執行 汪汪();
}
```

+ polymorphism(多型)
    > 在 main() 裡 dog, cat 的宣告方式即稱為多型.

    > 須注意的是因 Dog/Cat 為繼承 Animal 的 sub-class, 所以 Animal 所有 (default 以上) 的 methods, Dog/Cat class 都具有.
    但是 Animal 不能確保擁有 Dog/Cat 其擁有的 methods, 因此**反過來宣告則會在執行時期產生錯誤**.

    > 就以 dog 來說, dog 雖是屬於 Animal 的 objectg, 但是其中 methods 的部分只要 Dog class 有覆寫, 就會以 Dog class 的為主.
    >> 簡單說, 就是宣告出一個 Animal (parent) class, 同時將 Dog(child) class 所擁有的 methods, 取代(覆寫, overriding) Animal(parent) class中的 methods, 產生出 dog objectg


+ overriding(覆寫)
    > Dog class 和 Cat class 皆是繼承 Animal 的 child-class, 在其中各自改寫了 sound() 的 method, 此稱之.
    >> 須注意的是 **同型別且同參數** 才是覆寫, 若 **不同型別卻同參數** 則會發生編譯錯誤

+ overloading(多載)
    > 在 Dog class 裡有兩個 sound() 的 methods 但參數不同, 會在呼叫時依照給予的參數, 決定使用哪一個 sound()
    >> 須注意的是**同型別且不同參數**或**不同型別且不同參數**才是多載

