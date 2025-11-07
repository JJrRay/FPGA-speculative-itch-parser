# ============================================================
# payload_generator_helper.py
# ============================================================
#
# Description: Encodes binary payloads for ITCH message types.
#              Used to translate message fields into byte-aligned streams.
#              Supports all six decoder types: Add, Cancel, Delete, etc.
# Author: RZ
# Start Date: 05032025
# Version: 0.8

# Changelog
# =============================================
# [20250503-1] RZ: Initial Add/Cancel payloads (from payload_generators.py).
# [20250503-2] RZ: Added Delete/Replace and dummy payload generators.
# [20250503-1] RZ: Adopted into payload_generator_helper.py from payload_generators.py.
# [20250503-2] RZ: Added random_valid_payload() for randomized test cases.
# [20250504-1] RZ: updated cancel_order_payload to provide unused bytes for testing for real applications
# [20250504-2] RZ: updated delete_order_payload.
# [20250504-3] RZ: updated replace_order_payload.
# [20250504-4] RZ: updated executed_order_payload.
# [20250504-5] RZ: updated trade_payload.
# =============================================

import random
import string

def generate_add_order_payload(mode='set'):
    if mode == 'set':
        payload = [
            ord('A'),                              # Message Type
            *b'\x01\x23\x45\x67\x89\xAB\xCD\xEF',  # Order Ref  
            ord('S'),                              # Buy/Sell
            *b'\x00\x00\x00\x64',                  # Shares = 100
            *b'ABCD1234',                          # Symbol  
            *b'\x00\x00\x0F\xA0',                  # Price = 4000
        ] + [0] * 10                               # Zeroed Padding
    elif mode == 'rand':
        order_ref = random.getrandbits(64).to_bytes(8, 'big')
        buy_sell  = random.choice([ord('B'), ord('S')])
        shares    = random.randint(1, 1_000_000).to_bytes(4, 'big')
        symbol_length = random.randint(3, 6)
        symbol_core   = ''.join(random.choices("ABCDEFGHIJKLMNOPQRSTUVWXYZ", k=symbol_length))
        symbol_str    = symbol_core.ljust(8)
        symbol_bytes  = symbol_str.encode('ascii')
        price     = random.randint(1, 1_000_000).to_bytes(4, 'big')
        padding   = [0] * 10
        payload   = [ord('A')] + list(order_ref) + [buy_sell] + list(shares) + list(symbol_bytes) + list(price) + padding
    else:
        raise ValueError("Mode must be 'set' or 'rand'")

    return payload


def generate_cancel_order_payload(mode='set'):
    if mode == 'set':
        payload = [
            ord('X'),                              # Message Type
            *b'\xFE\xDC\xBA\x98\x76\x54\x32\x10',  # Order Ref (64-bit)
            *b'\x00\x00\x00\x32',                  # Canceled Shares = 50
        ] + [0] * 10                               # Padding
    elif mode == 'rand':
        order_ref = random.getrandbits(64).to_bytes(8, 'big')
        shares = random.randint(1, 1_000_000).to_bytes(4, 'big')
        padding = [random.randint(0, 255) for _ in range(10)]

        payload = [ord('X')] + list(order_ref) + list(shares) + [0] * 10
    else:
        raise ValueError("Mode must be 'set' or 'rand'")

    return payload

def generate_delete_order_payload(mode='set'):
    if mode == 'set':
        payload = [
            ord('D'),                              # Message Type
            *b'\x12\x34\x56\x78\x9A\xBC\xDE\xF0',  # Order Ref (64-bit)
        ] 
    elif mode == 'rand':
        order_ref = random.getrandbits(64).to_bytes(8, 'big')
        
        payload = [ord('D')] + list(order_ref) 
    else:
        raise ValueError("Mode must be 'set' or 'rand'")
    
    return payload

def generate_replace_order_payload(mode='set'):
    if mode == 'set':
        payload = [
            ord('U'),
            *b'\x11\x22\x33\x44\x55\x66\x77\x88',  # Original Ref
            *b'\x88\x77\x66\x55\x44\x33\x22\x11',  # New Ref
            *b'\x00\x00\x00\x64',                  # Updated Shares = 100
            *b'\x00\x00\x27\x10',                  # Updated Price = 10000
            0x00, 0x00                             # Reserved
        ]
    elif mode == 'rand':
        orig_ref = random.getrandbits(64).to_bytes(8, 'big')
        new_ref  = random.getrandbits(64).to_bytes(8, 'big')
        shares   = random.randint(1, 1_000_000).to_bytes(4, 'big')
        price    = random.randint(100, 500_000).to_bytes(4, 'big')
        reserved = [0, 0]
        payload  = [ord('U')] + list(orig_ref) + list(new_ref) + list(shares) + list(price) + reserved
    else:
        raise ValueError("Mode must be 'set' or 'rand'")

    return payload

def generate_executed_order_payload(mode='set'):
    if mode == 'set':
        payload = [
            ord('E'),
            *b'\x00\x00\x00\x00\x00\x01',                # Timestamp
            *b'\xAA\xBB\xCC\xDD\xEE\xFF\x00\x11',        # Order Ref
            *b'\x00\x00\x00\x0A',                        # Executed Shares = 10
            *b'\x12\x34\x56\x78\x9A\xBC\xDE\xF0',        # Match ID
        ] + [0] * 3  # Reserved
    elif mode == 'rand':
        timestamp = random.getrandbits(48).to_bytes(6, 'big')
        order_ref = random.getrandbits(64).to_bytes(8, 'big')
        shares = random.randint(1, 1_000_000).to_bytes(4, 'big')
        match_id = random.getrandbits(64).to_bytes(8, 'big')
        payload = [ord('E')] + list(timestamp) + list(order_ref) + list(shares) + list(match_id) + [0]*3
    else:
        raise ValueError("Mode must be 'set' or 'rand'")
    
    return payload

def generate_trade_payload(mode='set'):
    if mode == 'set':
        payload = [
            ord('P'),
            *b'\x00\x00\x00\x00\xAB\xCD',                    # Timestamp
            *b'\x11\x22\x33\x44\x55\x66\x77\x88',            # Order Ref
            ord('B'),                                        # Buy
            *b'\x00\x00\x00\x64',                            # Shares = 100
            *b'ABCD1234',                                    # 8-char symbol 
            *b'\x00\x00\x27\x10',                            # Price = 10000
            *b'\x99\x88\x77\x66\x55\x44\x33\x22',            # Match ID
        ]
    elif mode == 'rand':
        timestamp = random.getrandbits(48).to_bytes(6, 'big')
        order_ref = random.getrandbits(64).to_bytes(8, 'big')
        side      = random.choice([ord('B'), ord('S')])
        shares    = random.randint(1, 10_000).to_bytes(4, 'big')
        symbol_length = random.randint(3, 6)
        symbol_core = ''.join(random.choices("ABCDEFGHIJKLMNOPQRSTUVWXYZ", k=symbol_length))
        symnol_str = symbol_core.ljust(8)
        symbol_bytes = symnol_str.encode('ascii')       
        symbol  = list(symbol_bytes) 
        # symbol    = ''.join(random.choices("ABCDEFGHIJKLMNOPQRSTUVWXYZ", k=6)).ljust(8).encode('ascii')
        price     = random.randint(1_000, 1_000_000).to_bytes(4, 'big')   
        match_id  = random.getrandbits(64).to_bytes(8, 'big')

        payload = [ord('P')] + list(timestamp) + list(order_ref) + [side] + list(shares) + list(symbol) + list(price) + list(match_id)
    else:
        raise ValueError("Mode must be 'set' or 'rand'")
 
    return payload

