import math

f = open('weaver_cos.mif', 'w')
g = open('weaver_sin.mif', 'w')

f.write("DEPTH = 1024;\nWIDTH = 9;\nADDRESS_RADIX = DEC;\nDATA_RADIX = DEC;\n\n")
g.write("DEPTH = 1024;\nWIDTH = 9;\nADDRESS_RADIX = DEC;\nDATA_RADIX = DEC;\n\n")
f.write("CONTENT\nBEGIN\n")
g.write("CONTENT\nBEGIN\n")

for A in range(0,1024):
    val = 511*math.cos((float(A)/1024)*2*math.pi)
    f.write("%s  : %d;\n" % (A,round(val)))
    val = 511*math.sin((float(A)/1024)*2*math.pi)
    g.write("%s  : %d;\n" % (A,round(val)))

f.write("END;") 
g.write("END;") 

