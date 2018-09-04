GNU ELF
---
    ELF (Executable and Linkable Format) is a common standard file format for executable files,
    object code, shared libraries, and core dumps.
    First published in the specification for the application binary interface (ABI)
    of the Unix operating system version named System V Release 4 (SVR4).
    In 1999, it was chosen as the standard binary file format for Unix and Unix-like systems


# Three ELF Type

+ Relocatable or Object File (*.o)
+ Executable
+ Shared Object or Shared Library (*.so)


# Linking View v.s. Execution View

```
            Linking view                            Executable view
            +-------------------+                   +-------------------+
            |  ELF header       |                   |  ELF header       |
            |                   |                   |                   |
            +-------------------+                   +-------------------+
            |  Program Header   |                   |  Program Header  -|---+ p_offset
            |  table (optional) |                   |  table            |   |
            |                   |                   |                   |   |
        +-> +-------------------+                   +-------------------+ <-+
        |   |  Section 1        |                   |  Segment 1        |   |
        +-> +-------------------+                   |                   |   |
        |   |  Section 2        |                   |                   |   |
        +-> +-------------------+                   +-------------------+ <-+
        |   |  Section 3        |                   |  Segment 2        |
        +-> +-------------------+                   |                   |
        |   |  Section 4        |                   |                   |
        |   +-------------------+                   |                   |
        |   |  .....            |                   |  .....            |
        +-> +-------------------+                   |                   |
        |   |  Section K        |                   |                   |
        |   +-------------------+                   +-------------------+
        |   |  ....             |                   |  ....             |
        |   +-------------------+                   +-------------------+
        +---|- Section Header   |                   |  Section Header   |
 sh_offset  |  table            |                   |  table (optional) |
            +-------------------+                   +-------------------+

    * sh_offset: record every section offset
    * p_offset : record every segment offset

    segment = section * N

```

+ ELF header
    ```c
    typedef struct
    {
        unsigned char     e_ident[EI_NIDENT];     /* Identifies infomation */
        Elf32_Half        e_type;                 /* Identifies object file type. */
        Elf32_Half        e_machine;              /* Specifies target instruction set architecture, e.g. ARM, MIPS, ...etc. */
        Elf32_Word        e_version;              /* version of ELF. */
        Elf32_Addr        e_entry;                /* This is the memory address of the entry point from where the process starts executing. */
        Elf32_Off         e_phoff;                /* Points to the start of the program header table. */
        Elf32_Off         e_shoff;                /* Points to the start of the section header table. */
        Elf32_Word        e_flags;                /* Interpretation of this field depends on the target architecture. */
        Elf32_Half        e_ehsize;               /* Contains the size of this header,
                                                   * normally 64 Bytes for 64-bit and 52 Bytes for 32-bit format. */
        Elf32_Half        e_phentsize;            /* Contains the size of a program header table entry. */
        Elf32_Half        e_phnum;                /* Contains the number of entries in the program header table. */
        Elf32_Half        e_shentsize;            /* Contains the size of a section header table entry. */
        Elf32_Half        e_shnum;                /* Contains the number of entries in the section header table. */
        Elf32_Half        e_shstrndx;             /* Contains index of the section header table entry that contains the section names. */
    } Elf32_Ehdr;
    ```

+ Linking View
    > For linker, it will be stored at a `storage`, e.g. flash.

    - Section Header table

        ```c
        typedef struct
        {
            Elf32_Word    sh_name;                    // Section name (string tbl index)
            Elf32_Word    sh_type;                    // Section type
            Elf32_Word    sh_flags;                   // Section flags
            Elf32_Addr    sh_addr;                    // Section virtual addr at execution
            Elf32_Off     sh_offset;                  // Section file offset
            Elf32_Word    sh_size;                    // Section size in bytes
            Elf32_Word    sh_link;                    // Link to another section
            Elf32_Word    sh_info;                    // Additional section information
            Elf32_Word    sh_addralign;               // Section alignment
            Elf32_Word    sh_entsize;                 // Entry size if section holds table
        } Elf32_Shdr;
        ```

+ Execution View
    > For program loader, it will be loaded at `memory`, e.g. SRAM, DRAM.

    - Program Header table

        ```c
        typedef struct
        {
            Elf32_Word  p_type;             /* Identifies the type of the segment. */
            Elf32_Off   p_offset;           /* Offset of the segment in the file image. */
            Elf32_Addr  p_vaddr;            /* Virtual address of the segment in memory. */
            Elf32_Addr  p_paddr;            /* On systems where physical address is relevant, reserved for segment's physical address. */
            Elf32_Word  p_filesz;           /* Size in bytes of the segment in the file image. May be 0. */
            Elf32_Word  p_memsz;            /* Size in bytes of the segment in memory. May be 0. */
            Elf32_Word  p_flags;            /* Segment-dependent flags (position for 32-bit structure). */
            Elf32_Word  p_align;            /* 0 and 1 specify no alignment.
                                             * Otherwise should be a positive, integral power of 2,
                                             * with p_vaddr equating p_offset modulus p_align. */
        } Elf32_Phdr;
        ```

# Analysis

+ Object File (before linker to link symbols)

    ```shell
    $ readelf -a xx.o
    ELF Header:
        Magic:   7f 45 4c 46 01 01 01 00 00 00 00 00 00 00 00 00
        Class:                             ELF32
        Data:                              2's complement, little endian
        Version:                           1 (current)
        OS/ABI:                            UNIX - System V
        ABI Version:                       0
        Type:                              REL (Relocatable file)
        Machine:                           Intel 80386              # CPU machine type, e.g. ARM, MIPS, ...etc.
        Version:                           0x1
        Entry point address:               0x0                      # No program entry point
        Start of program headers:          0 (bytes into file)
        Start of section headers:          200 (bytes into file)    # offset of section header table
        Flags:                             0x0
        Size of this header:               52 (bytes)
        Size of program headers:           0 (bytes)
        Number of program headers:         0                        # No Program Header
        Size of section headers:           40 (bytes)
        Number of section headers:         8                        # 8 sections
        Section header string table index: 5

    Section Headers:
        [Nr] Name              Type            Addr         Off             Size    ES Flg Lk Inf Al
                                                            (file offset)   (hex)
        [ 0]                   NULL            00000000     000000          000000  00      0   0  0
        [ 1] .text             PROGBITS        00000000     000034          00002a  00  AX  0   0  4
        [ 2] .rel.text         REL             00000000     0002b0          000010  08      6   1  4
        [ 3] .data             PROGBITS        00000000     000060          000038  00  WA  0   0  4
        [ 4] .bss              NOBITS          00000000     000098          000000  00  WA  0   0  4
        [ 5] .shstrtab         STRTAB          00000000     000098          000030  00      0   0  1
        [ 6] .symtab           SYMTAB          00000000     000208          000080  10      7   7  4
        [ 7] .strtab           STRTAB          00000000     000288          000028  00      0   0  1
    Key to Flags:
        W (write), A (alloc), X (execute), M (merge), S (strings)
        I (info), L (link order), G (group), x (unknown)
        O (extra OS processing required) o (OS specific), p (processor specific)

    There are no section groups in this file.
    ```

    - Addr are `0`
        > When linker links symbols, it will assign the addresses.

    - section `.bss` size is 0 (this object file no uses bss section)
        > Normally, the global variables, which be set to 0, will put to `.bss` section.
        >> The `.bss` section only record the address and length of every variable.
        As this result, `.bss` section will take up very small size in object file
        but loader will reserve memories dependent on the length in `.bss` section.

    - section `.rel.text`
        > only for linker, record which one need to re-located

        ```shell
        Relocation section '.rel.text' at offset 0x2b0 contains 2 entries:
         Offset     Info    Type            Sym.Value  Sym. Name
        00000008  00000201 R_386_32          00000000   .data
        00000017  00000201 R_386_32          00000000   .data
        ```

        1. `Offset` column
            > the offset address, which is relative to start address of `.test` section, should be re-located by linker.

    - section `.shstrtab`
        > record all section names

    - section `.strtab`
        > string table, record the symbol names.

    - section `.symtab`
        > symbol table, record the information of symbols

        ```shell
        Symbol table '.symtab' contains 8 entries:
           Num:    Value  Size  Type        Bind   Vis      Ndx     Name
            0: 00000000     0   NOTYPE      LOCAL  DEFAULT  UND
            1: 00000000     0   SECTION     LOCAL  DEFAULT    1
            2: 00000000     0   SECTION     LOCAL  DEFAULT    3
            3: 00000000     0   SECTION     LOCAL  DEFAULT    4
            4: 00000000     0   NOTYPE      LOCAL  DEFAULT    3     data_items
            5: 0000000e     0   NOTYPE      LOCAL  DEFAULT    1     start_loop
            6: 00000023     0   NOTYPE      LOCAL  DEFAULT    1     loop_exit
            7: 00000000     0   NOTYPE      GLOBAL DEFAULT    1     _start

        No version information found in this file.
        ```

        1. `Value`
            > the address offset in a section

        1. `Ndx`
            > the section index of every symbol be located

        1. `Bind`
            > record the symbol is local or global

    - section `.text`
        > read-only, record machine codes

        ```shell
        $ objdump -d xx.o

        xx.o:     file format elf32-i386

        Disassembly of section .text:

        00000000 <_start>:
           0:   bf 00 00 00 00          mov    $0x0,%edi
           5:   8b 04 bd 00 00 00 00    mov    0x0(,%edi,4),%eax
           c:   89 c3                   mov    %eax,%ebx

        0000000e <start_loop>:
           e:   83 f8 00                cmp    $0x0,%eax
          11:   74 10                   je     23 <loop_exit>
          13:   47                      inc    %edi
          14:   8b 04 bd 00 00 00 00    mov    0x0(,%edi,4),%eax
          1b:   39 d8                   cmp    %ebx,%eax
          1d:   7e ef                   jle    e <start_loop>
          1f:   89 c3                   mov    %eax,%ebx
          21:   eb eb                   jmp    e <start_loop>

        00000023 <loop_exit>:
          23:   b8 01 00 00 00          mov    $0x1,%eax
          28:   cd 80                   int    $0x80

        # |<------ machine code ----->|<------- disassemble -------->

        # The values without prefix '$' are memory address which are relative to text section,
            and they will be modified with absolute address by linker.
        # Linker will modify the symbol addresst to the real memory address
        ```

+ Executable File

    ```shell
    $ readelf -a xx
    ELF Header:
        Magic:   7f 45 4c 46 01 01 01 00 00 00 00 00 00 00 00 00
        Class:                             ELF32
        Data:                              2's complement, little endian
        Version:                           1 (current)
        OS/ABI:                            UNIX - System V
        ABI Version:                       0
        Type:                              EXEC (Executable file)       # EXEC
        Machine:                           Intel 80386
        Version:                           0x1
        Entry point address:               0x8048074                    # Entry pointer address of program
        Start of program headers:          52 (bytes into file)         # offset of program header table
        Start of section headers:          256 (bytes into file)        # offset of section header table
        Flags:                             0x0
        Size of this header:               52 (bytes)
        Size of program headers:           32 (bytes)
        Number of program headers:         2                            # Program Header: 2 segments
        Size of section headers:           40 (bytes)
        Number of section headers:         6                            # Section Header: 6 sections
        Section header string table index: 3

    Section Headers:
        [Nr] Name              Type            Addr         Off             Size    ES Flg Lk Inf Al
                                                            (file offset)   (hex)
        [ 0]                   NULL            00000000     000000          000000  00      0   0  0
        [ 1] .text             PROGBITS        08048074     000074          00002a  00  AX  0   0  4
        [ 2] .data             PROGBITS        080490a0     0000a0          000038  00  WA  0   0  4
        [ 3] .shstrtab         STRTAB          00000000     0000d8          000027  00      0   0  1
        [ 4] .symtab           SYMTAB          00000000     0001f0          0000a0  10      5   6  4
        [ 5] .strtab           STRTAB          00000000     000290          000040  00      0   0  1
    Key to Flags:
      W (write), A (alloc), X (execute), M (merge), S (strings)
      I (info), L (link order), G (group), x (unknown)
      O (extra OS processing required) o (OS specific), p (processor specific)

    There are no section groups in this file.

    Program Headers:
        Type           Offset           VirtAddr   PhysAddr     FileSiz     MemSiz  Flg     Align
                       (file offset)
        LOAD           0x000000         0x08048000 0x08048000   0x0009e     0x0009e R E     0x1000
        LOAD           0x0000a0         0x080490a0 0x080490a0   0x00038     0x00038 RW      0x1000

     Section to Segment mapping:
        Segment Sections...
           00     .text
           01     .data

    There is no dynamic section in this file.

    There are no relocations in this file.

    There are no unwind sections in this file.

    Symbol table '.symtab' contains 10 entries:
       Num:    Value  Size  Type        Bind   Vis      Ndx     Name
        0: 00000000     0   NOTYPE      LOCAL  DEFAULT  UND
        1: 08048074     0   SECTION     LOCAL  DEFAULT    1
        2: 080490a0     0   SECTION     LOCAL  DEFAULT    2
        3: 080490a0     0   NOTYPE      LOCAL  DEFAULT    2     data_items
        4: 08048082     0   NOTYPE      LOCAL  DEFAULT    1     start_loop
        5: 08048097     0   NOTYPE      LOCAL  DEFAULT    1     loop_exit
        6: 08048074     0   NOTYPE      GLOBAL DEFAULT    1     _start
        7: 080490d8     0   NOTYPE      GLOBAL DEFAULT  ABS     __bss_start
        8: 080490d8     0   NOTYPE      GLOBAL DEFAULT  ABS     _edata
        9: 080490d8     0   NOTYPE      GLOBAL DEFAULT  ABS     _end

    No version information found in this file.
    ```

    - Program Headers (is used at executing time)
        1. segment 1
            > FileSiz 0x9e = 0x74 + 0x2a = ELF header + Program header table + `.text` section
            >> Map to `Off` column of Section Headers

        1. segment 2
            > FileSiz 0x38 = `.data` section

        1. `Align` in Program Headers
            > memory page size

        1. full flow
            > Loader put 0x0 ~ (0x0 + 0x9e) data, in this executable file, to 0x08048000 of memory,
            and 0xa0 ~ (0xa0 + 0x38) data, in this executable file, to (0x08049000 + 0xa0) of memory.

            >> + every segment should put at difference memory pages.
            >> + For simplifying mapping flow, the segment 2 directly is mapped with it's offset (not star at head of a memory page)

+ Shared Object
    > Data references from PIC are usually made indirectly,
    through `Global Offset Tables (GOTs)`, which store the addresses of all accessed global variables.
    There is one GOT per compilation unit or object module,
    and it is located at a fixed offset from the code (although this offset is not known until the library is linked).
    When a Linker links modules to create a shared library, it merges the GOTs and sets the final offsets in code.

    - compiler option `-fPIC` (Position Independent Code)
        > PIC can be executed at any memory address without modification (except GOTs).
        And it is commonly used for shared libraries,
        so that the same library code can be loaded in difference location with difference program.

        1. `.rel.text` section
            > + `R_386_32`: absolute address re-located
            > + `R_386_GOTPC`: use relative address and loading time re-located (need to reference Global Offset Table)

            ```shell
            # without fPIC
            Relocation section '.rel.text' at offset 0x848 contains 4 entries:
             Offset     Info    Type            Sym.Value  Sym. Name
            0000000d  00001001 R_386_32          00000000   top
            00000015  00001001 R_386_32          00000000   top
            0000001b  00001001 R_386_32          00000000   top
            00000025  00001101 R_386_32          00000000   stack
            ```

            ```shell
            # with fPIC
            Relocation section '.rel.text' at offset 0x94c contains 6 entries:
             Offset     Info    Type            Sym.Value  Sym. Name
            00000008  00001202 R_386_PC32        00000000   __i686.get_pc_thunk.bx
            0000000e  0000130a R_386_GOTPC       00000000   _GLOBAL_OFFSET_TABLE_
            0000001a  00001403 R_386_GOT32       00000000   top
            00000025  00001403 R_386_GOT32       00000000   top
            0000002d  00001403 R_386_GOT32       00000000   top
            00000035  00001503 R_386_GOT32       00000000   stack
            ```

        1. `disassemble`

            ```shell
            # without fPIC
            $ objdump -dS xx.o

                ...
            80483cc: a1 10 a0 04 08     mov   0x804a010,%eax   # 0x804a010 absolute adress
            80483d1: 83 c0 01           add   $0x1,%eax        # eax add 0x1
                ...

            ```

            ```shell
            # with fPIC
            $ objdump -dS libxx.so

                ...
            494:   8b 83 f4 ff ff ff   mov   -0xc(%ebx),%eax  # get 'pointer' and put it to eax
            49a:   8b 00               mov   (%eax),%eax      # get 'value' with pointer in eax and put it to eax
            49c:   8d 50 01            lea   0x1(%eax),%edx   # eax add 0x1 and put it to edx
                ...

            ##### indirect addressing

                    +----------------+
                    |                |
            ebx+0xc +----------------+
                    | pointer to X --|----+
            ebx+0x8 +----------------+    |
                    |                |    |
                    |                |    |
                    |   ...          |    |
                    |                |    |
                    +----------------+    |
                    |  X address  <--|----+
                    +----------------+
                    |                |
            ```
    - Tips

        1. `ldd`
            > simulate dynamic link, you can check the path and `*.so` file

            ```shell
            $ ldd [executable elf]

            # e.g.
            $ ldd test
                linux-gate.so.1 =>  (0xb7f5c000)
                libstack.so => not found
                libc.so.6 => /lib/tls/i686/cmov/libc.so.6 (0xb7dcf000)
                /lib/ld-linux.so.2 (0xb7f42000)     # dynamic-linker
            ```

        1. search path in running time

            > + `LD_LIBRARY_PATH`
            >> environment variable.
            In some situation, `LD_LIBRARY_PATH` will be ignored for security issues.
            Recommand: Use `LD_LIBRARY_PATH` only for debugging (it is dangerous).
            >   ```shell
                $ setenv LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/usr/xxx/
                    or
                $ export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/usr/xxx/
                ```
            >> In compiler time, gcc will search path first with option `-L` and then `LD_LIBRARY_PATH`
            >>  ```shell
                $ gcc -L./ -L/usr/xxx -ltest *.c
                ```

            > + `/etc/ld.so.conf` (popular)
            >> record the search path of shared objects in system level
            >   ```shell
                $ sudo vim /etc/ld.so.conf  # add dynamic path to this file
                $ ldconfig  # re-generate 'ld.so.cache' (note: there is no log to print)
                ```

            > + default search path `/usr/lib` or `/lib`
            >> copy your `*.so` to the system default path

            > + hot code in compiler option
            >>  option `-Wl,-rpath,[path]` (No recommand)
            >   ```shell
                $ gcc main.c -g -L. -lstack -Istack -o test -Wl,-rpath,/home/somedir
                $ readelf -a test
                    ...
                Dynamic section at offset 0xf10 contains 23 entries:
                  Tag        Type                         Name/Value
                 0x00000001 (NEEDED)                     Shared library: [libstack.so]
                 0x00000001 (NEEDED)                     Shared library: [libc.so.6]
                 0x0000000f (RPATH)                      Library rpath: [/home/somedir]  # hot code
                    ...
                ```


# Notic

+ `*.bin`
    > Raw binary, only include machine code. It can immediately execute by CPU.
    >> image files of uboot and Linux kernel are raw binary.

    - ELF to BIN
        > remove dummy sections (only extract machine code)

        ```
        $ arm-none-eabi-objcopy.exe -O binary xx.elf xx.bin
        ```

+ `*.elf`
    > It includes many infomations, e.g. machine code, symbol table, ...etc.
    > ELF Loader (parser) is necessary

    - BIN to ELF
        > only add elf header to the bin file

        ```
        $ arm-none-eabi-objcopy.exe -I binary -O elf32-littlearm xx.bin xx.bin.elf

        #-- Disassemble
        $ arm-none-eabi-objdump -m arm9 -D xx.bin.elf > xx.asm
        $ arm-none-eabi-objdump -b binary -m arm uboot.bin
        ```

+ `*.a`
    > static libraries

    ```
    # generate static lib
    $ ar –rc libtest.a aa.o bb.o cc.o

    # use static lib
    $ gcc -o executable-name prog.c libtest.a
        or
    $ gcc -o executable-name prog.c -L/path/to/library-directory -ltest
    ```

    - `-L`
        > the directory path of libraries

    - `-l`
        > the name of library without prefix **lib** and suffix **.a**

    - `-I`
        > the path of header of libraries


+ `*.so`
    > shared libraries

    ```
    # generate shared lib
    $ gcc -c -fPIC *.c
    $ gcc -shared -Wl,-soname,libtest.so.1 -o libtest.so.1.1 aa.o bb.o cc.o

    # symbolic link
    $ ln -s libstack.so.1.0 libstack.so

    # use shared lib
    $ gcc -Wall -I../ -L/opt/lib prog.c -ltest -o prog
    ```

    - `-L`
        > the directory path of the linker name of libraries

    - `-l`
        > the name of library without prefix **lib** and suffix **.so**

    - Naming
        1. Soname
            > The soname has the prefix **lib**, the name of the library, the phrase **.so**,
            followed by a period and a **version number** that is incremented whenever the interface changes.
            >> structure: `lib` + `name` + `.so` + `.ver_num`, e.g. libtest.so.1

            ```shell
            # get soname
            $ objdump -p libxx.so | grep SONAME
            ```

        1. Real Name
            >  The real name is the filename containing the actual library code.
            It adds to the soname a period, a minor number, another period, and the release number.
            The last period and release number are optional.
            >> structure: `soname` + `.minor_num` + `.release_num` (optional), e.g. libtest.so.1.1

        1. Linker name
            > + The linker name is simply the soname without any version number, e.g. libtest.so.
            And it is a symbolic link to the soname name.
            >   ```shell
                $ cat /usr/lib/libc.so
                /* GNU ld script
                   Use the shared library, but some functions are only in
                   the static library, so try that secondarily.  */
                OUTPUT_FORMAT(elf32-i386)
                GROUP ( /lib/libc.so.6 /usr/lib/libc_nonshared.a  AS_NEEDED ( /lib/ld-linux.so.2 ) )
                ```
            > + the compiler **ONLY** uses `linker name`


+ reference
    - SPEC: System V Application Binary Interface - Chapter 4
    - [ELF Document](http://learn.tsinghua.edu.cn/kejian/data/77130/138627/html-chunk/ch18s05.html#ftn.id2770769)
    - [Shared Object](http://learn.tsinghua.edu.cn/kejian/data/77130/138627/html-chunk/ch20s04.html)


