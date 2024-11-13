# convert raw level data into a format understandable by squarebot

import sys
import os

from rleEncoding import run_length_encoding

DEBUG = os.environ.get('SQUAREBOT_DEBUG')!= None

# mapping each ascii char in level data to the corresponding 4 bits in the squarebot level format
ascii_to_byte = {
    '.': 0b00000000, # blank space
    '0': 0b00000001, # starting position
    'W': 0b00000010, # wall
    'T': 0b00000011, # breakable wall
    'L': 0b00000100, # locked wall
    '#': 0b00000101, # ladder
    'E': 0b00000110, # exit (go to next level)
    '_': 0b00000111, # jump-through platform
    'K': 0b00001000, # key powerup
    'S': 0b00001001, # spike powerup
    'B': 0b00001010, # booster powerup
}


def main():
  args = sys.argv[1:]
  if len(args) != 2:
    print("Arguments: <ascii level file path> <output binary path>")
    exit(0)
  
  if (DEBUG): print("debugging mode is turned on")
  
  # read the data from the file as a 1d array of ascii chars
  data_file_path = args[0]
  output_file_path = args[1]
  
  if (DEBUG): print(f"Reading data file {data_file_path}, outputting generated level data to {output_file_path}")
  
  ascii_level = []
  with open(data_file_path) as f:
    while True:
      line = f.readline()
      if line == "":
        break
      split_line = list(line)
      
      if split_line[-1] == "\n": # for stylistic reasons, we want the nl in ascii data, but not in the binary output
        split_line.pop()
        
      if len(split_line) != 22: # levels are 22x23
        f.close()
        print(f"Line doesn't contain 22 characters: {split_line}")
        exit(0)
        
      ascii_level += split_line
  
  if len(ascii_level) != 506:
    print(f"ascii file contains {len(ascii_level)} characters instead of expected 506")
    exit(0)
    
  if (DEBUG):
    print("Level data to be converted:")
    for i in range(0, 507, 22):
      print("".join(ascii_level[i:i+22]))
  
#  now, convert to the squarebot level format
  converted_level_data = []
  for i in range(0, 506, 2):
    char1, char2 = ascii_level[i], ascii_level[i+1]
    if char1 not in ascii_to_byte or char2 not in ascii_to_byte:
      print(f"Level data has invalid character(s): {char1, char2}")
      exit(0)
      
    low_bits = ascii_to_byte[char1]
    high_bits = ascii_to_byte[char2]
    high_bits = high_bits << 4
    level_byte = (low_bits | high_bits) # byte represents 2 on screen chars of screen data
    if (DEBUG) and (char1 != "." or char2 != "."): 
      print((f"from ascii characters {char1}, {char2} / (0b{format(low_bits, '08b')}, "   
              f"0b{format(high_bits, '08b')}), produced level data byte: {level_byte} / 0b{format(level_byte, '08b')}"
              f"/ 0x{format(level_byte, '02x')}"
              ))
    converted_level_data.append(level_byte)
  
  if len(converted_level_data) != 253:
    print(f"Error: Level data is {len(converted_level_data)} instead of expected 253.")
    exit(0)    
    
  binary_level_data = [v.to_bytes(1, 'big') for v in converted_level_data]
  compressed_level_data = run_length_encoding(binary_level_data)
  if (DEBUG):
    uncompressed_hex = [byte.hex() for byte in binary_level_data]
    compressed_hex = [byte.hex() for byte in compressed_level_data]
    print(f"Uncompressed binary level data (hex):\n{uncompressed_hex}\nCompressed binary level data (hex):\n{compressed_hex}")
  
  print(f"Compressed level data is {len(compressed_level_data)} bytes.")
  
  data_to_write = b''.join(compressed_level_data)
  with open(output_file_path, 'wb') as output_file:
    output_file.write(data_to_write)
    
if __name__ == "__main__":
  main()