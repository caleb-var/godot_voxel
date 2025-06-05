extends RefCounted

class_name Bitboard

var data: PackedByteArray
var bit_size : int = -1

# === CONSTRUCTOR ===
func _init(size_in_bits : int = 64):
	bit_size = size_in_bits
	data = PackedByteArray()
	data.resize(size_in_bits/8)  # 64-bit storage (8 bytes), all initialized to 0
	
func copy_bits(bitboard : Bitboard):
	data = bitboard.data.duplicate()
# === SET A BIT (1) ===
func set_bit(index: int):
	if index < 0 or index >= bit_size:
		return  # Out of bounds
	var byte_index = index / 8
	var bit_index = index % 8

	var byte_value = data[byte_index] & 0xFF  # Ensure unsigned handling
	byte_value |= (1 << bit_index)  # Set the bit
	data[byte_index] = byte_value & 0xFF  # Store back, ensuring unsigned range

# === CHECK IF A BIT IS SET (1) ===
func is_bit_set(index: int) -> bool:
	if index < 0 or index >= 64:
		return false
	var byte_index = index / 8
	var bit_index = index % 8

	var byte_value = data[byte_index] & 0xFF  # Ensure unsigned
	return (byte_value & (1 << bit_index)) != 0
func first_valid_bit(start_index: int = 0) -> int:
	if start_index < 0 or start_index >= bit_size:
		return -1  # Out of bounds

	var byte_index = start_index / 8
	var bit_index = start_index % 8

	# Search within the starting byte first
	var byte_value = data[byte_index] & 0xFF  # Ensure unsigned
	byte_value >>= bit_index  # Ignore lower bits before start_index
	if byte_value != 0:
		for i in range(8 - bit_index):
			if (byte_value & (1 << i)) != 0:
				return byte_index * 8 + (bit_index + i)

	# Search the remaining bytes  
	for b in range(byte_index + 1, bit_size/8):
		byte_value = data[b] & 0xFF  # Ensure unsigned  
		if byte_value != 0:
			for i in range(8):
				if (byte_value & (1 << i)) != 0:
					return b * 8 + i
	return -1  # No bits found
func _to_string()-> String:
	var binary_str = ""
	for i in range(bit_size):
		if is_bit_set(i):
			binary_str += str(1)
		else:
			binary_str += str(0)
	return binary_str
