[protocol buffers](https://developers.google.com/protocol-buffers/docs/overview)
---

You can easily generate source code with compiling `.proto` file (which follow proto2/proto3 rule).
It also supports `backward/forward` compatible.

+ From offical description
    > Protocol buffers are a flexible, efficient, automated mechanism for serializing structured data – think XML,
    but smaller, faster, and simpler.
    You define how you want your data to be structured once,
    then you can use special generated source code to easily write and read your structured data
    to and from a variety of data streams and using a variety of languages.
    You can even update your data structure without breaking deployed programs that are compiled against the "old" format.

+ This message is encoded to `binary format`.
    - Pros
        1. better security (you can't analyze the context if no .proto file)
        1. smaller data size
        1. efficient
    - Cons
        1. readable is worse

# [proto2](https://developers.google.com/protocol-buffers/docs/proto)

Support C++, JAVA, Python, Go languages.
[There are third-party to generate other languages](https://github.com/google/protobuf/blob/master/docs/third_party.md)

## C language
1. [Nanopb](http://jpa.kapsi.fi/nanopb/)
2. [PBC](https://github.com/cloudwu/pbc/)
3. [protobuf-c](https://github.com/protobuf-c/protobuf-c)

## Syntax

+ Defining A Message Type
    ```
    message     SearchRequest {
      required string   query           = 1;
      optional int32    page_number     = 2;
      optional int32    result_per_page = 3;
    }
    ```

    - member format
        > [Specifying Field Rules] [Specifying Field Types] [Menber Name] [Field Numbers]

        ```
        [required] [string] [query]         [= 1];
        [optional] [int32]  [page_number]   [= 2];
        ```

    - Specifying Field Rules
        1. `required`
            > a well-formed message `MUST` have exactly one of this field.

        1. `optional`
            > a well-formed message can have zero or one of this field (but not more than one).
            >> it can be used for backward/forward compatible

        1. `repeated`
            > this field can be repeated any number of times (including zero) in a well-formed message.
            The order of the repeated values will be preserved.

        1. `reserved` (Reserved Fields)
            > If you want to reserve some field number or member name for future reusing,
            but maybe conflict with someone's version.
            Use `reserved` to reserve the field number or member name.
            (The protocol buffer compiler will complain if any future users try to use these identifiers.)

            > If you want to delete some members (field numbers) in new version,
            you should use `reserved` to avoid someone use the same member name (field number) in future version.

            ```
            // field number 2, 15, 9 ~ 11, 40 ~ max will be reserved
            // max is a keyword for the maximum possible value
            message Foo {
              reserved 2, 15, 9 to 11, 40 to max;
              reserved "foo", "bar";
            }

            if bar = 2
            reserved 2, "bar", 15 => NG
            ```

    - [Specifying Field Types](https://developers.google.com/protocol-buffers/docs/proto#scalar)
        > you can use basic type by program languages,
        or use self message type which declare with `message` or `enum`.

        ```
        [.proto Type]       [C/C++]     [note]
            double           double
            float            float
            int32            int32
            int64            int64
            uint32           uint32
            uint64           uint64
            sint32           int32
            sint64           int64
            fixed32          uint32
            fixed64          uint64
            sfixed32         int32
            sfixed64         int64
            bool             bool
            string           string
            bytes            string         May contain any arbitrary sequence of bytes.
        ```

    - Field Numbers
        > It is a unique number. These numbers are used to identify your fields in the message binary format,
        and **SHOULD NOT be changed** once your message type is in use.

        > The smallest field number you can specify is `1`, and the largest is `2^29 - 1`, or `536,870,911`.
        But the numbers `19000` through `19999` are reserved (you CAN NOT use).

    - Default Value
        > The default value can be specified as part of the message description.
        It also can assign by protobuf.

        ```
        optional int32 result_per_page = 3 [default = 10];
        ```

        ```
        [type]              [default]
        string              empty string
        bool                false
        numeric types       0
        enums               the 1-st value listed in the enum's type definition
        ```

    - Comments
        > To add comments to your .proto files, use C/C++-style `//` and `/* ... */` syntax.

    - Enumerations
        > Negative values are inefficient and thus not recommended.

        > the first member MUST be set `0` in `enum`

        ```
        message SearchRequest {
            required string     query = 1;
            optional int32      page_number = 2;
            optional int32      result_per_page = 3 [default = 10];

            enum Corpus {
                UNIVERSAL = 0;
                WEB       = 1;
                IMAGES    = 2;
                LOCAL     = 3;
                NEWS      = 4;
                PRODUCTS  = 5;
                VIDEO     = 6;
            }
            optional Corpus corpus = 4 [default = UNIVERSAL];
        }

        // define aliases by assigning the same value to different enum constants.
        enum EnumAllowingAlias {
            option allow_alias = true; // MUST
            UNKNOWN = 0;
            STARTED = 1;
            RUNNING = 1;
        }
        ```

    - Importing
        > You can use definitions from other .proto files by importing them.

        ```
        import "myproject/other_protos.proto";
        ```

    - Extensions
        > Let you declare that a range of field numbers in a message are available for third-party extensions.

        ```
        message Foo {
            // ...
            extensions 100 to 199; // field number 100 ~ 199 for 3th-party
        }

        // 3th-party extend message Foo
        extend Foo {
            optional int32 bar = 126;
        }

        ```

    - Oneof
        > If you have a message with many optional fields and
        where at most one field will be set at the same time,
        you can enforce this behavior and save memory by using the oneof feature.

        ```
        message SampleMessage {
            oneof test_oneof {  // like union ?
                string name = 4;
                SubMessage sub_message = 9;
            }
        }
        ```

+ example of a complex `.proto` file

    ```
    // addressbook.proto

    syntax = "proto2";

    package tutorial;

    message Person {
      required string name = 1;
      required int32 id = 2;
      optional string email = 3;

      enum PhoneType {
        MOBILE = 0;
        HOME = 1;
        WORK = 2;
      }

      message PhoneNumber {
        required string number = 1;
        optional PhoneType type = 2 [default = HOME];
      }

      repeated PhoneNumber phones = 4;
    }

    message AddressBook {
      repeated Person people = 1;
    }

    ```

## Binary Format

    use `Varint (varying-length integer)` compressing algorithm,

+ `Varints` are based on the idea that most numbers are not uniformly distributed.
    Almost always, smaller numbers are more common in computing than larger ones.
    The trade off that varints make is to spend more bits on larger numbers,
    and fewer bits on smaller numbers.

    - `MSB (Most Significant Bit)` of every byte is a tag field for data serializing
        > the top bit of each byte to indicate whether or not there are more bytes coming.
        >> `1` means data serializing, and `0` means it is the last byte.

    - only `7 bits` of every byte are used for data field

+ protobuf uses `little-endian` format in a value of aggregative bytes

+ protobuf Message Structure
    > every member is descripted by format of key-value pairs.

    ```
     <-- member 1 --> <-- member 2 --> <-- member 3 -->
    +-------+--------+-------+--------+-------+--------+--
    |  key  |  value |  key  |  value |  key  |  value |
    +-------+--------+-------+--------+-------+--------+--

    key[7:0] = ([Field Number] << 3) | [write type];
    ```

    ```
    // example of key declaration with C code
    struct key {
        uint8_t    write_type: 3;

        // field num in 1 ~ 15 range is efficient or key will be descripted with multi-bytes.
        uint8_t    field_num: 4;
        uint8_t    tag: 1;
    } key_t;
    ```

    ```
    // example of value encoding
    uint32  value = 150u
    binary        : 10010110
    7-bits context: 000,0001  001,0110
    little-endian : 001,0110  000,0001
    MSB tag       : 1001,0110  0000,0001
    hex           : 96  01
    ```

    - write type
        ```
        Type    Meaning             Used For
        0       Varint              int32, int64, uint32, uint64, sint32, sint64, bool, enum (little-endian)
        1       64-bit              fixed64, sfixed64, double (little-endian)
        2       Length-delimited    string, bytes, embedded messages, packed repeated fields
        3       Start group         groups (deprecated)
        4       End group           groups (deprecated)
        5       32-bit              fixed32, sfixed32, float (little-endian)
        ```

    - Negative Numbers
        > it will be handled as large number (as unsigned integer type).

        1. `signed int types` (sint32/sint64) vs `standard int types` (int32/int64)
            > **signed int types** will use `Zig-Zag` encoding (more efficient),
            and **standard int types** will use normal encoding (10 bytes long)

        1. `Zig-Zag` encoding
            > map signed value to unsigned vale (inter order in nagative/positive)

            ```
            original                    zig-zag
            0                           0
                        -1              1
            1                           2
                        -2              3
            2                           4
                        -3              5
            3                           6
                            ...
            2147483647                  4294967294
                        -2147483648     4294967295

            sint32:
            #define ZIGZAG_CONV_32(n)      (((n) << 1) ^ ((n) >> 31))

            sint64:
            #define ZIGZAG_CONV_64(n)      (((n) << 1) ^ ((n) >> 63))

            ```
    - Non-varint Numbers
        ```
        message Test {
            optional int32 a = 1;
            optional fixed32 b = 2;
        }

        set a = (1 << 28)
        set b = (1 << 28)

        int32  : 08 80 80 80 80 01 (6 bytes)
        fixed32: fixed 4 bytes length
        ```

    - Length-delimited type

        ```
        key (varint format) + length (varint format) + raw data (bytes)

        // example
        message Test2 {
            optional string b = 2;
        }

        set b = "testing"

        key     : 0001,0010 (tag + field number + write type)
        length  : 0000,0111 (tag + length value)
        raw data: \74 \65 \73 \74 \69 \6e \67 ('t' + 'e' + 's' + 't' + 'i' + 'n' + 'g')
        ```

    - Nested

        ```
        key (varint format) + length (varint format) + nested type data (bytes)
        => nested type data
            -> key-value pairs

        // example
        message Test {
            optional Test2  t2 = 9; // encode with Length-delimited type
        }

        set t2.b = "testing"

        key        : 0100,1010 (tag + field num '9' + write type '2')
        length     : 0000,1001 (tag + t2 length) // only nested member size NOT included self
        t2.key     : 0001,0010 (tag + field number + write type)
        t2.length  : 0000,0111 (tag + length value)
        t2.raw_data: \74 \65 \73 \74 \69 \6e \67 ('t' + 'e' + 's' + 't' + 'i' + 'n' + 'g')

        binary = key + length + t2.key + t2.length + t2.raw_data
        ```

    - Repeated

        ```
        key (varint format) + length (varint format) + repeated data (bytes)
        => repeated data
            -> key-value pairs * N

        // example
        message Test4 {
            repeated int32  d = 4; // encode with Length-delimited type
        }

        set d[0] = 3
        set d[1] = 270
        set d[2] = 86942

        key        : 0010,0010 (tag + field num '4' + write type '2')
        length     : 0000,1001 (tag + t2 length) // only repeated members size NOT included self
        d[0].key   : 0011,1000 (tag + field number + write type)
        d[0].value : 0000,0011 (tag + value)
        d[1].key   : 0011,1000 (tag + field number + write type)
        d[1].value : \8E \02 (varint format and little-endian)
        d[2].key   : 0011,1000 (tag + field number + write type)
        d[2].value : \9E \A7 \05 (varint format and little-endian)

        d[0].key == d[1].key == d[2].key => dummy

        binary = key + length + d[0].key + d[0].value + d[1].key + d[1].value + d[2].key + d[2].value

        // package
        message Test4 {
            repeated int32  d = 4 [packed=true];
        }

        key        : 0010,0010 (tag + field num '4' + write type '2')
        length     : 0000,0110 (tag + t2 length) // only repeated members size NOT included self
        d[0].value : 0000,0011 (tag + value)
        d[1].value : \8E \02 (varint format and little-endian)
        d[2].value : \9E \A7 \05 (varint format and little-endian)
        ```



# [proto3](https://developers.google.com/protocol-buffers/docs/proto3)

Support C++, JAVA, Python, Go, Ruby, Objective-C, C-sharp languages,
but proto3 is not completely compatible with proto2.

+ Distinction
    ```
    // .proto file
    // In first line, you MUST declare proto3 (defalut is proto2)
    syntax = "proto3";
    ```


