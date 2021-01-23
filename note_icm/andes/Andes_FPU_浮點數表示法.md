Andes FPU 浮點數表示法
---


# Andes FPU是依據IEEE754所設計的.

+ 單精度浮點數

```
32-bits single-precision floating-point format

 31   30           23 22                0
+----+---------------+-------------------+
| S  | Exponent [e]  | Significant [f]   |
+----+---------------+-------------------+
```

    - S
        > 浮點數符號(1代表負數).
    - 指數 (Exponent)
        > 8 位元(含指數符號).
    - 有效數字 (Significant)
        > 23 位元的小數.

+ 雙精度浮點數

```
64-bits double-precision floating-point format

 63   62           52 51                0
+----+---------------+-------------------+
| S  | Exponent [e]  | Significant [f]   |
+----+---------------+-------------------+
```

    - S
        > 浮點數符號(1代表負數).
    - 指數 (Exponent)
        > 11 位元(含指數符號).
    - 有效數字 (Significant)
        > 52 位元的小數.