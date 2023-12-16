library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity tb_key_expansion is
end tb_key_expansion;

architecture BHV of tb_key_expansion is
component KEY_EXPANSION
PORT
(
  CLK 					:in std_logic;
  RESET 				:in std_logic;
  START_KEY_EXPANSION   :in std_logic;
	CONFIG 				:in std_logic_vector(1 downto 0);
	KEY						:in std_logic_vector(127 downto 0);
	STATUS 				:out std_logic:='0';
	KEYS_EXP			:out std_logic_vector(1279 downto 0) := (others => '0')
);
end component;
signal CLK 				: std_logic;
signal RESET 			: std_logic := '0';
signal START_KEY_EXPANSION: std_logic;
signal CONFIG 			: std_logic_vector(1 downto 0);
signal KEY				: std_logic_vector(127 downto 0);
signal STATUS 			: std_logic;
signal KEYS_EXP			: std_logic_vector(1279 downto 0);
-- Clock period definitions
constant clk_period : time := 10 ns;
begin
	-- Instantiate the Unit Under Test (UUT)
	uut: KEY_EXPANSION PORT MAP (
				CLK 	 =>	CLK,
				RESET 	 =>	RESET,
				START_KEY_EXPANSION => START_KEY_EXPANSION,
				CONFIG 	 =>	CONFIG,
				KEY		 =>	KEY,
				STATUS 	 =>	STATUS,
				KEYS_EXP =>	KEYS_EXP
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
	   wait for clk_period;
		 KEY <= x"2B7E151628AED2A6ABF7158809CF4F3C"; 
		 START_KEY_EXPANSION <= '1';
		 wait;
  end process;


end BHV;