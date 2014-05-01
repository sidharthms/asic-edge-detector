#! /usr/bin/env python
import sys
import os
import Image
sys.path.append( "/home/ecegrid/a/mg82/BitVector-3.3.2" )
from BitVector import BitVector

def convertToString(im_filename,output_filename):
    im=Image.open(im_filename)
    pixels_map=im.load()

    # list stores all the image bits
    bit_list=[]

    # list stores pixel value in hex form including the all three bytes in each pixel
    pixel_list_hex=[]

    for h in range(im.size[1]):
        for w in range(im.size[0]):
            # a three elements tuple for each pixel
            pixel_tp=pixels_map[w,h]

            #create a temperary list stores all three values in each pixel in binary form as a string
            temp_list=[]

            for val in pixel_tp:
                # bit vector for each value in the tuple of each pixel
                bv=BitVector(intVal=val,size=8)

                temp_list.append(str(bv))

            temp_str="".join(temp_list)

            #bv for each pixel including all three bytes
            bv_pixel=BitVector(bitstring=temp_str)

            if len(bv_pixel)==24:
                pass
            else:
                raise ValueError('bit string len for each pixel is not 24')

            bv_pixel.pad_from_left(8)
            pixel_list_hex.append(bv_pixel.get_hex_string_from_bitvector())
            
    # bit vector for image width and height
    bv_width=BitVector(intVal=im.size[0],size=32)
    bv_height=BitVector(intVal=im.size[1],size=32)

    #string for image size in hex 
    width_hex=bv_width.get_hex_string_from_bitvector()
    height_hex=bv_height.get_hex_string_from_bitvector()

    fptr=open(output_filename,'w')
    fptr.write("<address>:<data value in hexidecimal>;\n")
    fptr.write('0:%s;\n' % width_hex)
    fptr.write('1:%s;\n' % height_hex)

    for i in range(len(pixel_list_hex)):
        fptr.write('%d:%s;\n' % (i+2, pixel_list_hex[i]))

    fptr.close()




def convertToImage(filename_input,filename_output):
    fptr=open(filename_input,'r')
    lines=fptr.readlines()

    del lines[0]

    #extract output image info 
    line1_str=lines[0].replace(":"," ")
    line1_str=line1_str.replace(";"," ")

    line2_str=lines[1].replace(":"," ")
    line2_str=line2_str.replace(";"," ")
    
    line1_lst=line1_str.split()
    line2_lst=line2_str.split()

    wid_hex=line1_lst[1]
    hei_hex=line2_lst[1]

    bv_temp1=BitVector(hexstring=wid_hex)
    bv_temp2=BitVector(hexstring=hei_hex)

    image_size=(int(bv_temp1),int(bv_temp2))

    #delete list except for the image data
    del lines[0:2]
    
    # create a list for image bytes in hex form 
    list_hex=[]
    for i in range(len(lines)):
        line_str=lines[i].replace(":"," ")

        line_str=line_str.replace(";"," ")
        line_lst=line_str.split()

        # get the hex value as a string of each pixel bytes
        hex_str=line_lst[1]
        list_hex.append(hex_str[2:len(hex_str)])
   
    if len(list_hex[0]) == 6:
        pass
    else:
        print "length of first pixel is:",len(list_hex[0])
        raise ValueError("wrong bit for the pixel,not equals to 6")

    # convert to hex string of image
    string_hex="".join(list_hex)

    # bv of bits of an image
    bv=BitVector(hexstring=string_hex)

    # list contains byte value of pixels of an image
    pxl_byte_list=[]

    # convert bits to bytes
    index=0
    while index<len(bv):
        pxl_byte_list.append(int(bv[index:index+8]))
        index=index+8
   
    # create a new image object with image_mode str and image_size tuple passed
    image_mode="RGB"
    im=Image.new(image_mode,image_size)
    im=im.convert(image_mode)
    pixels_map=im.load()

    # pixel mapping all the pixels with bytes from the bytelist
    ind=0
    for h in range(image_size[0]):
        for w in range(image_size[1]):
            pixels_map[w,h]=(pxl_byte_list[ind],pxl_byte_list[ind+1],pxl_byte_list[ind+2])
            ind=ind+3

    im.save(filename_output)
            
   

def convertToGrayImage(filename_input,filename_output):
    fptr=open(filename_input,'r')
    lines=fptr.readlines()

    del lines[0]

    #extract output image info 
    line1_str=lines[0].replace(":"," ")
    line1_str=line1_str.replace(";"," ")

    line2_str=lines[1].replace(":"," ")
    line2_str=line2_str.replace(";"," ")
    
    line1_lst=line1_str.split()
    line2_lst=line2_str.split()

    wid_hex=line1_lst[1][4:]
    hei_hex=line2_lst[1][4:]

    bv_temp1=BitVector(hexstring=wid_hex)
    bv_temp2=BitVector(hexstring=hei_hex)

    image_size=(int(bv_temp1),int(bv_temp2))

    #delete list except for the image data
    del lines[0:2]
    
    # create a list for image bytes in hex form 
    list_hex=[]
    for i in range(len(lines)):
        line_str=lines[i].replace(":"," ")

        line_str=line_str.replace(";"," ")
        line_lst=line_str.split()

        # get the hex value as a string of each pixel bytes
        hex_str=line_lst[1]
        list_hex.append(hex_str[4:])
   

    print "length of first pixel is:",len(list_hex[0])
    if len(list_hex[0]) == 2:
        pass
    else:
        raise ValueError("wrong bit for the pixel,not equals to 2")

    # convert to hex string of image
    string_hex="".join(list_hex)

    # bv of bits of an image
    bv=BitVector(hexstring=string_hex)

    # list contains byte value of pixels of an image
    pxl_byte_list=[]

    # convert bits to bytes
    index=0
    while index<len(bv):
        pxl_byte_list.append(int(bv[index:index+8]))
        index=index+8
   
    # create a new image object with image_mode str and image_size tuple passed
    image_mode='L'
    im=Image.new(image_mode,image_size)
    im=im.convert(image_mode)
    pixels_map=im.load()

    print "image size is:",image_size

    # pixel mapping all the pixels with bytes from the bytelist
    ind=0
    print "length of pixel byte list:",len(pxl_byte_list)
    for h in range(image_size[0]):
        for w in range(image_size[1]):
            pixels_map[w,h]=(pxl_byte_list[ind])
            ind=ind+1

    print im
    im.save(filename_output)
 
