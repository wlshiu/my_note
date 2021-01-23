import sys
import argparse
import struct

parser = argparse.ArgumentParser()
parser.add_argument("-o", "--Output", type=str, help="output file")
parser.add_argument("-r", "--Related", type=str, help="Related function file")
parser.add_argument("-i", "--Input", type=str, help="input Function list file")

args = parser.parse_args()

if args.Output:
    Func_list2 = open(args.Output,'w')
else:
    Func_list2 = open("Func_list2.txt",'w')

Object_list = open("Obj_list.txt", 'w')

if args.Input:
    input_file = args.Input
else:
    input_file = "Func_list.txt"


if args.Related:
    related_file = args.Related
else:
    related_file = "function_relation"

text_list = [" "]*102400
obj_list = [" "]*10240
count = 1

obj_count = 1


def search_obj(func):
    find = 0
    target = ".text."+func

    for line in open("sdk_ut.map"):
        if (find == 1):
            if (".o)" in line):
                tmp_line = line
                break
            else:
                if (func not in line):
                    find = 0
                    break;

        if target not in line:
            continue
        else:
            find = 1
            if ".o)" in line:
                tmp_line = line
                break
            else:
                continue

    if (find == 1) and ".o)" in tmp_line:
       tmp_line = tmp_line.split("(")[1].split(")")[0]
       #Object_list.write(tmp_line + "\n")

       obj_find = 0
       for i in range(obj_count):
           if obj_list[obj_count - i] == tmp_line:
               obj_find = 1
               break

       if (obj_find == 0):
           global obj_count 
           obj_list[obj_count] = tmp_line
           obj_count = obj_count + 1
           Object_list.write("*"+tmp_line + "* (.rodata* )\n")
    else:
        print("can't find %s\n", func)
         #Object_list.write(func + " can't find \n")

    return 0
    

#insert and search
def insert_and_search(func):
    global count 
    text_list[count] = func
    count = count + 1
    print("count = %d func = %s\n", count, func)
    if func != "main":
        Func_list2.write("* (.text." + func + "*)\n")
        search_obj(func)
    search_function(func)
    return 0;


# recursive find in table
def search_function(func_name):
    global count 
    find = 0
    for line in open(related_file):
        if "->" in line:
            # "source_func" -> "dst_func"
            source_func = line.split("\"")[1].split("\"")[0]
            dst_func = line.split("\"")[3].split("\"")[0]

            if source_func == func_name:
                find = 1
                exist = 0
                # search table and insert if not exist
                for i in range(count):
                    if text_list[count - i] == dst_func:
                        exist = 1
                        break;

                # if first time to insert, find related function by recursive
                if exist == 0:
                    insert_and_search(dst_func)
            # if already find targe function, then break loop
            elif find == 1:
                break;
    return 0
            
# search search list and put into table
for line in open(input_file):
    find = 0
    if ".text." in line:
        if ".startup.main" in line:
            Func_list2.write("* (.text.startup.main)\n")
            search_function("main");
            print("search main in top\n")
        else:
            tmp = line.split(".text.")[1].split(")")[0]

            # search table and skip if already exist
            for i in range(count):
                if text_list[count - i] == tmp:
                    find = 1
                    break

            if find == 1:
                continue
            else:
                print("search %s in top\n", tmp)
                search_function(tmp);

Func_list2.close()
Object_list.close()
