import json
import os
import sys
import re
import random
from PIL import Image, ImageDraw, ImageFont, ImageFilter, ImageChops, ImageEnhance

DIRS = ((0,-1),(1,-1),(1,0),(1,1),(0,1),(-1,1),(-1,0),(-1,-1))
CARDINALS = ((0,-1),(1,0),(0,1),(-1,0))
lines = []
img = None
objs = {}
sx = 1
sy = 1

def run(args):
    run_file(args)

def run_file(args):
    global img
    global sx
    global sy
    global lines
    global objs
    filenames = []
    for filename in os.listdir("./rawmaps/"):
        if (args == "all" or filename.startswith(args)) and filename.endswith(".png") and filename != "template.png":
            filenames.append(filename[:-4])
    writedata = []
    objs = {'H': [' ', 'ladder'], '_': [' ', 'platform'], '=': [' ', 'wooden door']}
    for filename in filenames:
        filename_split = filename.split('-')
        if filename_split.__len__() == 1 or int(filename_split[1]) == 1:
            writedata = []
        lines = []
        img = Image.open("./rawmaps/"+filename+".png").convert('RGB')
        sx, sy = img.size
        process()
        text = ""
        terrain = []
        for line in lines:
            row = ""
            for cell in line:
                row += cell
            terrain.append(row)
            text += row + "\n"
        #print(text)
        meta = {'name': filename, 'chance': 1/(writedata.__len__()+1), 'color': ['#000','#000'], 'foe': '#none', 'to': []}
        writedata.insert(0, [meta, terrain, objs])
        fwrite = open("./Scroller/assets/json/vaults/"+filename_split[0]+".json", "w+")
        fwrite.write(json.dumps(writedata))
        fwrite.close()

def process():
    for y in range(sy):
        line = []
        for x in range(sx):
            cell = pixel_to_char((x, y))
            line.append(cell)
        lines.append(line)
    #process_furniture()
    return lines

def pixel_to_char(at):
    pixel = img.getpixel(at)
    cell = ' '
    if pixel[0] == pixel[1] == pixel[2]:
        if pixel[0] == 0:
            cell = 'D'
        elif pixel[0] == 64:
            cell = '#'
        elif pixel[0] == 128:
            cell = 'H'
    elif pixel == (255, 0, 0): # Red
        cell = '@'
    elif pixel == (127, 0, 0): # Dark Red
        cell = 'X'
    elif pixel == (255, 106, 0): # Orange
        cell = 'B'
    elif pixel == (127, 51, 0): # Dark Orange
        cell = 'b'
    elif pixel == (255, 216, 0): # Yellow
        cell = 'M'
    elif pixel == (127, 106, 0): # Dark Yellow
        cell = 'm'
    elif pixel == (182, 255, 0): # Green
        cell = 'W'
    elif pixel == (91, 127, 0): # Dark Green
        cell = 'w'
    elif pixel == (0, 38, 255): # Blue
        cell = '-'
    elif pixel == (0, 19, 127): # Dark Blue
        cell = '='
    elif pixel == (0, 255, 33): # Teal
        cell = '_'
    return cell

def process_furniture():
    for y in range(1, sy-1):
        for x in range(1, sx-1):
            adjs = get_neighbors_4(x, y)
            if lines[y][x] == "*":
                if adjs.count("X") == 2:
                    if (adjs[0] == "X" and adjs[2] == "X") or (adjs[1] == "X" and adjs[3] == "X"):
                        lines[y][x] = "="

def get_neighbors_in_array(dirarr, x, y, arr, r):
    for i in dirarr:
        if (x+i[0], y+i[1]) in arr:
            r += 1
    return r

def get_neighbors_4(x, y):
    r = [None, None, None, None]
    if y > 0:
        r[0] = lines[y-1][x]
    if x < sx-1:
        r[1] = lines[y][x+1]
    if y < sy-1:
        r[2] = lines[y+1][x]
    if x > 0:
        r[3] = lines[y][x-1]
    return r


def get_neighbors_8(x, y):
    r = [None, None, None, None, None, None, None, None]
    if y > 0:
        r[0] = lines[y-1][x]
        if x < sx-1:
            r[1] = lines[y-1][x+1]
    if x < sx-1:
        r[2] = lines[y][x+1]
        if y < sy-1:
            r[3] = lines[y+1][x+1]
    if y < sy-1:
        r[4] = lines[y+1][x]
        if x > 0:
            r[5] = lines[y+1][x-1]
    if x > 0:
        r[6] = lines[y][x-1]
        if y > 0:
            r[7] = lines[y-1][x-1]
    return r

def rarr(arr):
    size = arr.__len__()
    if size == 0:
        return None
    elif size == 1:
        return arr[0]
    return arr[random.randrange(0, size-1)]

if __name__ == "__main__":
    if sys.argv.__len__() > 1:
        run(sys.argv[1])
    else:
        run(None)
