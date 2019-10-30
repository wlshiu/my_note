ARM GNU Binutils
---
[GNU Binary Utilities] (https://sourceware.org/binutils/docs-2.30/binutils/index.html)

## ar
+ replace or append object file
    ```
    # replace the same object file if exsit or append object file
    # ar -rv [output file] [object files...]
    $ ar -rv ./libfoo_new.a ./version.o ./libfoo.a
    ```

## nm
+ symbol type
    - `A`
        > The symbol's value is absolute, and will not be changed by further linking.

    - `B`/`b`
        > The symbol is in the uninitialized data section (known as BSS).

    - `C`
        > The symbol is common. Common symbols are uninitialized data. When linking, multiple common symbols may appear with the same name. If the symbol is defined anywhere, the common symbols are treated as undefined references. For more details on common symbols, see the discussion of –warn-common in Linker options in The GNU linker.

    - `D`/`d`
        > The symbol is in the initialized data section.

    - `G`/`g`
        > The symbol is in an initialized data section for small objects. Some object file formats permit more efficient access to small data objects, such as a global int variable as opposed to a large global array.

    - `i`
        > For PE format files this indicates that the symbol is in a section specific to the implementation of DLLs. For ELF format files this indicates that the symbol is an indirect function. This is a GNU extension to the standard set of ELF symbol types. It indicates a symbol which if referenced by a relocation does not evaluate to its address, but instead must be invoked at runtime. The runtime execution will then return the value to be used in the relocation.

    - `I`
        > The symbol is an indirect reference to another symbol.

    - `N`
        > The symbol is a debugging symbol.

    - `p`
        > The symbols is in a stack unwind section.

    - `R`/`r`
        > The symbol is in a read only data section.

    - `S`/`s`
        > The symbol is in an uninitialized data section for small objects.

    - `T`/`t`
        > The symbol is in the text (code) section.

    - `U`
        > The symbol is undefined.

    - `u`
        > The symbol is a unique global symbol. This is a GNU extension to the standard set of ELF symbol bindings. For such a symbol the dynamic linker will make sure that in the entire process there is just one symbol with this name and type in use.

    - `V`/`v`
        > The symbol is a weak object. When a weak defined symbol is linked with a normal defined symbol, the normal defined symbol is used with no error. When a weak undefined symbol is linked and the symbol is not defined, the value of the weak symbol becomes zero with no error. On some systems, uppercase indicates that a default value has been specified.

    - `W`/`w`
        > The symbol is a weak symbol that has not been specifically tagged as a weak object symbol. When a weak defined symbol is linked with a normal defined symbol, the normal defined symbol is used with no error. When a weak undefined symbol is linked and the symbol is not defined, the value of the symbol is determined in a system-specific manner without error. On some systems, uppercase indicates that a default value has been specified.

    - `-`
        > The symbol is a stabs symbol in an a.out object file. In this case, the next values printed are the stabs other field, the stabs desc field, and the stab type. Stabs symbols are used to hold debugging information.

    - `?`
        > The symbol type is unknown, or object file format specific.

+ To get the size of the functions
    ```
    $ nm --print-size --size-sort --radix=d tst.o
    The second column shows the size in decimal of function and objects
    address  size     type  symbol
    00001072 00000016   T   _avi_mux_add_frame
    00000000 00000020   r   .rdata$zzz
    00000164 00000020   r   ___func__.2512
    00000144 00000020   r   ___func__.2526
    00000120 00000024   r   ___func__.2536
    00001088 00000032   T   _avi_mux_get_header_size
    00000944 00000128   T   _avi_mux_update_info
    00000000 00000184   r   .rdata
    00000000 00000352   b   .bss
    00000000 00000352   b   _g_avi_ctxt
    00001120 00000688   T   _avi_mux_gen_header
    00001808 00000800   T   _avi_mux_reload_header
    00000000 00002608   T   _avi_mux_reset_header    
    ```
    
## size
+ simple section size
    ```
    # -d: shows value in decimal
    $ size.exe ap_mode.axf
    ```

## objcopy
+ bfdName list

    ```
    $ objcopy --info
    ```
    
+ insert binary file to ELF section

    ```
    $ $ objcopy --readonly-text -I binary -O elf32-i386 -B i386 ally.jpg ally.o
    $ objdump -x ally.o | grep ally
    ally.o:     format elf32-i386
    ally.o
    00000000 g       .data  00000000 _binary_ally_jpg_start
    00006e27 g       .data  00000000 _binary_ally_jpg_end
    00006e27 g       *ABS*  00000000 _binary_ally_jpg_size
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


