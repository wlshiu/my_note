# coding=utf-8
'''
@ Summary: 從網頁上下載音頻數據集
    待優化：
        1. 每次需要重新下載（已解決）
        2. 先下載MP3
        3. 然後轉成wav 刪除MP3, 內存比較浪費
@ Using:
    每次使用完記得更新cur_id這個值 爬完會有一個最後的name輸出，更新掉就好了
    接著才會下載新錄好的語音文件

@ file:    get_wav.py
@ version: 1.0.1

@ Author:  Lebhoryi@rt-thread.com
@ Date:    2020/3/20 下午5:14
'''
import os
import requests
import bs4
import urllib
from pydub import AudioSegment

def open_url(host):
    # use proxy
    # proxies = {"http": "127.0.0.1:1080", "https": "127.0.0.1:1080"}
    # not use proxy
    headers =  {'user-agent': 'Mozilla/5.0 (Windows NT 10.0; WOW64; rv:47.0) Gecko/20100101 Firefox/47.0'}

    # res = requests.get(host, headers=headers, proxies=proxies)
    res = requests.get(host, headers=headers)

    return res

def get_urls(host, res, cur_id):
    # find all pages
    soup = bs4.BeautifulSoup(res.text, "html.parser")
    target = soup.find_all("a")

    mp3_url, mp3_name = [], []
    for i in target:
        # print(i.get("href")) and int(i.get("href")[]) > cur_id
        if i.get("href")[:2] == "15" and int(i.get("href")[:-4]) > cur_id:
            mp3_url.append(host + i.get("href"))
            mp3_name.append(i.get("href"))

    return mp3_url, mp3_name

if __name__ == "__main__":
    host = "http://www.rt-thread.com/service/rec2/mp3/"
    res = open_url(host)
    cur_id = 1594780145  # 最新的id,如果不確定，去網頁上看一下最新的id
    urls, names = get_urls(host, res, cur_id)  # get url list
    filepath = "../data_from_web/"
    # creat filepath
    if not os.path.exists(filepath):
        os.mkdir(filepath)

    # download mp3
    for i in range(len(urls)):
        # get .mp3
        x = urllib.request.urlretrieve(urls[i], filepath+names[i])

        # .mp3 to .wav
        song = AudioSegment.from_mp3(x[0])
        song.export((filepath+names[i])[:-4]+".wav", format="wav")

        # delete .mp3
        os.remove(filepath+names[i])
        print("正在抓取第{}條音頻...".format(i+1))
    print("最新的文件名是{}...".format(names[-1:]))

