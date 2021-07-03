
#define GPIO_KEY_1          (0x1ul << 1)
#define GPIO_KEY_2          (0x1ul << 2)
#define GPIO_KEY_3          (0x1ul << 3)

uint32_t
GPIOKeyGet(
    void)
{
    uint32_t key = 0;
    uint32_t data = 0;
    uint32_t data_gpio1 = 0;
    uint32_t data_gpio2 = 0;
    uint32_t data_gpio3 = 0;

// 9 keys
    if ( GetDuration(lastClock) >= (KEY_SENSITIVITY >> 1))
    {
        int scan_round = 0;             // the round number of scanning key

start_scan:
        scan_round++;

        // set data_gpio 1 , 2 ,3 input mode
        _SetGpioMode(GPIO_INPUT_MODE, DEDICATED_GPIO, (GPIO_KEY_1 | GPIO_KEY_2 | GPIO_KEY_3));
        data = 0;
        Sleep(1);
        _GetGpioState(DEDICATED_GPIO, (GPIO_KEY_1 | GPIO_KEY_2 | GPIO_KEY_3), &data);

        data_gpio1 = data & GPIO_KEY_1;
        data_gpio2 = data & GPIO_KEY_2;
        data_gpio3 = data & GPIO_KEY_3;

        if (!(data_gpio1) )
        {
            // 3C_Key1
            key = KEY_X_0;
            lastClock = GetClock();
            if (scan_round == 1)
            {
                goto start_scan;
            }
            else if (scan_round == 2)
            {
                printf("[key] press UP \n");
                return key;
            }
        }
        else if (!(data_gpio2) )
        {
            // 3C_Key2
            key = KEY_X_1;
            lastClock = GetClock();
            if (scan_round == 1)
            {
                goto start_scan;
            }
            else if (scan_round == 2)
            {
                printf("[key] press POWER \n");
                return key;
            }
        }
        else if ( !(data_gpio3))
        {
            // 3C_Key3
            key = KEY_X_2;
            lastClock = GetClock();
            if (scan_round == 1)
            {
                goto start_scan;
            }
            else if (scan_round == 2)
            {
                printf("[key] press ENTER \n");
                return key;
            }
        }

        data = 0;
        // GPIO_Key1 set on Output mode and data = 0, GPIO_Key2 & GPIO_Key3 Set on Input Mode
        _SetGpioState(DEDICATED_GPIO, GPIO_KEY_1, 0);
        _SetGpioMode(GPIO_INPUT_MODE, DEDICATED_GPIO, GPIO_KEY_2 | GPIO_KEY_3);
        Sleep(1);
        _GetGpioState(DEDICATED_GPIO, (GPIO_KEY_2 | GPIO_KEY_3), &data);

        data_gpio2 = data & GPIO_KEY_2;
        data_gpio3 = data & GPIO_KEY_3;

        if (!(data_gpio2) )
        {
            // 3C_Key4
            key = KEY_X_3;
            lastClock = GetClock();
            if (scan_round == 1)
            {
                goto start_scan;
            }
            else if (scan_round == 2)
            {
                printf("[key] press MENU \n");
                return key;
            }
        }
        else if ( !(data_gpio3) )
        {
            // 3C_Key5
            key = KEY_X_4;
            lastClock = GetClock();
            if (scan_round == 1)
            {
                goto start_scan;
            }
            else if (scan_round == 2)
            {
                printf("[key] press RIGHT \n");
                return key;
            }
        }

        data = 0;
        // GPIO_Key2 set on Output mode and data = 0,  GPIO_Key1 & GPIO_Key3 Set on Input Mode
        _SetGpioState(DEDICATED_GPIO, GPIO_KEY_2, 0);
        _SetGpioMode(GPIO_INPUT_MODE, DEDICATED_GPIO, GPIO_KEY_1 | GPIO_KEY_3);
        Sleep(1);
        _GetGpioState(DEDICATED_GPIO, (GPIO_KEY_1 | GPIO_KEY_3), &data);

        data_gpio1 = data & GPIO_KEY_1;
        data_gpio3 = data & GPIO_KEY_3;

        if(!(data_gpio1))
        {
            // 3C_Key6
            key = KEY_X_5;
            lastClock = GetClock();
            if (scan_round == 1)
            {
                goto start_scan;
            }
            else if (scan_round == 2)
            {
                printf("[key] press CANCEL \n");
                return key;
            }
        }
        else if (!(data_gpio3) )
        {
            // 3C_Key7
            key = KEY_X_6;
            lastClock = GetClock();
            if (scan_round == 1)
            {
                goto start_scan;
            }
            else if (scan_round == 2)
            {
                printf("[key] press DOWN \n");
                return key;
            }
        }

        data = 0;
        // GPIO_Key3 set on Output mode and data = 0, GPIO_Key1 & GPIO_Key2 Set on Input Mode
        _SetGpioState(DEDICATED_GPIO, GPIO_KEY_3, 0);
        _SetGpioMode(GPIO_INPUT_MODE, DEDICATED_GPIO, GPIO_KEY_1 | GPIO_KEY_2);
        Sleep(1);
        _GetGpioState(DEDICATED_GPIO, (GPIO_KEY_1 | GPIO_KEY_2), &data);

        data_gpio1 = data & GPIO_KEY_1;
        data_gpio2 = data & GPIO_KEY_2;

        if (!(data_gpio1) )
        {
            // 3C_Key8
            key = KEY_X_7;
            lastClock = GetClock();
            if (scan_round == 1)
            {
                goto start_scan;
            }
            else if (scan_round == 2)
            {
                printf("[key] press LEFT \n");
                return key;
            }
        }
        else if ( !(data_gpio2) )
        {
            // 3C_Key9
            key = KEY_X_8;
            lastClock = GetClock();
            if (scan_round == 1)
            {
                goto start_scan;
            }
            else if (scan_round == 2)
            {
                printf("[key] press Volume- \n");
                return key;
            }
        }

    }

    return key;
}
