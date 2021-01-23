import struct

FUNC_LOG_MAX = 1024 * 1024 * 2

Mapping_file = open("Func_Mapping.txt",'w')
Func_list = open("Func_list.txt",'w')
source = open("funbin.bin",'rb')
count = 0

object_list = [" "]*10240

# big-little endian transfer
def big_little_transfer(string):
    hi, lo = struct.unpack("<HH", string)
    n = (lo << 16) | hi
    return n


# search address in file
def search_address(value):
    find = 0
    text_line = ""
    for line in open("skd_ut.map"):
        # log .text.function
        if ".text." in line:
            text_line = line

        # find match address with trace
        if "0x" in line and format(value, 'x') in line:
            '''
            # Mapping file for debug, can remove this section
            if(text_line != line):
                Mapping_file.write("case 1 find %d \n" % value)
                Mapping_file.write(str(line) + "\n")
                Mapping_file.write(text_line + "\n")
            else:
                Mapping_file.write("case 2\n")
                Mapping_file.write(text_line + "\n")
            '''
           
            if ".text." not in text_line:
                find = 0
                continue

            # find address and log to file
            find = 1
            tmp_line = text_line.split()[0]
            
            '''
            # check function appear before(can remove)
            for i in range(count):
                if object_list[i] == tmp_line:
                    return 0

            object_list[count] = tmp_line
            '''

            
            Func_list.write("* (" + tmp_line + ")\n")
            break

    #Mapping_file.write("\n")
    return find


# main function
for n in range(1, FUNC_LOG_MAX):
    # read 4byte from bin in each round
    rawstring = source.read(4)
    
    # big-little endian transfer
    value = big_little_transfer(rawstring)
    
    # source file -> EOF
    if(value == 0):
        break

    # search address in file
    RetVal = search_address(value)

    # print address not found
    if(RetVal == 0):
        print "%x not found" % value
    else:
        count = count + 1

print "total count = %u" % count

Mapping_file.close()
Func_list.close()
source.close()
