
#if 1

#include "stdafx.h"
#include <windows.h>
#include <iostream.h>

void CALLBACK OnTimer(HWND hWnd, Uint nMsg, Uint nIDEvent, DWORD dwTime)
{
    cout << "Time: " << dwTime << endl;
}

int main()
{
    MSG Msg;
    Uint TimerId = SetTimer(NULL, 0, 500, &OnTimer);
//底下的 while loop是讓Timer得以運作的關鍵
    while (GetMessage(&Msg, NULL, 0, 0))
        DispatchMessage(&Msg);//預設的WM_TIMER訊息處理會呼叫OnTimer
    KillTimer(NULL, TimerId);
    return 0;
}

#else
    
// lib: user32.dll (SetTimer)

void CALLBACK TimerProc(HWND hwnd, Uint uMsg, UINT_PTR idEvent, DWORD dwTime);

struct TIMER_INFO
{
    UINT_PTR Timer_id;
    int Time_up;
    HWND Hwnd;
    Uint Timer_idx;

    TIMER_INFO(UINT_PTR id, int time_up, HWND hwnd);
};
//========================================================================================

TIMER_INFO::TIMER_INFO(UINT_PTR id, int time_up, HWND hwnd)
{
    Timer_id = id;
    Time_up = time_up;
    Hwnd = hwnd;
}
//---------------------------------------------------------------------------

//========================================================================================
//========================================================================================
class X8TIMER
{
private:

    static DWORD WINAPI HandleTimer(LPvoid timer_info);

public:

    X8TIMER();

    int StartUp(struct TIMER_INFO *timer_info);
    int Stop(struct TIMER_INFO timer_info);

};

//========================================================================================

X8TIMER::X8TIMER()
{
    //
}
//---------------------------------------------------------------------------

int X8TIMER::StartUp(struct TIMER_INFO *timer_info)
{

    HANDLE hThread = ::CreateThread(NULL, NULL, (LPTHREAD_START_ROUTINE)X8TIMER::HandleTimer, (LPvoid)timer_info, NULL, NULL);
    CloseHandle(hThread);

    return SUCCESS;
}
//---------------------------------------------------------------------------

DWORD WINAPI X8TIMER::HandleTimer(LPvoid timer_info)
{
    TIMER_INFO *timer_data;

    timer_data = (TIMER_INFO *)timer_info;

    timer_data->Timer_idx = ::SetTimer(timer_data->Hwnd, timer_data->Timer_id, timer_data->Time_up, TimerProc);
    MSG MMsg;


    while ( GetMessage(&MMsg, NULL, 0, 0) )
    {
        TranslateMessage(&MMsg);
        DispatchMessage(&MMsg);
    }

    return 0;

}
//---------------------------------------------------------------------------

int X8TIMER::Stop(struct TIMER_INFO timer_info)
{

    KillTimer(timer_info.Hwnd, timer_info.Timer_idx);

    return SUCCESS;
}
//---------------------------------------------------------------------------


void CALLBACK TimerProc(HWND hwnd, Uint uMsg, UINT_PTR idEvent, DWORD dwTime)
{
    debuglog(ERR, "Time out !");
}
#endif
