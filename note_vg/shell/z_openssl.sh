#!/bin/bash

set -e

##############
# symmetric cryptography

# AES
# 指定密碼進行對稱加密
openssl enc -aes-128-cbc -in test.py -out entest.py -pass pass:123456

# 指定文件進行對稱加密
openssl enc -aes-128-cbc -in test.py -out entest.py -pass file:passwd.txt

# 指定環境變量進行對稱加密
openssl enc -aes-128-cbc -in test.py -out entest.py -pass env:passwd

# 指定密碼進行對稱解密
openssl enc -aes-128-cbc -d -in entest.py -out test.py -pass pass:123456

# 指定文件進行對稱解密
openssl enc -aes-128-cbc -d -in entest.py -out test.py -pass file:passwd.txt

# 指定環境變量進行對稱解密
openssl enc -aes-128-cbc -d -in entest.py -out test.py -pass env:passwd


##############
# asymmetric cryptography

# RSA
# 輔以 AES-128 算法, 生成 2048 比特長度的私鑰
openssl genrsa -aes128 -out private.pem 2048

# 根據私鑰來生成公鑰
openssl rsa -in private.pem -outform PEM -pubout -out public.pem

# 使用公鑰進行加密
openssl rsautl -encrypt -in passwd.txt -inkey public.pem -pubin -out enpasswd.txt

# 使用私鑰進行解密
openssl rsautl -decrypt -in enpasswd.txt -inkey private.pem -out passwd.txt

# 我們發行出去安裝包中, 源碼應該是被加密過的, 那麼就需要在構建階段對源碼進行加密.加密的過程如下：
# 1. 隨機生成一個密鑰.這個密鑰實際上是一個用於對稱加密的密碼.
# 2. 使用該密鑰對源代碼進行對稱加密, 生成加密後的代碼.
# 3. 使用公鑰（生成方法見 非對稱密鑰加密算法）對該密鑰進行非對稱加密, 生成加密後的密鑰.

# 不論是加密後的代碼還是加密後的密鑰, 都會放在安裝包中.它們能夠被用戶看到, 卻無法被破譯.
