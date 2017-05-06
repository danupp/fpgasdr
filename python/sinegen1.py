import math

f = open('cos_table_signed.mif', 'w')
g = open('sin_table_signed.mif', 'w')
h = open('cos_table_unsigned.mif', 'w')

f.write("DEPTH = 2048;\nWIDTH = 14;\nADDRESS_RADIX = DEC;\nDATA_RADIX = DEC;\n\n")
g.write("DEPTH = 2048;\nWIDTH = 14;\nADDRESS_RADIX = DEC;\nDATA_RADIX = DEC;\n\n")
h.write("DEPTH = 2048;\nWIDTH = 14;\nADDRESS_RADIX = DEC;\nDATA_RADIX = UNS;\n\n")
f.write("CONTENT\nBEGIN\n")
g.write("CONTENT\nBEGIN\n")
h.write("CONTENT\nBEGIN\n")

for A in range(0,2048):
    val = 8191*math.cos((float(A)/2048)*2*math.pi)
    f.write("%s  : %d;\n" % (A,round(val)))
    val = 8191*math.sin((float(A)/2048)*2*math.pi)
    g.write("%s  : %d;\n" % (A,round(val)))
    val = 16383*((math.cos((float(A)/2048)*2*math.pi)+1)/2)
    h.write("%s  : %d;\n" % (A,round(val)))

f.write("END;") 
g.write("END;") 
h.write("END;") 

