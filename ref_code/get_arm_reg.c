#define __ASM               __asm /*!< asm keyword for GNU Compiler */
#define __INLINE            inline /*!< inline keyword for GNU Compiler */
#define __STATIC_INLINE     static inline

/**
\brief Get Link Register
\details Returns the current value of the Link Register (LR).
\return LR Register value
*/
__attribute__( ( always_inline ) ) __STATIC_INLINE uint32_t __get_LR(void)
{
    register uint32_t result;

    __ASM volatile ("MOV %0, LR\n" : "=r" (result) );
    return(result);
}


__attribute__( ( always_inline ) ) __STATIC_INLINE uint32_t __get_PC(void)
{
    register uint32_t result;

    __ASM volatile ("MOV %0, PC\n" : "=r" (result) );
    return(result);
}

__attribute__( ( always_inline ) ) __STATIC_INLINE uint32_t __get_SP(void)
{
    register uint32_t result;

    __ASM volatile ("MOV %0, SP\n" : "=r" (result) );
    return(result);
}

__attribute__( ( always_inline ) ) __STATIC_INLINE uint32_t __get_R0(void)
{
    register uint32_t result;

    __ASM volatile ("MOV %0, R0\n" : "=r" (result) );
    return(result);
}


