ARM GNU Binutils
---

## nm
+ sy
## size
+ simple section size
    ```
    $ size.exe ap_mode.axf
    ```

    
## objdump
+ Display the contents of the symbol table

    ```
    $ objdump.exe -t mode.axf
    ```

## readelf
+ Display the sections

    ```
    $ readelf.exe -S mode.axf
    ```

## strip
+
    ```
    $ strip -d mode.axf
    ```



# Reduce code size
+ compiler optimize
    - `O0` ~ `O3`

+ strip debug info
    ```
    # check symbol sections
    $ readelf -S hello
    Section Headers:
        [Nr] Name Type
        [ 0] NULL
        [ 1] .interp PROGBITS
        [ 2] .note.ABI-tag NOTE
        [ 3] .hash HASH
        [ 4] .dynsym DYNSYM
        [ 5] .dynstr STRTAB
        [ 6] .gnu.version VERSYM
        [ 7] .gnu.version_r VERNEED
        [ 8] .rel.dyn REL
        [ 9] .rel.plt REL
        [10] .init PROGBITS
        [11] .plt PROGBITS
        [12] .text PROGBITS
        [13] .fini PROGBITS
        [14] .rodata PROGBITS
        [15] .eh_frame PROGBITS
        [16] .data PROGBITS
        [17] .dynamic DYNAMIC
        [18] .ctors PROGBITS
        [19] .dtors PROGBITS
        [20] .jcr PROGBITS
        [21] .got PROGBITS
        [22] .bss NOBITS
        [23] .comment PROGBITS
        [24] .debug_aranges PROGBITS
        [25] .debug_pubnames PROGBITS
        [26] .debug_info PROGBITS
        [27] .debug_abbrev PROGBITS
        [28] .debug_line PROGBITS
        [29] .debug_frame PROGBITS
        [30] .debug_str PROGBITS
        [31] .shstrtab STRTAB
        [32] .symtab SYMTAB
        [33] .strtab STRTAB

    # strip debug sections
    $ strip hello
    ```
+ remove misc info, e.g. comment section, note section, gnu.version section
    ```
    $ objcopy -R .comment -R .note.ABI-tag -R .gnu.version hello hello1
    ```


