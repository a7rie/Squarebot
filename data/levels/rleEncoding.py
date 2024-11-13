# compress binary data using RLE-encoding
def update_output(current_byte, current_length, output):
  if current_length != 0:
    output.append(current_length.to_bytes(1, 'little'))
    output.append(current_byte)
    

def run_length_encoding(binary_data):
  output = []
  prev_byte = None
  current_length = 0
  for current_byte in binary_data + [None]:
    if current_byte == None: 
      update_output(prev_byte,current_length, output)
      break
    if current_byte == prev_byte and current_length <= 255:
      current_length += 1
    else:
      update_output(prev_byte,current_length,output)
      current_length = 1
      prev_byte = current_byte
  
  return output
