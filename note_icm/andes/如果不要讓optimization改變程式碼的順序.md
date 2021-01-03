如果不要讓optimization改變程式碼的順序，
可以加2個options
`-fno-schedule-insns` and `-fno-schedule-insns2`
上面2個都要加...因為會有2階段可能會對code做重排序。
