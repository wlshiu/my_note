/**************************************************************************//**
 * @file     FlashPrg.c
 * @brief    Flash Programming Functions adapted for New Device Flash
 * @version  V1.0.0
 * @date     10. January 2018
 ******************************************************************************/
/*
 * Copyright (c) 2010-2018 Arm Limited. All rights reserved.
 *
 * SPDX-License-Identifier: Apache-2.0
 *
 * Licensed under the Apache License, Version 2.0 (the License); you may
 * not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an AS IS BASIS, WITHOUT
 * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include <stdint.h>
#include "FlashOS.H"        // FlashOS Structures

/*
   Mandatory Flash Programming Functions (Called by FlashOS):
                int Init        (unsigned long adr,   // Initialize Flash
                                 unsigned long clk,
                                 unsigned long fnc);
                int UnInit      (unsigned long fnc);  // De-initialize Flash
                int EraseSector (unsigned long adr);  // Erase Sector Function
                int ProgramPage (unsigned long adr,   // Program Page Function
                                 unsigned long sz,
                                 unsigned char *buf);

   Optional  Flash Programming Functions (Called by FlashOS):
                int BlankCheck  (unsigned long adr,   // Blank Check
                                 unsigned long sz,
                                 unsigned char pat);
                int EraseChip   (void);               // Erase complete Device
      unsigned long Verify      (unsigned long adr,   // Verify Function
                                 unsigned long sz,
                                 unsigned char *buf);

       - BlanckCheck  is necessary if Flash space is not mapped into CPU memory space
       - Verify       is necessary if Flash space is not mapped into CPU memory space
       - if EraseChip is not provided than EraseSector for all sectors is called
*/

//=============================================================================
//                  Constant Definition
//=============================================================================
//#define CONFIG_DEBUG        1

#define CONFIG_FLASH_DATA_BASE          0x0ul
#define CONFIG_SECTOR_SIZE              512ul

#define RCC_BASE        0x40020000UL
#define SYSCON_BASE     0x40001C00UL
#define FLASH_BASE      0x40020400UL
#define __I             volatile
#define __IO            volatile


#define RCC_SYSCLKCR_HIRCEN                 (0x1UL)

#define FLASH_CR_OP_Msk                     (0x3UL)

#define FLASH_OP_READ                       (0x0ul)
#define FLASH_OP_PROGRAM                    (0x1ul)
#define FLASH_OP_SECTORERASE                (0x2ul)
#define FLASH_OP_CHIPERASE                  (0x3ul)

#define FLASH_FLAG_BSY                      (0x4UL)
//=============================================================================
//                  Structure Definition
//=============================================================================
typedef struct                                  /*!< (@ 0x40020000) RCC Structure                                              */
{
    __IO uint32_t  HCLKDIV;                      /*!< (@ 0x00000000) AHB CLK Prescale                                           */
    __IO uint32_t  PCLKDIV;                      /*!< (@ 0x00000004) APB CLK Prescale                                           */
    __IO uint32_t  HCLKEN;                       /*!< (@ 0x00000008) AHB Peripheral Model Clk Enable                            */
    __IO uint32_t  PCLKEN;                       /*!< (@ 0x0000000C) APB Peripheral Model CLK Enable                            */
    __IO uint32_t  MCOCR;                        /*!< (@ 0x00000010) Clock Output Control Register                              */
    __I  uint32_t  RESERVED;
    __IO uint32_t  RSTCR;                        /*!< (@ 0x00000018) System Reset Control                                       */
    __IO uint32_t  RSTSR;                        /*!< (@ 0x0000001C) Reset Status                                               */
    __IO uint32_t  SYSCLKCR;                     /*!< (@ 0x00000020) CLK Setting                                                */
    __IO uint32_t  SYSCLKSEL;                    /*!< (@ 0x00000024) System Clock Select                                        */
    __IO uint32_t  HIRCCR;                       /*!< (@ 0x00000028) HIRC Control                                               */
    __IO uint32_t  HXTCR;                        /*!< (@ 0x0000002C) HXT Control                                                */
    __IO uint32_t  LIRCCR;                       /*!< (@ 0x00000030) LIRC Control                                               */
    __IO uint32_t  LXTCR;                        /*!< (@ 0x00000034) LXT Control                                                */
    __IO uint32_t  IRQLATENCY;                   /*!< (@ 0x00000038) M0 IRQ Delay                                               */
    __IO uint32_t  STICKCR;                      /*!< (@ 0x0000003C) SysTick Timer Circle Adjust                                */
    __IO uint32_t  SWDIOCR;                      /*!< (@ 0x00000040) Endpoint Function Select                                   */
    __IO uint32_t  PERIRST;                      /*!< (@ 0x00000044) Peripheral Model Control                                   */
    __IO uint32_t  RTCRST;                       /*!< (@ 0x00000048) RTC Control                                                */
    __I  uint32_t  RESERVED1[5];
    __IO uint32_t  UNLOCK;                       /*!< (@ 0x00000060) Register Protect                                           */
} RCC_TypeDef;

typedef struct {                                /*!< (@ 0x40001C00) SYSCON Structure                                           */
  __IO uint32_t  CFGR0;                         /*!< (@ 0x00000000) System Control setting regist 0                            */
  __IO uint32_t  PORTINTCR;                     /*!< (@ 0x00000004) PORT INTERRUPT MODE SETTING                                */
  __IO uint32_t  PORTCR;                        /*!< (@ 0x00000008) PORT control register                                      */
  __IO uint32_t  PCACR;                         /*!< (@ 0x0000000C) PCA Capture channel source select                          */
  __IO uint32_t  TIM1CR;                        /*!< (@ 0x00000010) TIM1 Channel Source Select                                 */
  __IO uint32_t  TIM2CR;                        /*!< (@ 0x00000014) TIM2 Channel Source Select                                 */
  __IO uint32_t  TIM1ACR;                       /*!< (@ 0x00000018) TIM1A Channel Source Select                                */
  __IO uint32_t  TIM1BCR;                       /*!< (@ 0x0000001C) TIM1B Channel Source Select                                */
  __IO uint32_t  TIM2ACR;                       /*!< (@ 0x00000020) TIM2A Channel Source Select                                */
  __IO uint32_t  TIM2BCR;                       /*!< (@ 0x00000024) TIM2B Channel Source Select                                */
  __IO uint32_t  TIM2CCR;                       /*!< (@ 0x00000028) TIM2C Channel Source Select                                */
  __I  uint32_t  RESERVED[9];
  __IO uint32_t  UNLOCK;                        /*!< (@ 0x00000050) Syscon Register Write Enable                               */
} SYSCON_TypeDef;                                  /*!< Size = 84 (0x54)                                                       */

typedef struct                                  /*!< (@ 0x40020400) FLASH Structure                                            */
{
    __IO uint32_t  CR;                           /*!< (@ 0x00000000) Control Register                                           */
    __IO uint32_t  IFR;                          /*!< (@ 0x00000004) Interrupt flag Register                                    */
    __IO uint32_t  ICLR;                         /*!< (@ 0x00000008) Interrupt Flag Clear Register                              */
    __IO uint32_t  BYPASS;                       /*!< (@ 0x0000000C) 0X5A5A-0XA5A5 sequence Register                            */
    __IO uint32_t  SLOCK0;                       /*!< (@ 0x00000010) Sector Write Protect Register0                             */
    __IO uint32_t  SLOCK1;                       /*!< (@ 0x00000014) Sector Write Protect Register1                             */
    __IO uint32_t  ISPCON;                       /*!< (@ 0x00000018) Flash ISP Control register                                 */
    __IO uint32_t  IAPCON;                       /*!< (@ 0x0000001C) Flash IAP Control register                                 */
    __IO uint32_t  IAP_SIZE;                     /*!< (@ 0x00000020) Flash IAP Size register                                    */
} FLASH_TypeDef;                                 /*!< Size = 36 (0x24)                                                          */


#define RCC         ((RCC_TypeDef*)RCC_BASE)
#define SYSCON      ((SYSCON_TypeDef*)SYSCON_BASE)
#define FLASH       ((FLASH_TypeDef*)FLASH_BASE)


#define RCC_HIRCCR_HIRCRDY_Msk          (0x1000UL)

#define HIRC24M_PKG_FLASHADDR           0x180000A0
#define HIRC16M_PKG_FLASHADDR           0x180000A4
//=============================================================================
//                  Macro Definition
//=============================================================================
#define CLEAR_REG(REG)          ((REG) = (0x0))
#define WRITE_REG(REG, VAL)     ((REG) = (VAL))
#define READ_REG(REG)           ((REG))

#define MODIFY_REG(REG, CLEARMASK, SETMASK)     WRITE_REG((REG), (((READ_REG(REG)) & (~(CLEARMASK))) | (SETMASK)))
#define CLEAR_WPBIT(REG, CLEARMASK, WPKEY)      WRITE_REG((REG), ((READ_REG(REG)) & (~(CLEARMASK))) | WPKEY)

#define __HAL_FLASH_REGISTER_UNLOCK     \
            do {                        \
                FLASH->BYPASS = 0x5A5A; \
                FLASH->BYPASS = 0xA5A5; \
            } while(0U)

#define __HAL_FLASH_REGISTER_LOCK       FLASH->BYPASS = 0x00000000ul

#define __HAL_FLASH_GET_FLAG(__FLAG__)      (((__FLAG__) == FLASH_FLAG_BSY) ? \
                                             (FLASH->CR & (__FLAG__)) :       \
                                             (FLASH->IFR & (__FLAG__)))

/*********************************************************************/

//=============================================================================
//                  Public Function Definition
//=============================================================================
/*
 *  Initialize Flash Programming Functions
 *    Parameter:      adr:  Device Base Address
 *                    clk:  Clock Frequency (Hz)
 *                    fnc:  Function Code (1 - Erase, 2 - Program, 3 - Verify)
 *    Return Value:   0 - OK,  1 - Failed
 */

int Init (unsigned long adr, unsigned long clk, unsigned long fnc)
{
    SYSCON->UNLOCK = 0x55AA6699;
    RCC->UNLOCK    = 0x55AA6699;

    RCC->HIRCCR   = *(volatile uint16_t*)(HIRC24M_PKG_FLASHADDR) | 0x5A690000;
    RCC->SYSCLKCR = 0x5A690001ul;

    while( !(RCC->HIRCCR & RCC_HIRCCR_HIRCRDY_Msk) );

    RCC->SYSCLKSEL = 0x5A690001ul;

    /* Reset HCLK and PCLK div bits */
    RCC->HCLKDIV = 0x00000000;
    RCC->PCLKDIV = 0x00000000;

    /* Reset AHB and APB module */
    RCC->HCLKEN = 0x00000109;
    RCC->PCLKEN = 0;

    /* unlock all sectors */
    __HAL_FLASH_REGISTER_UNLOCK;
    FLASH->SLOCK0 = 0xFFFFFFFFul;

    __HAL_FLASH_REGISTER_UNLOCK;
    FLASH->SLOCK1 = 0xFFFFFFFFul;

    return (0);                                  // Finished without Errors
}


/*
 *  De-Initialize Flash Programming Functions
 *    Parameter:      fnc:  Function Code (1 - Erase, 2 - Program, 3 - Verify)
 *    Return Value:   0 - OK,  1 - Failed
 */

int UnInit (unsigned long fnc)
{
    // flash change to read mode
    __HAL_FLASH_REGISTER_UNLOCK;
    FLASH->CR &= ~(FLASH_CR_OP_Msk);

    /* lock all sectors */
    __HAL_FLASH_REGISTER_UNLOCK;
    FLASH->SLOCK0 = 0x0ul;

    __HAL_FLASH_REGISTER_UNLOCK;
    FLASH->SLOCK1 = 0x0ul;

    __HAL_FLASH_REGISTER_LOCK;
    return (0);                                  // Finished without Errors
}


/*
 *  Erase complete Flash Memory
 *    Return Value:   0 - OK,  1 - Failed
 */

int EraseChip (void)
{
    __HAL_FLASH_REGISTER_UNLOCK;
    MODIFY_REG(FLASH->CR, FLASH_CR_OP_Msk, FLASH_OP_CHIPERASE);

    *(__IO uint32_t *)0x0 = 0x5555AAAA;

    while( __HAL_FLASH_GET_FLAG(FLASH_FLAG_BSY) == FLASH_FLAG_BSY )
    {
        __asm("nop");
    }

    return (0);                                  // Finished without Errors
}


/*
 *  Erase Sector in Flash Memory
 *    Parameter:      adr:  Sector Address
 *    Return Value:   0 - OK,  1 - Failed
 */

int EraseSector (unsigned long adr)
{
    if( adr > CONFIG_FLASH_DATA_BASE + (CONFIG_FLASH_SIZE << 10) )
        return 1;

    __HAL_FLASH_REGISTER_UNLOCK;
    MODIFY_REG(FLASH->CR, FLASH_CR_OP_Msk, FLASH_OP_SECTORERASE);
    *(__IO uint32_t *)adr = 0x5555AAAA;

    while( __HAL_FLASH_GET_FLAG(FLASH_FLAG_BSY) == FLASH_FLAG_BSY )
    {
        __asm("nop");
    }
    return (0);                                  // Finished without Errors
}


/*
 *  Program Page in Flash Memory
 *    Parameter:      adr:  Page Start Address
 *                    sz:   Page Size
 *                    buf:  Page Data
 *    Return Value:   0 - OK,  1 - Failed
 */

int ProgramPage (unsigned long adr, unsigned long sz, unsigned char *buf)
{
    if( (adr + sz) > CONFIG_FLASH_DATA_BASE + (CONFIG_FLASH_SIZE << 10) )
        return 1;

    while( sz-- )
    {
        __HAL_FLASH_REGISTER_UNLOCK;
        MODIFY_REG(FLASH->CR, FLASH_CR_OP_Msk, FLASH_OP_PROGRAM);

        /* Write data in the address */
        *(__IO uint8_t *)adr++ = *buf++;

        while( __HAL_FLASH_GET_FLAG(FLASH_FLAG_BSY) == FLASH_FLAG_BSY )
        {
            __asm("nop");
        }
    }

    return (0);                                  // Finished without Errors
}
