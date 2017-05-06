import math
from numpy import binary_repr

f = open('atan_IQ_table.mif', 'w')

f.write("DEPTH = 16384;\nWIDTH = 8;\nADDRESS_RADIX = BIN;\nDATA_RADIX = DEC;\n\n")

f.write("CONTENT\nBEGIN\n")

for Q in range(-64,64):
    for I in range(-64,64):
        val = 127/(math.pi)*math.atan2(float(Q),float(I))
        f.write("%s%s : %d;\n" % (binary_repr(Q,7), binary_repr(I,7),round(val)))

f.write("END;") 

