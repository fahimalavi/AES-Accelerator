-----------------------------------------------------------------------------
  -- Syed Fahimuddin Alavi
  -- AES Encryption
  -- https://www.github.com/fahimalavi
  -----------------------------------------------------------------------------
  --
  -- unit name: aes_encryption.vhdl
  --
  -- description:
  --
  --   This unit implements the encryption of the AES algorithm, it's pre-req is  
  --	 the key expansion present in the same directory.
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

ENTITY AES_ENCRYPTION is
PORT(
  CLK 							:in std_logic;
  RESET 						:in std_logic;
	CONFIG 						:in std_logic_vector(1 downto 0);
	ENCRYPT_ENABLE		:in std_logic;
	EXP_KEYS_PRESENT	:in std_logic;
	INITIAL_KEY				:in std_logic_vector(127 downto 0);
	PLAIN_TEXT				:in std_logic_vector(127 downto 0);
	KEYS_EXP					:in std_logic_vector(1279 downto 0);
	CIPHER						:out std_logic_vector(127 downto 0);
	ENCRYPTION_STATUS	:out std_logic
);
END AES_ENCRYPTION;

Architecture RTL of AES_ENCRYPTION is
  -----------------------------------------------------------------------------
  -- Type definitions
  -----------------------------------------------------------------------------
  type ByteArray is array (0 to 255) of std_logic_vector(7 downto 0);
	type RowArray is array (0 to 3) of std_logic_vector(7 downto 0);

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
	constant IRREDUCIBLE_POLY : std_logic_vector(7 downto 0) := x"1B"; -- X^4 + X^3 + X + 1
	constant ROUNDS_COUNT : natural := 10;

	TYPE 			Tstate IS (STATE_INIT, STATE_INIT_KEY, STATE_SBOX, STATE_MIXROWS, STATE_MIXCOLOUMN, STATE_ADD_ROUNDKEY, STATE_COMPLETE);
    SIGNAL 		FSM_STATE: Tstate := STATE_INIT;
	SIGNAL 		current_round_data: std_logic_vector(127 downto 0) := (others => '0');
begin

PROCESS (CLK, RESET)
VARIABLE 	round: natural range 0 to 10 := 0;
BEGIN
  IF CLK'event and rising_edge(CLK) THEN
    IF RESET='0' THEN
        FSM_STATE <=STATE_INIT;
    else
        CASE FSM_STATE IS
            WHEN STATE_INIT =>
                round := 0;
                CIPHER <= x"00000000000000000000000000000000";
                ENCRYPTION_STATUS <= '0';
                if(ENCRYPT_ENABLE='1' and EXP_KEYS_PRESENT='1') then
                    current_round_data <= INITIAL_KEY xor PLAIN_TEXT;
                    FSM_STATE <= STATE_SBOX;
                else 
                    current_round_data <=  (others => '1');
                    FSM_STATE <= STATE_INIT;
                end if;
            WHEN STATE_SBOX =>
                round := round + 1;
                CIPHER <= current_round_data;
                ENCRYPTION_STATUS <= '0';
                current_round_data(127 downto 120) 	<= std_logic_vector(SBOX(to_integer(unsigned(current_round_data(127 downto 120)))));
                current_round_data(119 downto 112) 	<= std_logic_vector(SBOX(to_integer(unsigned(current_round_data(119 downto 112)))));
                current_round_data(111 downto 104)	<= std_logic_vector(SBOX(to_integer(unsigned(current_round_data(111 downto 104)))));
                current_round_data(103 downto 96)	<= std_logic_vector(SBOX(to_integer(unsigned(current_round_data(103 downto 96)))));
                current_round_data(95 downto 88) 	<= std_logic_vector(SBOX(to_integer(unsigned(current_round_data(95 downto 88)))));
                current_round_data(87 downto 80) 	<= std_logic_vector(SBOX(to_integer(unsigned(current_round_data(87 downto 80)))));
                current_round_data(79 downto 72)	<= std_logic_vector(SBOX(to_integer(unsigned(current_round_data(79 downto 72)))));
                current_round_data(71 downto 64)	<= std_logic_vector(SBOX(to_integer(unsigned(current_round_data(71 downto 64)))));
                current_round_data(63 downto 56) 	<= std_logic_vector(SBOX(to_integer(unsigned(current_round_data(63 downto 56)))));
                current_round_data(55 downto 48) 	<= std_logic_vector(SBOX(to_integer(unsigned(current_round_data(55 downto 48)))));
                current_round_data(47 downto 40) 	<= std_logic_vector(SBOX(to_integer(unsigned(current_round_data(47 downto 40)))));
                current_round_data(39 downto 32)	<= std_logic_vector(SBOX(to_integer(unsigned(current_round_data(39 downto 32)))));
                current_round_data(31 downto 24) 	<= std_logic_vector(SBOX(to_integer(unsigned(current_round_data(31 downto 24)))));
                current_round_data(23 downto 16) 	<= std_logic_vector(SBOX(to_integer(unsigned(current_round_data(23 downto 16)))));
                current_round_data(15 downto 8)		<= std_logic_vector(SBOX(to_integer(unsigned(current_round_data(15 downto 8)))));
                current_round_data(7 downto 0)		<= std_logic_vector(SBOX(to_integer(unsigned(current_round_data(7 downto 0)))));
                FSM_STATE <= STATE_MIXROWS;
            WHEN STATE_MIXROWS =>
                CIPHER <= current_round_data;
                ENCRYPTION_STATUS <= '0';				
                -- ShiftRows() cyclically shifts the last three rows in the State. 
                -- R0
                -- R1
                current_round_data(119 downto 112) <= current_round_data(87 downto 80);
                current_round_data(87 downto 80) <= current_round_data(55 downto 48);
                current_round_data(55 downto 48) <= current_round_data(23 downto 16);
                current_round_data(23 downto 16) <= current_round_data(119 downto 112);
                -- R2
                current_round_data(111 downto 104) <= current_round_data(47 downto 40);
                current_round_data(79 downto 72) <= current_round_data(15 downto 8);
                current_round_data(47 downto 40) <= current_round_data(111 downto 104);
                current_round_data(15 downto 8) <= current_round_data(79 downto 72);
                -- R3
                current_round_data(103 downto 96) <= current_round_data(7 downto 0);
                current_round_data(71 downto 64) <= current_round_data(103 downto 96);
                current_round_data(39 downto 32) <= current_round_data(71 downto 64);
                current_round_data(7 downto 0) <= current_round_data(39 downto 32);
                if(round = 10) then
                    FSM_STATE <= STATE_ADD_ROUNDKEY;
                else
                    FSM_STATE <= STATE_MIXCOLOUMN;
                end if;
            WHEN STATE_MIXCOLOUMN =>
                CIPHER <= current_round_data;
                ENCRYPTION_STATUS <= '0';
                for i in 3 downto 0 loop
    --	constant MIX_C_MATRIX_R1 : RowArray := (x"02",x"03",x"01",x"01");
                    if(current_round_data((i*32)+31)='0')		then
                        if (current_round_data((i*32)+23) = '0') then
                            current_round_data((i*32)+31 downto (i*32)+24)	<= std_logic_vector(shift_left(unsigned(current_round_data((i*32)+31 downto (i*32)+24)),1)) xor 
                                                                                                            (std_logic_vector(shift_left(unsigned(current_round_data((i*32)+23 downto (i*32)+16)),1)) xor current_round_data((i*32)+23 downto (i*32)+16)) xor
                                                                                                            current_round_data((i*32)+15 downto (i*32)+8) xor current_round_data((i*32)+7 downto (i*32));
                        else
                            current_round_data((i*32)+31 downto (i*32)+24)	<= std_logic_vector(shift_left(unsigned(current_round_data((i*32)+31 downto (i*32)+24)),1)) xor 
                                                                                                            (std_logic_vector(shift_left(unsigned(current_round_data((i*32)+23 downto (i*32)+16)),1)) xor current_round_data((i*32)+23 downto (i*32)+16) xor IRREDUCIBLE_POLY) xor
                                                                                                            current_round_data((i*32)+15 downto (i*32)+8) xor current_round_data((i*32)+7 downto (i*32));
                        end if;
                    else	
                        if (current_round_data((i*32)+23) = '0') then
                            current_round_data((i*32)+31 downto (i*32)+24)	<= (std_logic_vector(shift_left(unsigned(current_round_data((i*32)+31 downto (i*32)+24)),1)) xor IRREDUCIBLE_POLY) xor 
                                                                                                            (std_logic_vector(shift_left(unsigned(current_round_data((i*32)+23 downto (i*32)+16)),1)) xor current_round_data((i*32)+23 downto (i*32)+16)) xor
                                                                                                            current_round_data((i*32)+15 downto (i*32)+8) xor current_round_data((i*32)+7 downto (i*32));
                        else
                            current_round_data((i*32)+31 downto (i*32)+24)	<= (std_logic_vector(shift_left(unsigned(current_round_data((i*32)+31 downto (i*32)+24)),1)) xor IRREDUCIBLE_POLY) xor 
                                                                                                            (std_logic_vector(shift_left(unsigned(current_round_data((i*32)+23 downto (i*32)+16)),1)) xor current_round_data((i*32)+23 downto (i*32)+16) xor IRREDUCIBLE_POLY) xor
                                                                                                            current_round_data((i*32)+15 downto (i*32)+8) xor current_round_data((i*32)+7 downto (i*32));
                        end if;
                    end if;
    
    --	constant MIX_C_MATRIX_R2 : RowArray := (x"01",x"02",x"03",x"01");
                    if(current_round_data((i*32)+23)='0')		then
                        if (current_round_data((i*32)+15) = '0') then
                            current_round_data((i*32)+23 downto (i*32)+16)	<= current_round_data((i*32)+31 downto (i*32)+24) xor 
                                                                                                            std_logic_vector(shift_left(unsigned(current_round_data((i*32)+23 downto (i*32)+16)),1)) xor
                                                                                                            (std_logic_vector(shift_left(unsigned(current_round_data((i*32)+15 downto (i*32)+8)),1)) xor current_round_data((i*32)+15 downto (i*32)+8)) xor 
                                                                                                            current_round_data((i*32)+7 downto (i*32));
                        else
                            current_round_data((i*32)+23 downto (i*32)+16)	<= current_round_data((i*32)+31 downto (i*32)+24) xor 
                                                                                                            std_logic_vector(shift_left(unsigned(current_round_data((i*32)+23 downto (i*32)+16)),1)) xor
                                                                                                            (std_logic_vector(shift_left(unsigned(current_round_data((i*32)+15 downto (i*32)+8)),1)) xor current_round_data((i*32)+15 downto (i*32)+8) xor IRREDUCIBLE_POLY) xor 
                                                                                                            current_round_data((i*32)+7 downto (i*32));
                            
                        end if;
                    else	
                        if (current_round_data((i*32)+15) = '0') then
                            current_round_data((i*32)+23 downto (i*32)+16)	<= current_round_data((i*32)+31 downto (i*32)+24) xor 
                                                                                                            (std_logic_vector(shift_left(unsigned(current_round_data((i*32)+23 downto (i*32)+16)),1)) xor IRREDUCIBLE_POLY) xor
                                                                                                            (std_logic_vector(shift_left(unsigned(current_round_data((i*32)+15 downto (i*32)+8)),1)) xor current_round_data((i*32)+15 downto (i*32)+8)) xor 
                                                                                                            current_round_data((i*32)+7 downto (i*32));
                        else
                            current_round_data((i*32)+23 downto (i*32)+16)	<= current_round_data((i*32)+31 downto (i*32)+24) xor 
                                                                                                            (std_logic_vector(shift_left(unsigned(current_round_data((i*32)+23 downto (i*32)+16)),1)) xor IRREDUCIBLE_POLY) xor
                                                                                                            (std_logic_vector(shift_left(unsigned(current_round_data((i*32)+15 downto (i*32)+8)),1)) xor current_round_data((i*32)+15 downto (i*32)+8) xor IRREDUCIBLE_POLY) xor 
                                                                                                            current_round_data((i*32)+7 downto (i*32));
                        end if;					
                    end if;
    
    --	constant MIX_C_MATRIX_R3 : RowArray := (x"01",x"01",x"02",x"03");
                    if(current_round_data((i*32)+15)='0')		then
                        if (current_round_data((i*32)+7) = '0') then
                            current_round_data((i*32)+15 downto (i*32)+8)	<= current_round_data((i*32)+31 downto (i*32)+24) xor current_round_data((i*32)+23 downto (i*32)+16) xor
                                                                                                            (std_logic_vector(shift_left(unsigned(current_round_data((i*32)+15 downto (i*32)+8)),1))) xor 
                                                                                                            (std_logic_vector(shift_left(unsigned(current_round_data((i*32)+7 downto (i*32))),1)) xor current_round_data((i*32)+7 downto (i*32)));
                        else
                            current_round_data((i*32)+15 downto (i*32)+8)	<= current_round_data((i*32)+31 downto (i*32)+24) xor current_round_data((i*32)+23 downto (i*32)+16) xor
                                                                                                            (std_logic_vector(shift_left(unsigned(current_round_data((i*32)+15 downto (i*32)+8)),1))) xor 
                                                                                                            (std_logic_vector(shift_left(unsigned(current_round_data((i*32)+7 downto (i*32))),1)) xor current_round_data((i*32)+7 downto (i*32)) xor IRREDUCIBLE_POLY);
                        end if;
                    else	
                        if (current_round_data((i*32)+7) = '0') then
                            current_round_data((i*32)+15 downto (i*32)+8)	<= current_round_data((i*32)+31 downto (i*32)+24) xor current_round_data((i*32)+23 downto (i*32)+16) xor
                                                                                                            (std_logic_vector(shift_left(unsigned(current_round_data((i*32)+15 downto (i*32)+8)),1)) xor IRREDUCIBLE_POLY) xor 
                                                                                                            (std_logic_vector(shift_left(unsigned(current_round_data((i*32)+7 downto (i*32))),1)) xor current_round_data((i*32)+7 downto (i*32)));
                        else
                            current_round_data((i*32)+15 downto (i*32)+8)	<= current_round_data((i*32)+31 downto (i*32)+24) xor current_round_data((i*32)+23 downto (i*32)+16) xor
                                                                                                            (std_logic_vector(shift_left(unsigned(current_round_data((i*32)+15 downto (i*32)+8)),1)) xor IRREDUCIBLE_POLY) xor 
                                                                                                            (std_logic_vector(shift_left(unsigned(current_round_data((i*32)+7 downto (i*32))),1)) xor current_round_data((i*32)+7 downto (i*32)) xor IRREDUCIBLE_POLY);
                        end if;
                    end if;
    
    --	constant MIX_C_MATRIX_R4 : RowArray := (x"03",x"01",x"01",x"02");
                    if(current_round_data((i*32)+7)='0')		then
                        if (current_round_data((i*32)+31) = '0') then
                            current_round_data((i*32)+7 downto (i*32))	<= (std_logic_vector(shift_left(unsigned(current_round_data((i*32)+31 downto (i*32)+24)),1)) xor current_round_data((i*32)+31 downto (i*32)+24)) xor 
                                                                                                            current_round_data((i*32)+15 downto (i*32)+8) xor
                                                                                                            current_round_data((i*32)+23 downto (i*32)+16) xor 
                                                                                                            (std_logic_vector(shift_left(unsigned(current_round_data((i*32)+7 downto (i*32))),1)));
                        else
                            current_round_data((i*32)+7 downto (i*32))	<= (std_logic_vector(shift_left(unsigned(current_round_data((i*32)+31 downto (i*32)+24)),1)) xor current_round_data((i*32)+31 downto (i*32)+24) xor IRREDUCIBLE_POLY) xor 
                                                                                                            current_round_data((i*32)+15 downto (i*32)+8) xor
                                                                                                            current_round_data((i*32)+23 downto (i*32)+16) xor 
                                                                                                            (std_logic_vector(shift_left(unsigned(current_round_data((i*32)+7 downto (i*32))),1)));
                        end if;
                    else	
                        if (current_round_data((i*32)+31) = '0') then
                            current_round_data((i*32)+7 downto (i*32))	<= (std_logic_vector(shift_left(unsigned(current_round_data((i*32)+31 downto (i*32)+24)),1)) xor current_round_data((i*32)+31 downto (i*32)+24)) xor 
                                                                                                            current_round_data((i*32)+15 downto (i*32)+8) xor
                                                                                                            current_round_data((i*32)+23 downto (i*32)+16) xor 
                                                                                                            (std_logic_vector(shift_left(unsigned(current_round_data((i*32)+7 downto (i*32))),1)) xor IRREDUCIBLE_POLY);
                        else
                            current_round_data((i*32)+7 downto (i*32))	<= (std_logic_vector(shift_left(unsigned(current_round_data((i*32)+31 downto (i*32)+24)),1)) xor current_round_data((i*32)+31 downto (i*32)+24) xor IRREDUCIBLE_POLY) xor 
                                                                                                            current_round_data((i*32)+15 downto (i*32)+8) xor
                                                                                                            current_round_data((i*32)+23 downto (i*32)+16) xor 
                                                                                                            (std_logic_vector(shift_left(unsigned(current_round_data((i*32)+7 downto (i*32))),1)) xor IRREDUCIBLE_POLY);
                        end if;
                    end if;
                end loop;  -- i
                FSM_STATE <= STATE_ADD_ROUNDKEY;
            WHEN STATE_ADD_ROUNDKEY =>	
                CIPHER <= current_round_data;
                ENCRYPTION_STATUS <= '0';
                current_round_data <= current_round_data xor KEYS_EXP((128*round)-1 downto (128*(round-1)));
                if(round = ROUNDS_COUNT) then
                    FSM_STATE <= STATE_COMPLETE;
                else
                    FSM_STATE <= STATE_SBOX;
                end if;
        WHEN STATE_COMPLETE =>
                CIPHER <= current_round_data;
                ENCRYPTION_STATUS <= '1';
                FSM_STATE <= STATE_COMPLETE;
                if(ENCRYPT_ENABLE='0') then
                    FSM_STATE <= STATE_INIT;
                end if;
            WHEN OTHERS =>
                CIPHER <= current_round_data;
                ENCRYPTION_STATUS <= '0';
                FSM_STATE <= STATE_INIT;
        END CASE;
    END IF;
  END IF;
END PROCESS;
end RTL;



