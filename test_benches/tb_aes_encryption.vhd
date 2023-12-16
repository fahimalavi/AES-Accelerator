-----------------------------------------------------------------------------
  -- Syed Fahimuddin Alavi
  -- AES Encryption test bench
  -- https://www.github.com/fahimalavi
  -----------------------------------------------------------------------------
  --
  -- unit name: tb_aes_encryption.vhdl
  --
  -- description:
  --
  --   This unit tests the encryption of the AES algorithm
  --
  -----------------------------------------------------------------------------
  -- Copyright (c) 2023
  -----------------------------------------------------------------------------
  -- LICENSE NAME
  -----------------------------------------------------------------------------
  -- LICENSE NOTICE
  --
  --
  --
  --
-----------------------------------------------------------------------------
library IEEE;
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity TB_AES_ENCRYPTION is
end TB_AES_ENCRYPTION;

architecture BHV of TB_AES_ENCRYPTION is
component KEY_EXPANSION
PORT
(
  CLK 					:in std_logic;
  RESET 				:in std_logic;
  START_KEY_EXPANSION   :in std_logic;
	CONFIG 				:in std_logic_vector(1 downto 0);
	KEY					:in std_logic_vector(127 downto 0);
	STATUS 				:out std_logic:='0';
	KEYS_EXP			:out std_logic_vector(1279 downto 0)
);
end component;
COMPONENT AES_ENCRYPTION
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
end component;
signal CLK 				: std_logic;
signal RESET 			: std_logic := '1';
signal START_KEY_EXPANSION 				: std_logic := '0';
signal CONFIG 			: std_logic_vector(1 downto 0);
signal KEY				: std_logic_vector(127 downto 0);
signal STATUS 			: std_logic;
signal KEYS_EXP			: std_logic_vector(1279 downto 0);

signal ENCRYPT_ENABLE 			: std_logic;
signal PLAIN_TEXT						: std_logic_vector(127 downto 0);
signal CIPHER								: std_logic_vector(127 downto 0);
signal ENCRYPTION_STATUS		: std_logic;
-- Clock period definitions
constant clk_period : time := 10 ns;
begin
	-- Instantiate the Unit Under Test (UUT)
	UUT_PREREQ: KEY_EXPANSION PORT MAP (
				CLK 	 =>	CLK,
				RESET 	 =>	RESET,
				START_KEY_EXPANSION => START_KEY_EXPANSION,
				CONFIG 	 =>	CONFIG,
				KEY		 =>	KEY,
				STATUS 	 =>	STATUS,
				KEYS_EXP =>	KEYS_EXP
	);
	-- Instantiate the Unit Under Test (UUT)
	UUT: AES_ENCRYPTION
	PORT MAP(
		CLK 							,
		RESET 						,
		CONFIG 						,
		ENCRYPT_ENABLE		,
		STATUS						,
		KEY								,
		PLAIN_TEXT				,
		KEYS_EXP					,
		CIPHER						,
		ENCRYPTION_STATUS			
	);
	
  -- Clock process definitions
  clk_process :process
  begin
		CLK <= '0';
		wait for clk_period/2;
		CLK <= '1';
		wait for clk_period/2;
  end process;

   -- Stimulus process
  stim_proc: process
  begin		
	  wait for clk_period;
	  RESET <= '1';
		KEY <= x"2B7E151628AED2A6ABF7158809CF4F3C"; 
		START_KEY_EXPANSION <= '1';
	  wait until STATUS = '1';
		PLAIN_TEXT <= x"3243F6A8885A308D313198A2E0370734"; 
		ENCRYPT_ENABLE <= '1';
	  wait until ENCRYPTION_STATUS = '1';
	  wait for clk_period*30;
		ENCRYPT_ENABLE <= '0';
		wait;
  end process;


end BHV;