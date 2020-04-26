#!/usr/bin/env python
#coding=utf-8
import getopt
import os, sys
import zipfile
from Crypto.Cipher import AES
import random, struct
#加密python3的代碼
def transfer3(dir_pref):
    os.system('cython -2 %s.py;'
            'gcc -c -fPIC -I/usr/include/python3.5/ %s.c -o %s.o'
            % (dir_pref, dir_pref, dir_pref))
    os.system('gcc -shared %s.o -o %s.so' % (dir_pref, dir_pref))
    if clear:
        os.system('rm -f %s.c %s.o %s.py' % (dir_pref, dir_pref, dir_pref))
    else:
        os.system('rm -f %s.c %s.o' % (dir_pref, dir_pref))

#加密python2的代碼
def transfer2(dir_pref):
    os.system('cython -2 %s.py;'
              'gcc -c -fPIC -I/usr/include/python2.7/ %s.c -o %s.o'
              % (dir_pref, dir_pref, dir_pref))
    os.system('gcc -shared %s.o -o %s.so' % (dir_pref, dir_pref))
    if clear:
        os.system('rm -f %s.c %s.o %s.py' % (dir_pref, dir_pref, dir_pref))
    else:
        os.system('rm -f %s.c %s.o' % (dir_pref, dir_pref))

#加密AI模型
def encrypt_file(in_filename, out_filename=None, chunksize=64*1024):
    """
    使用AES（CBC模式）加密文件給定的密鑰。
    :param key: 加密密鑰-必須是16、24或32字節長。長按鍵更安全。
    :param in_filename: 輸入的文件的名稱
    :param out_filename: 如果為None，將使用「<in_filename>.enc」。
    :param chunksize: 設置函數用於讀取和加密文件。大塊一些文件和機器的大小可能更快。塊大小必須可被16整除。
    :return: None
    """
    if not out_filename:
        out_filename = in_filename + '.enc'
    salt = ''  # 鹽值
    key = "{: <32}".format(salt).encode("utf-8")
    #iv = ''.join(chr(random.randint(0, 0xFF)) for i in range(16))
    #encryptor = AES.new(key, AES.MODE_CBC, iv)
    iv = b'0000000000000000'
    encryptor = AES.new(key, AES.MODE_CBC, iv)
    filesize = os.path.getsize(in_filename)

    with open(in_filename, 'rb') as infile:
        with open(out_filename, 'wb') as outfile:
            outfile.write(struct.pack('<Q', filesize))
            outfile.write(iv)
            while True:
                chunk = infile.read(chunksize)
                if len(chunk) == 0:
                    break
                elif len(chunk) % 16 != 0:
                    chunk += (' ' * (16 - len(chunk) % 16)).encode("utf-8")

                outfile.write(encryptor.encrypt(chunk))

def zip_dir(dir_path,out_path):
    """
    壓縮指定文件夾
    :param dir_path: 目標文件夾路徑
    :param out_path: 壓縮文件保存路徑+xxxx.zip
    :return: 無
    """

    zip = zipfile.ZipFile(out_path, "w", zipfile.ZIP_DEFLATED)
    for path, dirnames, filenames in os.walk(dir_path):
        # 去掉目標跟路徑，只對目標文件夾下邊的文件及文件夾進行壓縮
        fpath = path.replace(dir_path, '')
        for filename in filenames:
            zip.write(os.path.join(path, filename), os.path.join(fpath, filename))
    zip.close()

if __name__ == '__main__':
    help_show = '''
python version:
   python3        該代碼用於加密python3編寫的代碼,將.py文件轉換成.so文件，達到加密的效果
   python2        該代碼用於加密python2編寫的代碼,將.py文件轉換成.so文件，達到加密的效果

Options:
  -h,  --help       顯示幫助
  -d,  --directory  你需要加密的文件夾
  -o,  --operation  你所需要執行的操作,python3 or python2 or model
  -f,  --file       加密單個py文件
  -c,  --clear      刪除原始的py文件
  -m,  --maintain   列出你不需要加密的文件和文件夾，如果是文件夾的話需要加[]
                    例子: -m __init__.py,setup.py,[poc,resource,venv,interface]
  -z,  --zip        加密之後壓縮文件

Example:
  python setup.py -f test_file.py -o python2     加密單個文件
  python setup.py -d test_dir -o python2 -m __init__.py,setup.py,[poc/,resource/,venv/,interface/] -c      加密文件夾

  python3 setup.py -f test_file.py  -o python3    加密單個文件
  python3 setup.py -d test_dir -o python3 -m __init__.py,setup.py,[poc/,resource/,venv/,interface/] -c      加密文件夾
    '''
    clear = 0
    is_zip = False
    root_name = ''
    operation = ''
    file_name = ''
    m_list = ''
    try:
        options,args = getopt.getopt(sys.argv[1:],"vh:d:f:cm:o:z:",["version","help","directory=","file=","operation=","zip","clear","maintain="])
    except getopt.GetoptError:
        print(help_show)
        sys.exit(1)

    for key, value in options:
        if key in ['-h', '--help']:
            print(help_show)
        elif key in ['-c', '--clear']:
            clear = 1
        elif key in ['-d', '--directory']:
            root_name = value
        elif key in ['-f', '--file']:
            file_name = value
        elif key in ['-o', '--operation']:
            operation = value
        elif key in ['-z','--zip']:
            is_zip = True
        elif key in ['-m', '--maintain']:
            m_list = value
            file_flag = 0
            dir_flag = 0
            if m_list.find(',[') != -1:
                tmp = m_list.split(',[')
                file_list = tmp[0]
                dir_list = tmp[1:-1]
                file_flag = 1
                dir_flag = 1
            elif m_list.find('[') != -1:
                dir_list = m_list[1:-1]
                dir_flag = 1
            else:
                file_list = m_list.split(',')
                file_flag = 1
            if dir_flag == 1:
                dir_tmp = dir_list.split(',')
                dir_list=[]
                for d in dir_tmp:
                    if d.startswith('./'):
                        dir_list.append(d[2:])
                    else:
                        dir_list.append(d)

    if root_name != '':
        if not os.path.exists(root_name):
            print('No such Directory, please check or use the Absolute Path')
            sys.exit(1)
        if os.path.exists('%s_old' % root_name):
            os.system('rm -rf %s_old' % root_name)
        #os.system('cp -r %s %s_old' % (root_name, root_name))   #備份源文件
        try:
            for root, dirs, files in os.walk(root_name):
                for file in files:
                    if m_list != '':
                        skip_flag = 0
                        if dir_flag == 1:
                            for dir in dir_list:
                                if (root+'/').startswith(root_name + '/' + dir):
                                    skip_flag = 1
                                    break
                            if skip_flag:
                                continue
                        if file_flag == 1:
                            if file in file_list:
                                continue
                    pref = file.split('.')[0]
                    dir_pref = root + '/' + pref
                    if file.endswith('.pyc'):
                        os.system('rm -f %s' % dir_pref+'.pyc')
                    elif file.endswith('.so'):
                        pass
                    elif file.endswith('.py'):
                        if operation == 'python3':
                            transfer3(dir_pref)
                        elif operation == 'python2':
                            transfer2(dir_pref)
                        else:
                            pass
        except Exception as e:
            print(e)
    if file_name != '':
        try:
            dir_pref = file_name.split('.')[0]
            if operation == 'python3':
                transfer3(dir_pref)
            elif operation == 'python2':
                transfer2(dir_pref)
            else:
                pass
        except Exception as e:
            print(e)
    if is_zip:
        zip_dir(root_name,root_name+'.zip')
    if operation == 'model':
        encrypt_file(root_name)
