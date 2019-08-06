# blueness_main
# 2016-04-19
#
# Author: Tom Zajdel
#
# Iterative scan-and-push for 96 well plate imaging
#   1. Intialize the linear actuator
#   2. Move 96-well plate into first position and scan
#   3. Move 96-well plate by 9mm to next row and repeat until all rows scanned

# Set up for 96-well plate, two columns at a time, so 4 scans are necessary
nCols = 4

# Import required libraries
import twain   # for scanner communication
import serial  # for Arduino communication
import time    # for timing operations

def onTwainEvent(event):
    if event == twain.MSG_XFERREADY:
        saveImage()
       
# Serial communication commands
READY = 'R'
INIT  = 'I'
BUSY  = 'B'

# Initialize the linear actuator
# Open connection with Arduino
ser = serial.Serial('COM3',9600)

# Wait for linearAct to be ready
while ser.read() != READY:
    print 'Waiting for linearAct to be ready... '
    time.sleep(1)
print 'linearAct is ready!'

# Tell linearAct to intialize and wait for success
ser.write(INIT)
while ser.read() != INIT:
    print 'Waiting for linearAct to intialize... '
    time.sleep(.1)
print 'linearAct has initialized!'

# Move plate to initial location and wait for confirm
while ser.read() != READY:
    print 'Moving plate to initial position...'
    time.sleep(.1)
print 'Plate has arrived at its initial position!'

# Acquire image, move plate, and iterate
for n in range(nCols):
    sm= twain.SourceManager(0)
    
    print 'Scanning column '+str(n+1)+'/'+str(nCols)+'...'
    # Open the source using the string with the name of the scanner.
    # If you want to see available scanner names, just call this:
    #   sm.GetSourceList()
    # ...and you will get a list of all scanners connected to the computer.
    #
    # For testing:
    # sd = sm.OpenSource('TWAIN2 FreeImage Software Scanner 2.1')
    sd = sm.OpenSource('WIA-HP Scanjet G4050')
    
    #set resolution to 600dpi
    x_res = sd.SetCapability(twain.ICAP_XRESOLUTION, twain.TWTY_FIX32,float(600))
    y_res = sd.SetCapability(twain.ICAP_YRESOLUTION, twain.TWTY_FIX32,float(600))
                             
    sd.RequestAcquire(0,0)
    (handle,count) = sd.XferImageNatively()
    twain.DIBToBMFile(handle,'image'+str(n+1)+'.jpg')
    
  
    # Deleting these and recreating sm and sd each iteration avoids excTWCC_SEQERROR
    del sm
    del sd

    if (n<nCols-1):
        ser.write(INIT)
    else:
        print 'Finished!'
    

