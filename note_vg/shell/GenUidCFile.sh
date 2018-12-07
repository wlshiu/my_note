#!/bin/bash

set -e

help()
{
    echo -e "usage: $0 [file name]"
    exit 0
}

if [ $# != 1 ]; then
    help
fi

out_name=$1
year=$(date +%Y)

today=$(date +%Y/%m/%d)

uid=$(echo -e `uuidgen` | sed -r "s/-/_/g")

# echo -e "${uid}"

#############################
echo -e "/**"                                                       > ${out_name}.h
echo -e " * Copyright (c) $year Wei-Lun Hsu. All Rights Reserved."  >> ${out_name}.h
echo -e " */"                                                       >> ${out_name}.h

echo -e "/** @file ${out_name}.h"                                   >> ${out_name}.h
echo -e " *"                                                        >> ${out_name}.h
echo -e " * @author Wei-Lun Hsu"                                    >> ${out_name}.h
echo -e " * @version 0.1"                                           >> ${out_name}.h
echo -e " * @date ${today}"                                         >> ${out_name}.h
echo -e " * @license"                                               >> ${out_name}.h
echo -e " * @description"                                           >> ${out_name}.h
echo -e " */\n\n"                                                   >> ${out_name}.h

echo -e "#ifndef __${out_name}_H_${uid}__"                          >> ${out_name}.h
echo -e "#define __${out_name}_H_${uid}__\n"                        >> ${out_name}.h
echo -e "#ifdef __cplusplus\nextern \"C\" {\n#endif\n\n"            >> ${out_name}.h


echo -e "//============================================================================="   >> ${out_name}.h
echo -e "//                  Constant Definition"                                           >> ${out_name}.h
echo -e "//=============================================================================\n" >> ${out_name}.h
echo -e "//============================================================================="   >> ${out_name}.h
echo -e "//                  Macro Definition"                                              >> ${out_name}.h
echo -e "//=============================================================================\n" >> ${out_name}.h
echo -e "//============================================================================="   >> ${out_name}.h
echo -e "//                  Structure Definition"                                          >> ${out_name}.h
echo -e "//=============================================================================\n" >> ${out_name}.h
echo -e "//============================================================================="   >> ${out_name}.h
echo -e "//                  Global Data Definition"                                        >> ${out_name}.h
echo -e "//=============================================================================\n" >> ${out_name}.h
echo -e "//============================================================================="   >> ${out_name}.h
echo -e "//                  Private Function Definition"                                   >> ${out_name}.h
echo -e "//=============================================================================\n" >> ${out_name}.h
echo -e "//============================================================================="   >> ${out_name}.h
echo -e "//                  Public Function Definition"                                    >> ${out_name}.h
echo -e "//=============================================================================\n" >> ${out_name}.h

echo -e "#ifdef __cplusplus\n}\n#endif\n\n#endif\n\n"                                       >> ${out_name}.h

#############################
echo -e "/**"                                                       > ${out_name}.c
echo -e " * Copyright (c) $year Wei-Lun Hsu. All Rights Reserved."  >> ${out_name}.c
echo -e " */"                                                       >> ${out_name}.c

echo -e "/** @file ${out_name}.c"                                   >> ${out_name}.c
echo -e " *"                                                        >> ${out_name}.c
echo -e " * @author Wei-Lun Hsu"                                    >> ${out_name}.c
echo -e " * @version 0.1"                                           >> ${out_name}.c
echo -e " * @date ${today}"                                         >> ${out_name}.c
echo -e " * @license"                                               >> ${out_name}.c
echo -e " * @description"                                           >> ${out_name}.c
echo -e " */\n\n"                                                   >> ${out_name}.c
echo -e "#include \"${out_name}.h\"\n"                              >> ${out_name}.c

echo -e "//============================================================================="   >> ${out_name}.c
echo -e "//                  Constant Definition"                                           >> ${out_name}.c
echo -e "//=============================================================================\n" >> ${out_name}.c
echo -e "//============================================================================="   >> ${out_name}.c
echo -e "//                  Macro Definition"                                              >> ${out_name}.c
echo -e "//=============================================================================\n" >> ${out_name}.c
echo -e "//============================================================================="   >> ${out_name}.c
echo -e "//                  Structure Definition"                                          >> ${out_name}.c
echo -e "//=============================================================================\n" >> ${out_name}.c
echo -e "//============================================================================="   >> ${out_name}.c
echo -e "//                  Global Data Definition"                                        >> ${out_name}.c
echo -e "//=============================================================================\n" >> ${out_name}.c
echo -e "//============================================================================="   >> ${out_name}.c
echo -e "//                  Private Function Definition"                                   >> ${out_name}.c
echo -e "//=============================================================================\n" >> ${out_name}.c
echo -e "//============================================================================="   >> ${out_name}.c
echo -e "//                  Public Function Definition"                                    >> ${out_name}.c
echo -e "//=============================================================================\n" >> ${out_name}.c
echo -e " \n\n"                                                                            >> ${out_name}.c


