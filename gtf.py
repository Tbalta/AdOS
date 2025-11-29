# (c) 2025, Tanguy Baltazart
# Calculation in this file are extracted from https://glenwing.github.io/docs/VESA-GTF-1.1.pdf
import math


MARGIN_P = 1.8
CELL_GRAN = 8

MIN_PORCH_RND = 1
V_SYNC_RQD = 3

H_SYNC_P = 8

MIN_VSYNC_BP = 550

# [V SYNC RQD] DEFAULT VALUE: 3 lines
# Assuming here that [V SYNC RQD] was a typo for [V_SYNC_RND]
V_SYNC_RND = 3


M = 600

C = 40

K = 128

J = 20

# Inputs
H_PIXELS = 640
V_LINES = 200

I_P_FREQ_RQD = 25


INTERLACE_REQUIRED = False

# 1. In order to give correct results, the number of horizontal pixels requested is first processed to ensure that it is divisible by the character size, by rounding it to the nearest character cell boundary:
H_PIXELS_RND = round (H_PIXELS / CELL_GRAN) * CELL_GRAN

# 2. If interlace is requested, the number of vertical lines assumed by the calculation must be halved, as the
# computation calculates the number of vertical lines per field. In either case, the number of lines is rounded to the
# nearest integer
V_LINES_RND = round (V_LINES / 2) if INTERLACE_REQUIRED else V_LINES

# 3. Find the pixel clock rate required:
PIXEL_FREQ=I_P_FREQ_RQD

# 4. Find number of lines in left margin:
LEFT_MARGIN = 0

# 5. Find number of lines in rigth margin:
RIGHT_MARGIN = 0

# 6. Find total number of active pixels in image and left and right margins:
TOTAL_ACTIVE_PIXELS =H_PIXELS_RND+ RIGHT_MARGIN+LEFT_MARGIN

# 7. Find the ideal horizontal period from the blanking duty cycle equation:
IDEAL_H_PERIOD= ( (C-100) + (math.sqrt(((100-C)**2) + (0.4*M* (TOTAL_ACTIVE_PIXELS + RIGHT_MARGIN + LEFT_MARGIN) / PIXEL_FREQ)))) / 2 / M * 1000

# 8. Find the ideal blanking duty cycle from the blanking duty cycle equation:
IDEAL_DUTY_CYCLE = C - (M * IDEAL_H_PERIOD / 1000)

# 9. Find the number of pixels in the blanking time to the nearest double character cell:
H_BLANK = (round ((TOTAL_ACTIVE_PIXELS* IDEAL_DUTY_CYCLE / (100 - IDEAL_DUTY_CYCLE) / ( 2 * CELL_GRAN)),0))*(2*CELL_GRAN)

# 10. Find total number of pixels:
TOTAL_PIXELS = TOTAL_ACTIVE_PIXELS + H_BLANK

# 11. Find horizontal frequency:
H_FREQ=PIXEL_FREQ/TOTAL_PIXELS*1000

# 12. Find horizontal period:
H_PERIOD = 1000 / H_FREQ

# 13. Find number of lines in Top margin:
TOP_MARGIN=0

# 14. Find number of lines in Bottom margin:
BOT_MARGIN=0

# 15. If interlace is required, then set variable INTERLACE = 0.5:
INTERLACE= 0.5 if INTERLACE_REQUIRED else 0

# 16. Find the number of lines in V sync + back porch:
V_SYNC_BP = round(MIN_VSYNC_BP * H_FREQ / 1000,0)

# 17. Find the number of lines in V back porch alone:
V_BACK_PORCH=V_SYNC_BP - V_SYNC_RND

# 18. Find the total number of lines in Vertical field period
TOTAL_V_LINES = V_LINES_RND + TOP_MARGIN + BOT_MARGIN + INTERLACE + V_SYNC_BP + MIN_PORCH_RND

# 19. Find the Vertical field frequency:
V_FIELD_RATE = H_FREQ / TOTAL_V_LINES*1000

# 20. Find the Vertical frame frequency:
V_FRAME_RATE= (V_FIELD_RATE / 2) if INTERLACE_REQUIRED else V_FIELD_RATE

# 7.6 Using Stage 1 Parameters to Derive Stage 2 Parameters 

# 1. Find the addressable lines per frame:
ADDR_LINES_PER_FRAME = (V_LINES_RND / 2) if INTERLACE_REQUIRED else V_LINES_RND

# 2. Find the character time (in ns):
CHAR_TIME=CELL_GRAN/PIXEL_FREQ*1000

# 3. Find the total number of lines in a frame:
TOTAL_LINES_PER_FRAME = TOTAL_V_LINES * (2 if INTERLACE_REQUIRED else 1)

# 4. Find the total number of characters in a horizontal line:
TOTAL_H_TIME= round(TOTAL_PIXELS / CELL_GRAN,0)

# 5. Find the horizontal addressable time (in us):
H_ADDR_TIME=H_PIXELS_RND / PIXEL_FREQ

# 6. Find the horizontal addressable time (in chars):
H_ADDR_TIME_CHARS = round(H_PIXELS_RND / CELL_GRAN,0)

# 7. Find the horizontal blanking time (in us):
H_BLANK_US = H_BLANK / PIXEL_FREQ

# 8. Find the horizontal blanking time (in chars):
H_BLANK_CHAR = round(H_BLANK /CELL_GRAN,0)

# 9. Find the horizontal blanking + margin time (in us):
H_BLANK_MARGIN_US = (H_BLANK + RIGHT_MARGIN + LEFT_MARGIN ) / PIXEL_FREQ

# 10. Find the horizontal blanking + margin time (in chars):
H_BLANK_MARGIN_CHAR = round ((H_BLANK + RIGHT_MARGIN + LEFT_MARGIN ) / CELL_GRAN, 0)

# 11. Find the actual horizontal active video duty cycle (in %):
ACTUAL_DUTY_CYCLE = H_BLANK_CHAR / TOTAL_H_TIME * 100

# 12. Find the image video duty cycle (in %):
BLANK_MARGIN_DUTY_CYCLE = H_BLANK_MARGIN_CHAR /TOTAL_H_TIME * 100

# 13. Find the left margin time (in us)
LEFT_MARGIN_US = LEFT_MARGIN / PIXEL_FREQ * 1000

# 14. Find the number of characters in the left margin (in chars):
LEFT_MARGIN_CHARS=LEFT_MARGIN / CELL_GRAN

# 15. Find the right margin time (in us)
RIGHT_MARGIN_US = RIGHT_MARGIN / PIXEL_FREQ * 1000

# 16. Find the number of characters in the right margin (in chars):
RIGHT_MARGIN_CHARS = RIGHT_MARGIN / CELL_GRAN

# 17. Find the number of pixels in the horizontal sync period:
H_SYNC_PIXEL = round((H_SYNC_P /100 * TOTAL_PIXELS / CELL_GRAN),0) * CELL_GRAN

# 18. Find the number of pixels in the horizontal front porch period:
H_FRONT_PORCH_PIXELS = (H_BLANK / 2) - H_SYNC_PIXEL

# 19. Find the number of pixels in the horizontal back porch period:
H_BACK_PORCH_PIXELS = H_FRONT_PORCH_PIXELS + H_SYNC_PIXEL

# 20. Find the number of characters in the horizontal sync period:
H_SYNC_CHARS = H_SYNC_PIXEL / CELL_GRAN

# 21. Find the horizontal sync period (in us):
H_SYNC = H_SYNC_PIXEL / PIXEL_FREQ

# 22. Find the number of characters in the horizontal front porch period:
H_FRONT_PORCH_CHARS = H_FRONT_PORCH_PIXELS / CELL_GRAN

# 23. Find the horizontal front porch period (in us):
H_FRONT_PORCH = H_FRONT_PORCH_PIXELS / PIXEL_FREQ

# 24. Find the number of characters in the horizontal back porch period:
H_BACK_PORCH_CHARS = H_BACK_PORCH_PIXELS / CELL_GRAN

# 25. Find the horizontal back porch period(in us):
H_BACK_PORCH = H_BACK_PORCH_PIXELS / PIXEL_FREQ

# 26. Find the vertical frame period (in ms):
V_FRAME_PERIOD = TOTAL_V_LINES * H_PERIOD / 1000

# 27. Find the vertical field period(in ms):
V_FIELD_PERIOD =TOTAL_V_LINES * H_PERIOD / 1000

# 28. Find the addressable vertical period per frame (in ms):
V_ADDR_TIME_PER_FRAME= V_LINES_RND*H_PERIOD/1000 * (2 if INTERLACE_REQUIRED else 1)

# 29. Find the addressable vertical period per field (in ms):
V_ADDR_TIME_PER_FIELD = V_LINES_RND*H_PERIOD/1000

# 30. Find the number of lines in the odd blanking period:
V_ODD_BLANKING_LINES= V_SYNC_BP + MIN_PORCH_RND

# 31. Find the odd blanking period (in ms):
V_ODD_BLANKING=(V_SYNC_BP+ MIN_PORCH_RND) * H_PERIOD/1000

# 32. Find the number of lines in the even blanking period:
V_EVEN_BLANKING_LINES= V_SYNC_BP + (2*INTERLACE)+MIN_PORCH_RND

# 33. Find the even blanking period (in ms):
V_EVEN_BLANKING =(V_SYNC_BP + (2*INTERLACE) + MIN_PORCH_RND)/1000*H_PERIOD

# 34. Find the top margin period (in us):
TOP_MARGIN_US = TOP_MARGIN*H_PERIOD

# 35. Find the odd front porch period (in us):
V_ODD_FRONT_PORCH=( MIN_PORCH_RND+INTERLACE)*H_PERIOD

# 36. Find the number of lines in the odd front porch period:
V_ODD_FRONT_PORCH_LINES=( MIN_PORCH_RND+INTERLACE)

# 37. Find the even front porch period (in us):
V_EVEN_FRONT_PORCH = MIN_PORCH_RND*H_PERIOD

# 38. Find the vertical sync period (in us):
V_SYNC=V_SYNC_RND*H_PERIOD

# 39. Find the even front porch period (in us):
V_EVEN_BACK_PORCH=(V_BACK_PORCH+INTERLACE)*H_PERIOD

# 40. Find the number of lines in the even front porch period:
V_EVEN_BACK_PORCH_LINES=(V_BACK_PORCH+INTERLACE)

# 41. Find the odd_back_porch period (in us):
V_ODD_BACK_PORCH=V_BACK_PORCH*H_PERIOD

# 42. Find the bottom margin period (in us):
BOT_MARGIN_US=BOT_MARGIN*H_PERIOD


TOTAL_H_TIME = round(TOTAL_PIXELS/CELL_GRAN,0)


print ("Vertical Total: ", TOTAL_V_LINES)
print ("Horizontal Total", TOTAL_H_TIME)

print ("")

# I decided Horizontal Blanking start after active display (no border)
print ("Horizontal Blanking start (chars): ", H_ADDR_TIME_CHARS)
print ("Horizontal Blanking duration: ", H_BLANK_CHAR)

# I decided Horizontal Retrace will start at H_ADDR_TIME_CHARS + H_FRONT_PORCH_CHARS
print ("Horizontal Sync Start (chars):", H_ADDR_TIME_CHARS + H_FRONT_PORCH_CHARS)
print ("Horizontal Sync Duration", H_SYNC_CHARS)

print ("")


# I decided Horizontal Blanking start after active display (no border)
print ("Vertical Blanking Start (lines)", V_LINES_RND )
print ("Vertical (even) Blanking Duration (lines)", V_EVEN_BLANKING_LINES )
print ("Vertical (odd) Blanking Duration (lines)", V_ODD_BLANKING_LINES )

# I decided Horizontal Retrace will start at V_LINES_RND + V_ODD_FRONT_PORCH_LINES
print ("Vertical Sync Start", V_LINES_RND + V_ODD_FRONT_PORCH_LINES)
print ("Vertical Sync Duration", V_SYNC_BP)