import sys
import re
import select
import time
#from colors import *    # pip3 install ansicolors

import re
from colorama import init,Fore,Back,Style # pip3 install colorama
init()

padding = 0

#####################################################################
# replace
#####################################################################

table = []
cur_idx = -1
def reset_replace():
    global table,cur_idx
    table = []
    cur_idx = -1

def dump_replace():
    global table
    for idx,replace_str in table:
        print(f"${idx}$ -> {replace_str}")

def add_replace(str):
    global table,cur_idx
    cur_idx += 1
    #table[cur_idx] = (cur_idx, str)
    table.append( (cur_idx, str) )
    #print("add: ",cur_idx," = ",str)
    return cur_idx

def apply_replace(str):
    #print("= ",str)
    global table
    if not table:
        return str
    #table.reverse()
    for idx,replace_str in table:
        #print("- ",idx,replace_str)
        str = str.replace(f"_@{idx}@_", replace_str)
        #print("  -> ",str)
    reset_replace()
    return str

def replace_trim_and_matched(s,pattern, col,ltrim,rtrim):
    match = re.search(pattern, s)
    if match:
        target = match.group()
        trimmed_target = target.lstrip(ltrim).rstrip(rtrim)
        idx = add_replace( color(trimmed_target,col) )
        return s.replace(target, f"_@{idx}@_",999)
    else:
        return s

def replace_matched(s,pattern, col):
    match = re.search(pattern, s)
    if match:
        #print("***",s)
        ##print("match.lastindex:", match.lastindex)
        #if match.lastindex:
        #    #print("process:",s, match.group())
        #    for i in range(1,match.lastindex+1):
        #        target = match.group(i)
        #        if target == None:
        #            continue
        #        #print("- ",i,target)
        #        #print(target, " <-- " , color(target,col)  )
        #        idx = add_replace( color(target,col) )
        #        s = s.replace(target, f"_@{idx}@_",999)
        #        #print("  -> ",s)
        #    return s
        #else:
            target = match.group()
            #print(target, " <-- " , color(target,col)  )
            idx = add_replace( color(target,col) )
            return s.replace(target, f"_@{idx}@_",999)
    else:
        return s

#####################################################################

def color_paths(line, replacement):
    # 正規表現で / で始まり、 .erl のような拡張子で終わるか、 / で終わるパスをマッチする
    #pattern = r'\/[\w\/.-]+(\.\w+|\/)'
    pattern = r'\/[\w\/.-]+(\.\w+|\/)'
    return re.sub(pattern, replacement, line)

#  BLACK           = 30
#  RED             = 31
#  GREEN           = 32
#  YELLOW          = 33
#  BLUE            = 34
#  MAGENTA         = 35
#  CYAN            = 36
#  WHITE           = 37
#  RESET           = 39
#  LIGHTBLACK_EX   = 90
#  LIGHTRED_EX     = 91
#  LIGHTGREEN_EX   = 92
#  LIGHTYELLOW_EX  = 93
#  LIGHTBLUE_EX    = 94
#  LIGHTMAGENTA_EX = 95
#  LIGHTCYAN_EX    = 96
#  LIGHTWHITE_EX   = 97

def color(str,col):
    return col + str + Style.RESET_ALL

def color_escaped_strings(s, col):
    # エスケープされた " や ' や """ で囲まれた文字列にマッチする正規表現
    pattern = r'\"\"\".*?\"\"\"|\'\'\'.*?\'\'\'|\"(\\\\\"|[^\"])*\"|\'(\\\\\'|[^\'])*\''
    return replace_matched(s,pattern,col)

def color_erlang_binary_text(s, col):
    #pattern = r'<<\"((?:\\\\.|[^\\\\\"])*)\">>'
    #pattern = r'<<\".*\">>'
    #pattern = r'<<\"(.*?)\">>'
    pattern = r'<<"(.*?)">>'
    return replace_trim_and_matched(s,pattern,col,'<<"','">>')

def color_function(s, col):
    pattern = r'#Fun<[^>]+>'
    return replace_matched(s,pattern,col)

def color_line_lineno(s, col):
    pattern = r'\bline[ ,](\d+)\b'
    return replace_matched(s,pattern,col)

# def color_file_paths(input_str,COLOR):
#     # 正規表現でUNIXファイルパスまたはWindowsファイルパスを検出します。
#     # この正規表現は単純なものであり、すべての可能なファイルパスにマッチするわけではありませんが、一般的なケースで動作します。
#     #file_path_pattern = r'(/[\w\-. /]+)|(C:\\[\w\-. \\]+)'
#     file_path_pattern = r'(/[\w\-. @/]+)|(C:\\[\w\-. \\]+)|(/[\w\-. /]+\.erl)|(/[\w\-. /]+ebin)|(#Fun<[^>]+>)'
# 
#     def replacer(match):
#         # ANSIエスケープシーケンスで青色にします。34mは青色です。
#         #return f'\033[34m{match.group()}\033[0m'
#         return color(match.group(), Fore.BLUE)
#     # 文字列内のファイルパスを色付けします。
#     hilighted_str = re.sub(file_path_pattern, replacer, input_str)
#     return hilighted_str

def add_newline_after_key_value(input_str):
    # KEY => VALUE, の形式に一致する箇所の最後（すなわち、カンマ）に改行を追加
    return re.sub(r'(=>[^,]+,)', r'\1\n', input_str)

def add_newline_before_file_type(input_str):
    tokens = input_str.split("[{file,")
    if len(tokens) == 1:
        return [input_str]
    else:
        #return [ (token + "[{file,") for token in tokens ]
        return [ ("[{file," + token) for token in tokens ]

DEBUG = False

# # r'/.*\.erl[\s\(\)\[\]\{\}<>:]+',
# # r'/.*\.gleam[\s\(\)\[\]\{\}<>:]+',
# # r'/.*/ebin/',
# file_patterns = [
#     r'(/.*\.erl)',
#     r'/.*\.gleam',
#     r'/.*/ebin/',
#     r'#Fun<.*>',
# ]

indent_plus_patterns = [
    #'#(','#{','(','[','{'
    '(','[','{'
]
indent_minus_patterns = [
    ')','}',']'
]
reserved_patterns = [
    #'#(','#{','=>','->',",",
    #'(',')','[',']','{','}',':',
    '=>','->',",",':',
]
dimm_patterns = [
    '<<"','">>',
]

def color_patterns(patterns,input_str, col):
    for pattern in patterns:
        if input_str.find(pattern) == -1:
            continue

        idx = add_replace(color(pattern, col))
        output_str = input_str.replace(pattern, f"_@{idx}@_",999)
        #output_str = input_str.replace(pattern, color("\\1",col),100)
        if output_str == None:
            continue
        if output_str == input_str:
            continue
        input_str = output_str
    #print("- ",input_str)
    return input_str

def color_indent_patterns(patterns,input_str, col,d):
    global padding
    output_str = ""
    for pattern in patterns:
        if input_str.find(pattern) == -1:
            continue

        padding += d*2
        idx = add_replace(color(pattern, col))
        output_str = input_str.replace(pattern, f"_@{idx}@_",999)
        #output_str = input_str.replace(pattern, color("\\1",col),100)
        if output_str == None:
            continue
        if output_str == input_str:
            continue
        input_str = output_str
    #return output_str
    return input_str


#####################################################################

def color_line(line):
    if line.startswith("%"):
        return color(line, Fore.CYAN+Style.DIM)
    elif line.startswith("Hint:"):
        return color(line, Fore.GREEN+Style.DIM)
    elif line.startswith("Testing"):
        return color(line, Fore.YELLOW+Style.BRIGHT)
    elif line.startswith("TEST:"):
        return color(line, Fore.GREEN+Style.BRIGHT)
    elif "Warning:" in line:
        return color(line, Fore.GREEN+Style.DIM)
    elif "0: soft failing tests" in line:
        return color(line, Fore.WHITE+Style.DIM)
    elif "0: failing tests" in line:
        return color(line, Fore.WHITE+Style.DIM)
    elif "FAILED" in line:
        return color(line, Fore.RED)
    elif "Expected" in line:
        return color(line, Fore.CYAN)
    elif "Got" in line:
        return color(line, Fore.MAGENTA)
    elif "failing tests" in line:
        return color(line, Fore.RED+Style.BRIGHT)
    elif "passing tests" in line:
        return color(line, Fore.WHITE+Style.BRIGHT)
    else:
        return line




def read_stdin():
    buf = ""
    while True:
        # selectを用いてstdinが読み込み可能かどうかをチェック
        timeout = 1
        rlist, _, _ = select.select([sys.stdin], [], [], timeout)

        #print(rlist)
        
        if rlist:
            # 1文字読む
            c = sys.stdin.read(1)
            #print(c)
            if c == "\n" or c == "\r":
                # 改行コードの場合はバッファを返す
                return buf
            elif c == '':
                print("EOF detected. Exiting.")
                if buf == "":
                    return None
                else:
                    #print("buf",buf)
                    return buf
            else:
                buf += c
        else:
            # 読める文字がない場合
            if buf == "":
                continue
            else:
                return buf


# Regular expressions
comment_pattern = re.compile(r"^#+\s*(.*)$")
block_start_pattern = re.compile(r"=([^=]*)==== \d+-\w+-\d+::\d+:\d+:\d+\.\d+ ===")
erl_shell_start_pattern = re.compile(r"Eshell V[^ ]* \(press Ctrl\+G to abort, type help\(\)\. for help\)")
erl_prompt_pattern = re.compile(r"^[0-9]*>")
escape_sequence_pattern = re.compile(r"(\\e\[\d+(;\d+)*m)")
item_pattern1 = re.compile(r"^([^: ]*):\s*$")
item_pattern2 = re.compile(r"^([^->]*):\s*$")
item_patternns = [item_pattern1, item_pattern2]
line_number_pattern = re.compile(r"\{line,([^\}]*)\}")

def read_stdin():
    readline = sys.stdin.readline()
    while readline:
        if readline == "":
            return None

        lines = add_newline_before_file_type(readline)
        for readline in lines:
            if len(readline) > 40:
                #print("***",readline)
                readline = add_newline_after_key_value(readline)
                lines = readline.split("\n")
            else:
                lines = [readline]

            for line in lines:
                yield line
        readline = sys.stdin.readline()

def loop():
    global padding
    line_color = Fore.WHITE
    line = ""
    nline = ""

    def emit():
        nonlocal line_color,nline
        #print(f"{line_color}{print_padding()}{nline}{RESET}")
        #print(f"{print_padding()}{color(nline,line_color)}")
        print(f"{print_padding()}{color(nline,line_color)}")
        nline = None

    def print_padding():
        global padding
        return " " * padding


    # Read lines from standard input
    for line in read_stdin():
        nline = line.strip(" \r\n\t")
        if nline == "":
            continue

        if nline.startswith("TEST:"):
            continue
    
        nline = color_line(nline)

        line_color = Fore.LIGHTBLUE_EX
        line_color = Fore.CYAN + Style.BRIGHT

        print(color(nline,line_color))



def test():
    str = "uhoho]/abc/def/ghi.erl[DESUYO!"
    #print(color_erl_path(str, Fore.MAGENTA))
    print(color_file_paths(str, Fore.MAGENTA))

if __name__ == "__main__":
    #test()
    loop()