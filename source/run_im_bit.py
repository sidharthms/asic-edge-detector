#! /usr/bin/env python
import sys
import os
from image_str_converter import *
from random import random
if __name__=="__main__":
    #convertToString('lena.bmp','output.mem')
    #convertToImage('output.mem','lena_recovered.bmp')
    convertToGrayImage('/home/ecegrid/a/mg81/asic-edge-detector/aoutputs.mem','/home/ecegrid/a/mg81/asic-edge-detector/result_gray_' + str(random()*10000) + '.bmp')

