@ECHO OFF

SET DIFFTOOL="%ProgramFiles(x86)%\WinMerge\WinMergeU.exe -s -e -x -ul -ur -wl -dl %%bname -dr %%yname %%base %%mine"
SET MERGETOOL="%ProgramFiles(x86)%\WinMerge\WinMergeU.exe %%theirs %%mine %%merged"

REG ADD HKEY_CURRENT_USER\Software\TortoiseGit /v Diff       /t REG_SZ /d %DIFFTOOL% /f
REG ADD HKEY_CURRENT_USER\Software\TortoiseGit /v DiffViewer /t REG_SZ /d %DIFFTOOL% /f
REG ADD HKEY_CURRENT_USER\Software\TortoiseGit /v Merge      /t REG_SZ /d %MERGETOOL% /f