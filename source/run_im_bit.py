#! /usr/bin/env python
import sys
import os
from image_str_converter import *

if __name__=="__main__":
    #convertToString('lena.bmp','output.mem')
    #convertToImage('output.mem','lena_recovered.bmp')
    convertToGrayImage('aoutputs.mem','lena_grayscale.bmp')

