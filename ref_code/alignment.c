
/**
 *  Ref: https://developer.arm.com/documentation/101754/0618/armclang-Reference/Compiler-specific-Function--Variable--and-Type-Attributes/--attribute----aligned---variable-attribute
 */

#include <stdint.h>
#include <stdio.h>
#include <stddef.h>

#define STR(s) #s

// Aligns on 16-byte boundary
int x __attribute__((aligned (16)));

// When no value is given, the alignment used is the maximum alignment for a scalar data type.
//   For A32, the maximum is 8 bytes.
//   For A64, the maximum is 16 bytes.
short my_array[3] __attribute__((aligned));

// Cannot decrease the alignment below the natural alignment of the type.
// Aligns on 4-byte boundary.
int my_array_reduced[3] __attribute__((aligned (2)));

// b aligns on 8-byte boundary for A32 and 16-byte boundary for A64
struct my_struct
{
    char a;
    int b __attribute__((aligned));
};

// 'aligned' on a struct member cannot decrease the alignment below the
// natural alignment of that member. b aligns on 4-byte boundary.
struct my_struct_reduced
{
    char a;
    int b __attribute__((aligned (2)));
};

// Combine 'packed' and 'aligned' on a struct member to set the alignment for that
// member to any value. b aligns on 2-byte boundary.
struct my_struct_packed
{
    char a;
    int b __attribute__((packed)) __attribute__((aligned (2)));
};

int main()
{
#define SHOW_STRUCT(t)                                                         \
  do {                                                                         \
    printf(STR(t) " is size %zd, align %zd\n", sizeof(struct t),               \
           _Alignof(struct t));                                                \
    printf("  a is at offset %zd\n", offsetof(struct t, a));                   \
    printf("  b is at offset %zd\n", offsetof(struct t, b));                   \
  } while (0)

    SHOW_STRUCT(my_struct);
    SHOW_STRUCT(my_struct_reduced);
    SHOW_STRUCT(my_struct_packed);
    return 0;
}