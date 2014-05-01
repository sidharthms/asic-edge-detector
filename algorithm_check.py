# Check Averaging Algorithm
#
import sys
hex = int(sys.argv[1],0)
k = ((hex >> 16) & 0xFF) + ((hex >> 8) & 0xFF) + (hex & 0xFF)
f = (k >> 2) + (k >> 4) + (k >> 6) + (k >> 8)
print f
