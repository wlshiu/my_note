// macro return

#include <stdio.h>

#define DBG(s, b...)                                                   \
    {                                                                  \
        printf(__FILE__ "@%d, %s(): " s, __LINE__, __FUNCTION__, ##b); \
        fflush(stdout);                                                \
    }

#define round_down(f)      \
    ({                     \
        int __ret = 0;     \
        __ret = (int)f;    \
        __ret;             \
    })

int main(int argc, char *argv[])
{
    DBG("This is a debug message\n");
    printf("round_down(%f) = %d\n", 4.5, round_down(4.5));
    printf("round_down(%f) = %d\n", 9.5, round_down(9.5));
    return 0;
}