#!/usr/bin/env python3
"""
============================================================
ITCH Parser - Software Implementation
============================================================
Author: Jean-Claude Junior Raymond

Python implementation of the ITCH 5.0 protocol parser,
matching the FPGA hardware implementation.

Supports 9 message types:
  0: Add Order ('A')
  1: Cancel Order ('X')
  2: Delete Order ('D')
  3: Executed Order ('E')
  4: Replace Order ('U')
  5: Trade ('P')
  6: Add Order MPID ('F')
  7: Executed with Price ('C')
  8: Broken Trade ('B')
============================================================
"""

from dataclasses import dataclass
from enum import IntEnum
from typing import Optional
import struct


class MessageType(IntEnum):
    ADD_ORDER = 0
    CANCEL_ORDER = 1
    DELETE_ORDER = 2
    EXECUTED_ORDER = 3
    REPLACE_ORDER = 4
    TRADE = 5
    ADD_ORDER_MPID = 6
    EXECUTED_PRICE = 7
    BROKEN_TRADE = 8


# Message type character to enum mapping
MSG_CHAR_TO_TYPE = {
    ord('A'): MessageType.ADD_ORDER,
    ord('X'): MessageType.CANCEL_ORDER,
    ord('D'): MessageType.DELETE_ORDER,
    ord('E'): MessageType.EXECUTED_ORDER,
    ord('U'): MessageType.REPLACE_ORDER,
    ord('P'): MessageType.TRADE,
    ord('F'): MessageType.ADD_ORDER_MPID,
    ord('C'): MessageType.EXECUTED_PRICE,
    ord('B'): MessageType.BROKEN_TRADE,
}

# Message lengths (including type byte) - matches FPGA implementation
MSG_LENGTHS = {
    MessageType.ADD_ORDER: 36,       # A
    MessageType.CANCEL_ORDER: 23,    # X
    MessageType.DELETE_ORDER: 9,     # D
    MessageType.EXECUTED_ORDER: 30,  # E
    MessageType.REPLACE_ORDER: 27,   # U
    MessageType.TRADE: 40,           # P
    MessageType.ADD_ORDER_MPID: 40,  # F
    MessageType.EXECUTED_PRICE: 36,  # C
    MessageType.BROKEN_TRADE: 19,    # B
}


@dataclass
class ParsedMessage:
    """Parsed ITCH message with canonical fields (matches FPGA output)"""
    valid: bool = False
    msg_type: int = 0
    order_ref: int = 0
    side: int = 0          # 0 = Buy, 1 = Sell
    shares: int = 0
    price: int = 0
    new_order_ref: int = 0
    timestamp: int = 0
    misc_data: int = 0     # stock symbol or match_id depending on message type
    
    def __repr__(self):
        if not self.valid:
            return "ParsedMessage(valid=False)"
        
        type_names = ['ADD', 'CANCEL', 'DELETE', 'EXEC', 'REPLACE', 
                      'TRADE', 'ADD_MPID', 'EXEC_PRICE', 'BROKEN']
        side_str = 'Sell' if self.side else 'Buy'
        
        return (f"ParsedMessage(\n"
                f"  type={type_names[self.msg_type]} ({self.msg_type}),\n"
                f"  order_ref=0x{self.order_ref:016X},\n"
                f"  side={side_str},\n"
                f"  shares={self.shares},\n"
                f"  price={self.price} (${self.price/10000:.4f}),\n"
                f"  new_order_ref=0x{self.new_order_ref:016X},\n"
                f"  timestamp={self.timestamp},\n"
                f"  misc_data=0x{self.misc_data:016X}\n"
                f")")


class ITCHParser:
    """
    Software ITCH parser matching the FPGA implementation.
    
    Usage:
        parser = ITCHParser()
        
        # Feed bytes one at a time (like FPGA)
        for byte in message_bytes:
            result = parser.feed_byte(byte)
            if result.valid:
                print(result)
        
        # Or parse a complete message at once
        result = parser.parse_message(message_bytes)
    """
    
    def __init__(self):
        self.reset()
    
    def reset(self):
        """Reset parser state"""
        self.byte_index = 0
        self.msg_type: Optional[MessageType] = None
        self.msg_length = 0
        self.buffer = bytearray()
        self._result = ParsedMessage()
    
    def feed_byte(self, byte: int) -> ParsedMessage:
        """
        Feed a single byte to the parser (matches FPGA behavior).
        Returns ParsedMessage with valid=True when message is complete.
        """
        # Byte 0: Message type detection
        if self.byte_index == 0:
            if byte in MSG_CHAR_TO_TYPE:
                self.msg_type = MSG_CHAR_TO_TYPE[byte]
                self.msg_length = MSG_LENGTHS[self.msg_type]
                self.buffer = bytearray([byte])
            else:
                # Unknown message type
                self.reset()
                return ParsedMessage(valid=False)
        else:
            self.buffer.append(byte)
        
        self.byte_index += 1
        
        # Check if message is complete
        if self.byte_index >= self.msg_length:
            result = self._decode_message()
            self.reset()
            return result
        
        return ParsedMessage(valid=False)
    
    def parse_message(self, data: bytes) -> ParsedMessage:
        """Parse a complete message at once"""
        self.reset()
        for byte in data:
            result = self.feed_byte(byte)
            if result.valid:
                return result
        return ParsedMessage(valid=False)
    
    def _decode_message(self) -> ParsedMessage:
        """Decode the buffered message into canonical fields"""
        msg = ParsedMessage(valid=True, msg_type=self.msg_type)
        buf = self.buffer
        
        if self.msg_type == MessageType.DELETE_ORDER:
            # 'D' (1) + Order Ref (8) = 9 bytes
            msg.order_ref = int.from_bytes(buf[1:9], 'big')
            
        elif self.msg_type == MessageType.ADD_ORDER:
            # 'A' (1) + Timestamp (6) + Order Ref (8) + Side (1) + 
            # Shares (4) + Stock (8) + Price (4) = 36 bytes
            msg.timestamp = int.from_bytes(buf[1:7], 'big')
            msg.order_ref = int.from_bytes(buf[7:15], 'big')
            msg.side = 1 if buf[15] == ord('S') else 0
            msg.shares = int.from_bytes(buf[16:20], 'big')
            msg.misc_data = int.from_bytes(buf[20:28], 'big')  # stock symbol
            msg.price = int.from_bytes(buf[28:32], 'big')
            
        elif self.msg_type == MessageType.CANCEL_ORDER:
            # 'X' (1) + Timestamp (6) + Order Ref (8) + Canceled Shares (4) = 23 bytes
            msg.timestamp = int.from_bytes(buf[1:7], 'big')
            msg.order_ref = int.from_bytes(buf[7:15], 'big')
            msg.shares = int.from_bytes(buf[15:19], 'big')
            
        elif self.msg_type == MessageType.EXECUTED_ORDER:
            # 'E' (1) + Timestamp (6) + Order Ref (8) + Executed Shares (4) + 
            # Match ID (8) = 30 bytes (actually needs padding check)
            msg.timestamp = int.from_bytes(buf[1:7], 'big')
            msg.order_ref = int.from_bytes(buf[7:15], 'big')
            msg.shares = int.from_bytes(buf[15:19], 'big')
            msg.misc_data = int.from_bytes(buf[19:27], 'big')  # match_id
            
        elif self.msg_type == MessageType.REPLACE_ORDER:
            # 'U' (1) + Timestamp (6) + Old Order Ref (8) + New Order Ref (8) +
            # Shares (4) + Price (4) = 27 bytes (needs check)
            msg.timestamp = int.from_bytes(buf[1:7], 'big')
            msg.order_ref = int.from_bytes(buf[7:15], 'big')  # old
            msg.new_order_ref = int.from_bytes(buf[15:23], 'big')  # new
            msg.shares = int.from_bytes(buf[23:27], 'big')
            # Note: some specs have price here too
            
        elif self.msg_type == MessageType.TRADE:
            # 'P' (1) + Timestamp (6) + Order Ref (8) + Side (1) + Shares (4) +
            # Stock (8) + Price (4) + Match ID (8) = 40 bytes
            msg.timestamp = int.from_bytes(buf[1:7], 'big')
            msg.order_ref = int.from_bytes(buf[7:15], 'big')
            msg.side = 1 if buf[15] == ord('S') else 0
            msg.shares = int.from_bytes(buf[16:20], 'big')
            # Stock is at 20:28, we put match_id in misc_data
            msg.price = int.from_bytes(buf[28:32], 'big')
            msg.misc_data = int.from_bytes(buf[32:40], 'big')  # match_id
            
        elif self.msg_type == MessageType.ADD_ORDER_MPID:
            # 'F' (1) + Timestamp (6) + Order Ref (8) + Side (1) + Shares (4) +
            # Stock (8) + Price (4) + Attribution (4) = 40 bytes
            msg.timestamp = int.from_bytes(buf[1:7], 'big')
            msg.order_ref = int.from_bytes(buf[7:15], 'big')
            msg.side = 1 if buf[15] == ord('S') else 0
            msg.shares = int.from_bytes(buf[16:20], 'big')
            msg.misc_data = int.from_bytes(buf[20:28], 'big')  # stock
            msg.price = int.from_bytes(buf[28:32], 'big')
            # Attribution at 32:36
            
        elif self.msg_type == MessageType.EXECUTED_PRICE:
            # 'C' (1) + Timestamp (6) + Order Ref (8) + Executed Shares (4) +
            # Match ID (8) + Printable (1) + Execution Price (4) = 36 bytes
            msg.timestamp = int.from_bytes(buf[1:7], 'big')
            msg.order_ref = int.from_bytes(buf[7:15], 'big')
            msg.shares = int.from_bytes(buf[15:19], 'big')
            msg.misc_data = int.from_bytes(buf[19:27], 'big')  # match_id
            # Printable at 27
            msg.price = int.from_bytes(buf[28:32], 'big')
            
        elif self.msg_type == MessageType.BROKEN_TRADE:
            # 'B' (1) + Timestamp (6) + Match ID (8) + ... = 19 bytes
            msg.timestamp = int.from_bytes(buf[1:7], 'big')
            msg.misc_data = int.from_bytes(buf[7:15], 'big')  # match_id
        
        return msg


# ============================================================
# Message Generators (for testing)
# ============================================================

def gen_delete_order(order_ref: int) -> bytes:
    """Generate DELETE order message"""
    return bytes([ord('D')]) + order_ref.to_bytes(8, 'big')


def gen_add_order(timestamp: int, order_ref: int, side: str, 
                  shares: int, stock: str, price: int) -> bytes:
    """Generate ADD order message (36 bytes)"""
    stock_bytes = stock.ljust(8)[:8].encode('ascii')
    side_byte = ord('S') if side == 'S' else ord('B')
    
    return (bytes([ord('A')]) +           # 1
            timestamp.to_bytes(6, 'big') + # 6
            order_ref.to_bytes(8, 'big') + # 8
            bytes([side_byte]) +           # 1
            shares.to_bytes(4, 'big') +    # 4
            stock_bytes +                  # 8
            price.to_bytes(4, 'big') +     # 4
            bytes(4))                      # 4 padding = 36 total


def gen_cancel_order(timestamp: int, order_ref: int, canceled_shares: int) -> bytes:
    """Generate CANCEL order message"""
    return (bytes([ord('X')]) +
            timestamp.to_bytes(6, 'big') +
            order_ref.to_bytes(8, 'big') +
            canceled_shares.to_bytes(4, 'big') +
            bytes(4))  # padding


def gen_executed_order(timestamp: int, order_ref: int, 
                       executed_shares: int, match_id: int) -> bytes:
    """Generate EXECUTED order message"""
    return (bytes([ord('E')]) +
            timestamp.to_bytes(6, 'big') +
            order_ref.to_bytes(8, 'big') +
            executed_shares.to_bytes(4, 'big') +
            match_id.to_bytes(8, 'big') +
            bytes(3))  # padding to 30


def gen_replace_order(timestamp: int, old_order_ref: int, 
                      new_order_ref: int, shares: int) -> bytes:
    """Generate REPLACE order message"""
    return (bytes([ord('U')]) +
            timestamp.to_bytes(6, 'big') +
            old_order_ref.to_bytes(8, 'big') +
            new_order_ref.to_bytes(8, 'big') +
            shares.to_bytes(4, 'big'))


def gen_trade(timestamp: int, order_ref: int, side: str, shares: int,
              stock: str, price: int, match_id: int) -> bytes:
    """Generate TRADE message"""
    stock_bytes = stock.ljust(8)[:8].encode('ascii')
    side_byte = ord('S') if side == 'S' else ord('B')
    
    return (bytes([ord('P')]) +
            timestamp.to_bytes(6, 'big') +
            order_ref.to_bytes(8, 'big') +
            bytes([side_byte]) +
            shares.to_bytes(4, 'big') +
            stock_bytes +
            price.to_bytes(4, 'big') +
            match_id.to_bytes(8, 'big'))


def gen_add_order_mpid(timestamp: int, order_ref: int, side: str,
                       shares: int, stock: str, price: int, mpid: str) -> bytes:
    """Generate ADD ORDER with MPID message (40 bytes)"""
    stock_bytes = stock.ljust(8)[:8].encode('ascii')
    mpid_bytes = mpid.ljust(4)[:4].encode('ascii')
    side_byte = ord('S') if side == 'S' else ord('B')
    
    # F(1) + timestamp(6) + order_ref(8) + side(1) + shares(4) + 
    # stock(8) + price(4) + mpid(4) + padding(4) = 40
    return (bytes([ord('F')]) +            # 1
            timestamp.to_bytes(6, 'big') + # 6
            order_ref.to_bytes(8, 'big') + # 8
            bytes([side_byte]) +           # 1
            shares.to_bytes(4, 'big') +    # 4
            stock_bytes +                  # 8
            price.to_bytes(4, 'big') +     # 4
            mpid_bytes +                   # 4
            bytes(4))                      # 4 padding = 40 total


def gen_executed_price(timestamp: int, order_ref: int, executed_shares: int,
                       match_id: int, printable: bool, exec_price: int) -> bytes:
    """Generate EXECUTED with PRICE message (36 bytes)"""
    # C(1) + timestamp(6) + order_ref(8) + shares(4) + match_id(8) + 
    # printable(1) + price(4) + padding(4) = 36
    return (bytes([ord('C')]) +                          # 1
            timestamp.to_bytes(6, 'big') +               # 6
            order_ref.to_bytes(8, 'big') +               # 8
            executed_shares.to_bytes(4, 'big') +         # 4
            match_id.to_bytes(8, 'big') +                # 8
            bytes([ord('Y') if printable else ord('N')]) + # 1
            exec_price.to_bytes(4, 'big') +              # 4
            bytes(4))                                    # 4 = 36 total


def gen_broken_trade(timestamp: int, match_id: int) -> bytes:
    """Generate BROKEN TRADE message"""
    return (bytes([ord('B')]) +
            timestamp.to_bytes(6, 'big') +
            match_id.to_bytes(8, 'big') +
            bytes(4))  # padding to 19


# ============================================================
# Test Suite
# ============================================================

def run_tests():
    """Run all tests matching the FPGA testbench"""
    parser = ITCHParser()
    tests_passed = 0
    tests_total = 0
    
    print("=" * 60)
    print("ITCH Parser Software Tests")
    print("=" * 60)
    
    # Test 1: DELETE ORDER
    tests_total += 1
    print("\n--- TEST 1: DELETE ORDER ---")
    msg = gen_delete_order(order_ref=0x0102030405060708)
    print(f"Message bytes: {msg.hex()}")
    result = parser.parse_message(msg)
    print(result)
    if result.valid and result.msg_type == MessageType.DELETE_ORDER:
        if result.order_ref == 0x0102030405060708:
            print("✓ PASS")
            tests_passed += 1
        else:
            print("✗ FAIL: order_ref mismatch")
    else:
        print("✗ FAIL")
    
    # Test 2: ADD ORDER
    tests_total += 1
    print("\n--- TEST 2: ADD ORDER ---")
    msg = gen_add_order(
        timestamp=0x000001020304,
        order_ref=0x1122334455667788,
        side='B',
        shares=1000,
        stock="APPL",
        price=100000  # $10.0000
    )
    print(f"Message bytes: {msg.hex()}")
    result = parser.parse_message(msg)
    print(result)
    if (result.valid and 
        result.msg_type == MessageType.ADD_ORDER and
        result.order_ref == 0x1122334455667788 and
        result.shares == 1000 and
        result.price == 100000):
        print("✓ PASS")
        tests_passed += 1
    else:
        print("✗ FAIL")
    
    # Test 3: CANCEL ORDER
    tests_total += 1
    print("\n--- TEST 3: CANCEL ORDER ---")
    msg = gen_cancel_order(
        timestamp=0x000000000001,
        order_ref=0xAABBCCDDEEFF0011,
        canceled_shares=500
    )
    print(f"Message bytes: {msg.hex()}")
    result = parser.parse_message(msg)
    print(result)
    if (result.valid and 
        result.msg_type == MessageType.CANCEL_ORDER and
        result.order_ref == 0xAABBCCDDEEFF0011 and
        result.shares == 500):
        print("✓ PASS")
        tests_passed += 1
    else:
        print("✗ FAIL")
    
    # Test 4: EXECUTED ORDER
    tests_total += 1
    print("\n--- TEST 4: EXECUTED ORDER ---")
    msg = gen_executed_order(
        timestamp=0x000000001234,
        order_ref=0x1111222233334444,
        executed_shares=250,
        match_id=0xDEADBEEFCAFE0000
    )
    print(f"Message bytes: {msg.hex()}")
    result = parser.parse_message(msg)
    print(result)
    if (result.valid and 
        result.msg_type == MessageType.EXECUTED_ORDER and
        result.shares == 250):
        print("✓ PASS")
        tests_passed += 1
    else:
        print("✗ FAIL")
    
    # Test 5: REPLACE ORDER
    tests_total += 1
    print("\n--- TEST 5: REPLACE ORDER ---")
    msg = gen_replace_order(
        timestamp=0x000000005678,
        old_order_ref=0x0000000000000001,
        new_order_ref=0x0000000000000002,
        shares=750
    )
    print(f"Message bytes: {msg.hex()}")
    result = parser.parse_message(msg)
    print(result)
    if (result.valid and 
        result.msg_type == MessageType.REPLACE_ORDER and
        result.order_ref == 0x0000000000000001 and
        result.new_order_ref == 0x0000000000000002):
        print("✓ PASS")
        tests_passed += 1
    else:
        print("✗ FAIL")
    
    # Test 6: TRADE
    tests_total += 1
    print("\n--- TEST 6: TRADE ---")
    msg = gen_trade(
        timestamp=0x000000009ABC,
        order_ref=0x5555666677778888,
        side='S',
        shares=100,
        stock="MSFT",
        price=350000,  # $35.0000
        match_id=0x1234567890ABCDEF
    )
    print(f"Message bytes: {msg.hex()}")
    result = parser.parse_message(msg)
    print(result)
    if (result.valid and 
        result.msg_type == MessageType.TRADE and
        result.side == 1):  # Sell
        print("✓ PASS")
        tests_passed += 1
    else:
        print("✗ FAIL")
    
    # Test 7: ADD ORDER MPID
    tests_total += 1
    print("\n--- TEST 7: ADD ORDER MPID ---")
    msg = gen_add_order_mpid(
        timestamp=0x00000000DEAD,
        order_ref=0xAAAABBBBCCCCDDDD,
        side='B',
        shares=2000,
        stock="GOOGL",
        price=150000,
        mpid="ABCD"
    )
    print(f"Message bytes: {msg.hex()}")
    result = parser.parse_message(msg)
    print(result)
    if (result.valid and 
        result.msg_type == MessageType.ADD_ORDER_MPID and
        result.shares == 2000):
        print("✓ PASS")
        tests_passed += 1
    else:
        print("✗ FAIL")
    
    # Test 8: EXECUTED WITH PRICE
    tests_total += 1
    print("\n--- TEST 8: EXECUTED WITH PRICE ---")
    msg = gen_executed_price(
        timestamp=0x00000000BEEF,
        order_ref=0x9999888877776666,
        executed_shares=50,
        match_id=0xFEDCBA0987654321,
        printable=True,
        exec_price=123456
    )
    print(f"Message bytes: {msg.hex()}")
    result = parser.parse_message(msg)
    print(result)
    if (result.valid and 
        result.msg_type == MessageType.EXECUTED_PRICE and
        result.price == 123456):
        print("✓ PASS")
        tests_passed += 1
    else:
        print("✗ FAIL")
    
    # Test 9: BROKEN TRADE
    tests_total += 1
    print("\n--- TEST 9: BROKEN TRADE ---")
    msg = gen_broken_trade(
        timestamp=0x00000000CAFE,
        match_id=0x0123456789ABCDEF
    )
    print(f"Message bytes: {msg.hex()}")
    result = parser.parse_message(msg)
    print(result)
    if (result.valid and 
        result.msg_type == MessageType.BROKEN_TRADE and
        result.misc_data == 0x0123456789ABCDEF):
        print("✓ PASS")
        tests_passed += 1
    else:
        print("✗ FAIL")
    
    # Summary
    print("\n" + "=" * 60)
    print(f"RESULTS: {tests_passed}/{tests_total} tests passed")
    print("=" * 60)
    
    return tests_passed == tests_total


if __name__ == "__main__":
    run_tests()
