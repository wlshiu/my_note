bash
---


# delete '/*!' to line end

```
$ sed -i 's/\/\*\!.*$//' $FILENAME
```

# 多空格替換成單空格

```
$ sed -e 's/[[:space:]][[:space:]]*/ /g'
```
