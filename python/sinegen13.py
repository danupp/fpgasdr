import math

f = open('cos_table_signed_13.mif', 'w')
g = open('sin_table_signed_13.mif', 'w')

f.write("DEPTH = 8192;\nWIDTH = 13;\nADDRESS_RADIX = DEC;\nDATA_RADIX = DEC;\n\n")
g.write("DEPTH = 8192;\nWIDTH = 13;\nADDRESS_RADIX = DEC;\nDATA_RADIX = DEC;\n\n")
f.write("CONTENT\nBEGIN\n")
g.write("CONTENT\nBEGIN\n")

for A in range(0,8192):
    val_c = 8191*math.cos((float(A)/8192)*2*math.pi)
    val_s = 8191*math.sin((float(A)/8192)*2*math.pi)
    f.write("%s  : %d;\n" % (A,round(val_c)))
    g.write("%s  : %d;\n" % (A,round(val_s)))

f.write("END;") 
g.write("END;") 

