三角函數 [[Back](note_FOC.md##Trigonometric-functions)]
---

+ 弧度 radian (rad) `0 ~ 2π`

    ```
    #define PI                          3.14159f
    #define degree2rad(__degree__)      (((__degree__) * PI) / 180)
    ```

+ 角度 degree `0° ~ 360°`

    ```
    #define PI                          3.14159f
    #define rad2degree(__rad__)         (((__rad__) * 180)/PI)
    ```


## 數學觀念

```
   ^ Y-axis
   |
   |    (x, y)
   |    /|
   | r / | y
   |  /  |
   | /θ  |
---+-----+-------------> X-axis
   |  x


 * sin(θ) = (y/r)
 * cos(θ) = (x/r)
 * tan(θ) = (y/x)

 * arcsin(θ) = (r/y)
 * arccos(θ) = (r/x)
 * arctan(θ) = (x/y)

```


## math lib of clib

+ `sin()/asin()`

    ```
    sin_value = sin(radian)
    radian    = asin(sin_value)

    note. -1 < sin_value < 1
           0 <   radian  < 2π
    ```

+ `cos()/asin()`

    ```
    cos_value = cos(radian)
    radian    = acos(cos_value)

    note. -1 < sin_value < 1
           0 <   radian  < 2π
    ```

+ `tan()/atan()/atan2()`

    ```
    tan_value = tan(radian)
    radian    = atan(tan_value) = atan(x/y), tan_value = (x/y)
    radian2   = atan2(y, x)     = x/y (傳入 x, y 座標值)

    note. -Infinity < tan_value < Infinity
               -π/2 <   radian  < π/2
               -π   <   radian2 < π

    ```

    - fast_atan2
        > ref. [Atan2 Faster Approximation](https://math.stackexchange.com/a/1105038/81278)

        ```
        float fast_atan2(float y, float x)
        {
            // a := min (|x|, |y|) / max (|x|, |y|)
            float   abs_y = fabsf(y);
            float   abs_x = fabsf(x);
            // inject FLT_MIN in denominator to avoid division by zero
            float   a = min(abs_x, abs_y) / (max(abs_x, abs_y));

            // s := a * a
            float   s = a * a;

            // r := ((-0.0464964749 * s + 0.15931422) * s - 0.327622764) * s * a + a
            float r =
                ((-0.0464964749f * s + 0.15931422f) * s - 0.327622764f) * s * a + a;

            // if |y| > |x| then r := 1.57079637 - r
            if (abs_y > abs_x)
                r = 1.57079637f - r;

            // if x < 0 then r := 3.14159274 - r
            if (x < 0.0f)
                r = 3.14159274f - r;

            // if y < 0 then r := -r
            if (y < 0.0f)
                r = -r;

            return r;
        }
        ```




