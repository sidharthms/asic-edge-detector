#! /usr/bin/env python
# -*- coding: utf-8 -*-
import sys
import os
from image_str_converter import *

if __name__=="__main__":
    convertToString('/home/ecegrid/a/mg81/asic-edge-detector/' + sys.argv[1] + '.bmp','/home/ecegrid/a/mg81/asic-edge-detector/' + sys.argv[1] + '.mem')
    #convertToImage('output.mem','lena_recovered.bmp')
    #convertToGrayImage('/home/ecegrid/a/mg81/asic-edge-detector/aoutputs.mem','/home/ecegrid/a/mg81/asic-edge-detector/result_gray_stage.bmp')

