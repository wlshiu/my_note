Graph Easy
---

`Graph::Easy` 是一個處理圖形 DSL 的 Perl 模塊, 它有如下功能
> + 提供了一種易懂, 可讀性很強的圖形描述語言
> + 一種支持 ASCII Art 的基於網格的佈局器
> + 可以導出為 Graphviz, VCG(Visualizing Compiler Graphs), GDL(Graph Description LAnguages) 和 GraphML格式
> + 可以從Graphviz, VCG 和 GDL 導入圖像

# Setup

## Windows

+ Install perl-5

+ Add perl-5 path to environment variable of cmder

+ execute `cpan` of perl

    ```
    λ perl -MCPAN -e shell
    cpan>
    ```

    - install

        ```
        cpan> install Graph::Easy::As_svg
        cpan> install Graph::Easy
        ```

    - exit `cpan`

        ```
        cpan> exit
        ```

+ check version

    ```
    λ graph-easy --version
    ```

+ generate ascii flow

    ```
    λ graph-easy --input openocd_cmd_arch.ge --output openocd_arch.txt
    ```

# Reference

+ [Graph::Easy - CN](https://weishu.gitbooks.io/graph-easy-cn/content/)
+ [Graph::Easy - Manual](http://bloodgate.com/perl/graph/manual/tutorial.html)
+ [how to create specific graph layouts](http://bloodgate.com/perl/graph/manual/hinting.html)
+ [graph easy繪制ascii簡易流程圖](https://xuxinkun.github.io/2018/09/03/graph-easy/)
+ [Graph-Easy- github](https://github.com/ironcamel/Graph-Easy/tree/master/t/txt)

