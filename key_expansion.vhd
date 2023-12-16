-----------------------------------------------------------------------------
  -- Syed Fahimuddin Alavi
  -- Key expansion
  -- https://www.github.com/fahimalavi
  -----------------------------------------------------------------------------
  --
  -- unit name:  key_expansion.vhdl
  --
  -- description:
  --
  --   This unit implements the key expansion phase of the AES algorithm
  --
  -----------------------------------------------------------------------------
  -- Copyright (c) 2023 Syed Fahimuddin Alavi
  -----------------------------------------------------------------------------
  -- MIT License
  -----------------------------------------------------------------------------
  -- Permission is hereby granted, free of charge, to any person obtaining a copy
  -- of this software and associated documentation files (the "Software"), to deal
  -- in the Software without restriction, including without limitation the rights
  -- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  -- copies of the Software, and to permit persons to whom the Software is
  -- furnished to do so, subject to the following conditions:
  -- 
  -- The above copyright notice and this permission notice shall be included in all
  -- copies or substantial portions of the Software.
  -- 
  -- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  -- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  -- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  -- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  -- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  -- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
  -- SOFTWARE.
-----------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity KEY_EXPANSION is
PORT
(
  CLK 					:in std_logic;
  RESET 				:in std_logic;
  START_KEY_EXPANSION   :in std_logic;
	CONFIG 				:in std_logic_vector(1 downto 0);
	KEY					:in std_logic_vector(127 downto 0);
	STATUS 				:out std_logic:='0';
	KEYS_EXP			:out std_logic_vector(1279 downto 0) := (others => '0')
);
end KEY_EXPANSION;

architecture RTL of KEY_EXPANSION is

  -----------------------------------------------------------------------------
  -- Type definitions
  -----------------------------------------------------------------------------
  type ByteArray is array (0 to 255) of std_logic_vector(7 downto 0);
  type RconArray is array (0 to 9) of std_logic_vector(7 downto 0);

  -----------------------------------------------------------------------------
  -- Constants
  -----------------------------------------------------------------------------
	constant SBOX : ByteArray := (
    x"63", x"7c", x"77", x"7b", x"f2", x"6b", x"6f", x"c5", x"30", x"01", x"67", x"2b", x"fe", x"d7", x"ab", x"76", x"ca", x"82", x"c9", x"7d", x"fa", 
		x"59", x"47", x"f0", x"ad", x"d4", x"a2", x"af", x"9c", x"a4", x"72", x"c0", x"b7", x"fd", x"93", x"26", x"36", x"3f", x"f7", x"cc", x"34", x"a5", 
		x"e5", x"f1", x"71", x"d8", x"31", x"15", x"04", x"c7", x"23", x"c3", x"18", x"96", x"05", x"9a", x"07", x"12", x"80", x"e2", x"eb", x"27", x"b2", 
		x"75", x"09", x"83", x"2c", x"1a", x"1b", x"6e", x"5a", x"a0", x"52", x"3b", x"d6", x"b3", x"29", x"e3", x"2f", x"84", x"53", x"d1", x"00", x"ed", 
		x"20", x"fc", x"b1", x"5b", x"6a", x"cb", x"be", x"39", x"4a", x"4c", x"58", x"cf", x"d0", x"ef", x"aa", x"fb", x"43", x"4d", x"33", x"85", x"45", 
		x"f9", x"02", x"7f", x"50", x"3c", x"9f", x"a8", x"51", x"a3", x"40", x"8f", x"92", x"9d", x"38", x"f5", x"bc", x"b6", x"da", x"21", x"10", x"ff", 
		x"f3", x"d2", x"cd", x"0c", x"13", x"ec", x"5f", x"97", x"44", x"17", x"c4", x"a7", x"7e", x"3d", x"64", x"5d", x"19", x"73", x"60", x"81", x"4f", 
		x"dc", x"22", x"2a", x"90", x"88", x"46", x"ee", x"b8", x"14", x"de", x"5e", x"0b", x"db", x"e0", x"32", x"3a", x"0a", x"49", x"06", x"24", x"5c", 
		x"c2", x"d3", x"ac", x"62", x"91", x"95", x"e4", x"79", x"e7", x"c8", x"37", x"6d", x"8d", x"d5", x"4e", x"a9", x"6c", x"56", x"f4", x"ea", x"65", 
		x"7a", x"ae", x"08", x"ba", x"78", x"25", x"2e", x"1c", x"a6", x"b4", x"c6", x"e8", x"dd", x"74", x"1f", x"4b", x"bd", x"8b", x"8a", x"70", x"3e", 
		x"b5", x"66", x"48", x"03", x"f6", x"0e", x"61", x"35", x"57", x"b9", x"86", x"c1", x"1d", x"9e", x"e1", x"f8", x"98", x"11", x"69", x"d9", x"8e", 
		x"94", x"9b", x"1e", x"87", x"e9", x"ce", x"55", x"28", x"df", x"8c", x"a1", x"89", x"0d", x"bf", x"e6", x"42", x"68", x"41", x"99", x"2d", x"0f", 
		x"b0", x"54", x"bb", x"16");
	constant RCONS : RconArray := (x"01", x"02", x"04", x"08", x"10", x"20", x"40", x"80", x"1B", x"36");
	TYPE Tstate IS (STATE_INIT, STATE_ROTWORD, STATE_SUBWORD, STATE_RCON, STATE_NEXT_C1, STATE_NEXT_C2, STATE_NEXT_C3, STATE_NEXT_C4,  STATE_ROUND_COMPLETE, STATE_COMPLETE);
  SIGNAL FSM_STATE: Tstate := STATE_INIT;
  SIGNAL KEY_RESULT: std_logic:='0';
	SIGNAL 		current_round_key: std_logic_vector(127 downto 0) := x"00000000000000000000000000000000";
	SIGNAL 		last_column: std_logic_vector(31 downto 0) := x"00000000";
	SIGNAL      KEYS_EXP_INT: std_logic_vector(1279 downto 0) := (others => '0');
begin


PROCESS (CLK,RESET)
VARIABLE 	round: natural range 0 to 10 := 0;
BEGIN
  IF CLK'event and rising_edge(CLK) THEN
    IF RESET='0' THEN
        FSM_STATE <=STATE_INIT;
    else
        CASE FSM_STATE IS
            WHEN STATE_INIT =>
                KEYS_EXP <= KEYS_EXP_INT;
                KEYS_EXP_INT <= KEYS_EXP_INT;
                last_column <= last_column;
                STATUS <= KEY_RESULT;
                KEY_RESULT <= KEY_RESULT;
                round := round;
                if(START_KEY_EXPANSION='1' and KEY_RESULT='0') then
                    FSM_STATE <= STATE_ROTWORD;
                else
                    FSM_STATE <= STATE_INIT;
                end if;
                current_round_key <= KEY;
            WHEN STATE_ROTWORD =>
                KEYS_EXP <= KEYS_EXP_INT;
                KEYS_EXP_INT <= KEYS_EXP_INT;
                current_round_key <= current_round_key;
                STATUS <= KEY_RESULT;
                KEY_RESULT <= KEY_RESULT;
                round := round;
                last_column(31 downto 24) <= current_round_key(23 downto 16);
                last_column(23 downto 16) <= current_round_key(15 downto 8);
                last_column(15 downto 8) <= current_round_key(7 downto 0);
                last_column(7 downto 0) <= current_round_key(31 downto 24);
                FSM_STATE <= STATE_SUBWORD;
            WHEN STATE_SUBWORD =>
                KEYS_EXP <= KEYS_EXP_INT;
                KEYS_EXP_INT <= KEYS_EXP_INT;
                current_round_key <= current_round_key;
                STATUS <= KEY_RESULT;
                KEY_RESULT <= KEY_RESULT;
                round := round;
                last_column(31 downto 24) <= std_logic_vector(SBOX(to_integer(unsigned(last_column(31 downto 24)))));
                last_column(23 downto 16) <= std_logic_vector(SBOX(to_integer(unsigned(last_column(23 downto 16)))));
                last_column(15 downto 8) <= std_logic_vector(SBOX(to_integer(unsigned(last_column(15 downto 8)))));
                last_column(7 downto 0) <= std_logic_vector(SBOX(to_integer(unsigned(last_column(7 downto 0)))));
                FSM_STATE <= STATE_RCON;
            WHEN STATE_RCON =>
                KEYS_EXP <= KEYS_EXP_INT;
                KEYS_EXP_INT <= KEYS_EXP_INT;
                current_round_key <= current_round_key;
                STATUS <= KEY_RESULT;
                KEY_RESULT <= KEY_RESULT;
                last_column(31 downto 24) <= last_column(31 downto 24) xor std_logic_vector(RCONS(round));
                last_column(23 downto 0) <= last_column(23 downto 0);
                round := round + 1;
                FSM_STATE <= STATE_NEXT_C1;			
            WHEN STATE_NEXT_C1 =>
                KEYS_EXP <= KEYS_EXP_INT;
                KEYS_EXP_INT <= KEYS_EXP_INT;
                last_column <= last_column;
                STATUS <= KEY_RESULT;
                KEY_RESULT <= KEY_RESULT;
                round := round;
                current_round_key(127 downto 96) <= current_round_key(127 downto 96) xor last_column;
                FSM_STATE <= STATE_NEXT_C2;
            WHEN STATE_NEXT_C2 =>
                KEYS_EXP <= KEYS_EXP_INT;
                KEYS_EXP_INT <= KEYS_EXP_INT;
                last_column <= last_column;
                STATUS <= KEY_RESULT;
                KEY_RESULT <= KEY_RESULT;
                round := round;
                current_round_key(95 downto 64) <= current_round_key(95 downto 64) xor current_round_key(127 downto 96);
                FSM_STATE <= STATE_NEXT_C3;
            WHEN STATE_NEXT_C3 =>
                KEYS_EXP <= KEYS_EXP_INT;
                KEYS_EXP_INT <= KEYS_EXP_INT;
                last_column <= last_column;
                STATUS <= KEY_RESULT;
                KEY_RESULT <= KEY_RESULT;
                round := round;
                current_round_key(63 downto 32) <= current_round_key(63 downto 32) xor current_round_key(95 downto 64);			
                FSM_STATE <= STATE_NEXT_C4;
            WHEN STATE_NEXT_C4 =>
                KEYS_EXP <= KEYS_EXP_INT;
                KEYS_EXP_INT <= KEYS_EXP_INT;
                last_column <= last_column;
                STATUS <= KEY_RESULT;
                KEY_RESULT <= KEY_RESULT;
                round := round;
                current_round_key(31 downto 0) <= current_round_key(31 downto 0) xor current_round_key(63 downto 32);		
                FSM_STATE <= STATE_ROUND_COMPLETE;
            WHEN STATE_ROUND_COMPLETE =>
                current_round_key <= current_round_key;
                last_column <= last_column;
                round := round;	
                if(round = 1) then
                    KEYS_EXP_INT(1279 downto 128) <= KEYS_EXP_INT(1279 downto 128);
                    KEYS_EXP_INT(127 downto 0) <= current_round_key;
                elsif(round = 2) then
                    KEYS_EXP_INT(1279 downto 256) <= KEYS_EXP_INT(1279 downto 256);
                    KEYS_EXP_INT(255 downto 128) <= current_round_key;
                    KEYS_EXP_INT(127 downto 0) <= KEYS_EXP_INT(127 downto 0);
                elsif(round = 3) then
                    KEYS_EXP_INT(1279 downto 384) <= KEYS_EXP_INT(1279 downto 384);
                    KEYS_EXP_INT(383 downto 256) <= current_round_key;
                    KEYS_EXP_INT(255 downto 0) <= KEYS_EXP_INT(255 downto 0);
                elsif(round = 4) then
                    KEYS_EXP_INT(1279 downto 512) <= KEYS_EXP_INT(1279 downto 512);
                    KEYS_EXP_INT(511 downto 384) <= current_round_key;
                    KEYS_EXP_INT(383 downto 0) <= KEYS_EXP_INT(383 downto 0);
                elsif(round = 5) then
                    KEYS_EXP_INT(1279 downto 640) <= KEYS_EXP_INT(1279 downto 640);
                    KEYS_EXP_INT(639 downto 512) <= current_round_key;
                    KEYS_EXP_INT(511 downto 0) <= KEYS_EXP_INT(511 downto 0);
                elsif(round = 6) then
                    KEYS_EXP_INT(1279 downto 768) <= KEYS_EXP_INT(1279 downto 768);
                    KEYS_EXP_INT(767 downto 640) <= current_round_key;
                    KEYS_EXP_INT(639 downto 0) <= KEYS_EXP_INT(639 downto 0); 
                elsif(round = 7) then
                    KEYS_EXP_INT(1279 downto 896) <= KEYS_EXP_INT(1279 downto 896);
                    KEYS_EXP_INT(895 downto 768) <= current_round_key;
                    KEYS_EXP_INT(767 downto 0) <= KEYS_EXP_INT(767 downto 0);
                elsif(round = 8) then
                    KEYS_EXP_INT(1279 downto 1024) <= KEYS_EXP_INT(1279 downto 1024);
                    KEYS_EXP_INT(1023 downto 896) <= current_round_key;
                    KEYS_EXP_INT(895 downto 0) <= KEYS_EXP_INT(895 downto 0);
                elsif(round = 9) then
                    KEYS_EXP_INT(1279 downto 1152) <= KEYS_EXP_INT(1279 downto 1152);
                    KEYS_EXP_INT(1151 downto 1024) <= current_round_key;
                    KEYS_EXP_INT(1023 downto 0) <= KEYS_EXP_INT(1023 downto 0);
                elsif(round = 10) then
                    KEYS_EXP_INT(1279 downto 1152) <= current_round_key;
                    KEYS_EXP_INT(1151 downto 0) <= KEYS_EXP_INT(1151 downto 0);
                else
                    KEYS_EXP_INT <= (others => '1');
                end if;
                if(round = 10) then
                    KEY_RESULT <= '1';
                    STATUS <= KEY_RESULT;
                    KEYS_EXP <= KEYS_EXP_INT;
                    FSM_STATE <= STATE_COMPLETE;
                else
                    KEY_RESULT <= '0';
                    STATUS <= KEY_RESULT;
                    KEYS_EXP <= KEYS_EXP_INT;
                    FSM_STATE <= STATE_ROTWORD;
                end if;
            WHEN STATE_COMPLETE =>
                KEYS_EXP <= KEYS_EXP_INT;
                KEYS_EXP_INT <= KEYS_EXP_INT;
                current_round_key <= current_round_key;
                last_column <= last_column;
                round := round;
                FSM_STATE <= STATE_COMPLETE;
                STATUS <= KEY_RESULT;
                KEY_RESULT <= KEY_RESULT;
            WHEN OTHERS =>
                KEYS_EXP <= KEYS_EXP_INT;
                KEYS_EXP_INT <= KEYS_EXP_INT;
                current_round_key <= current_round_key;
                last_column <= last_column;
                STATUS <= KEY_RESULT;
                KEY_RESULT <= KEY_RESULT;
                round := round;
                FSM_STATE <= FSM_STATE;
        END CASE;
	END IF;
  END IF;
END PROCESS;
end RTL;



