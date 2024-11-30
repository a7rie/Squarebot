# test decompressing RLE encoded output

# no functional purpose beyond testing

import sys
  
byte_to_ascii = {
    0: '.', # blank space
    16: '0', # starting position
    32: 'W', # wall
    48: 'T', # breakable wall
    64: 'L', # locked wall
    80: '#', # Gravity Powerup
    96: 'E', # exit (go to next level)
    112: '_', # jump-through platform
    144: 'S', # spike 
    128: 'K', # key powerup
    160: 'B', # booster powerup
}

def main():
  args = sys.argv[1:]
  if len(args) != 1:
    print("Arguments: <binary file path>")
    exit(0)
  
  data_file_path = args[0]
  data_file = open(data_file_path, 'rb')
  output = []

  while True: 
    length_byte = data_file.read(1)
    current_byte = data_file.read(1)
    if current_byte == b'' or length_byte == b'':
      break
    
    length = int.from_bytes(length_byte, 'little')
    current = int.from_bytes(current_byte, 'little')
    print(f"length byte: {length_byte} / {length}, current byte: {current_byte} / {current}")
    first_char = (current << 4) & 0b11110000
    second_char = (current) & 0b11110000 # NOTE
    for i in range(length):
      output.append(byte_to_ascii[first_char])
      output.append(byte_to_ascii[second_char])

  
  print(f"uncompressed level has {len(output)} bytes")
  
  for i in range(0, len(output), 22):  print(" ".join(output[i:i+22]))

if __name__ == "__main__":
  main()