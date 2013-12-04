-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
--                                                                           --
-- File Name: user_logic_tb_test1.vhd                                        --
-- Author: Nathan Miller (nathanm2@iastate.edu  )                            --
-- Date: 11/23/2013                                                          --
--                                                                           --
-- Description: Testbench for user_logic_tb_test1                            --
--                                                                           --
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library proc_common_v3_00_a;
use proc_common_v3_00_a.ipif_pkg.all;

entity test3_double_dog is
  generic
  (
    C_NUM_REG                      : integer              := 32;
    C_SLV_DWIDTH                   : integer              := 32
  );
  port
  (
    clk							   : in  std_logic;
    Bus2IP_Resetn                  : in  std_logic;
    Bus2IP_Data                    : out std_logic_vector(C_SLV_DWIDTH-1 downto 0);
    Bus2IP_BE                      : out std_logic_vector(C_SLV_DWIDTH/8-1 downto 0);
    Bus2IP_RdCE                    : out std_logic_vector(C_NUM_REG-1 downto 0);
    Bus2IP_WrCE                    : out std_logic_vector(C_NUM_REG-1 downto 0);
    IP2Bus_Data                    : in  std_logic_vector(C_SLV_DWIDTH-1 downto 0);
    IP2Bus_RdAck                   : in  std_logic;
    IP2Bus_WrAck                   : in  std_logic;
    IP2Bus_Error                   : in  std_logic;
    finished					   : out std_logic
  );
end test3_double_dog;

architecture test3_i of test3_double_dog is

----------------------------------------------
--       Signal Declarations                --
----------------------------------------------
	type test_states is (wait_for_ready, write_data, write_data_done,
						 begin_hash, wait_hash,
						 wait_clear, validate, done);
	signal current_state : test_states;

	type sha1_in is array (0 to 15) of std_logic_vector(31 downto 0);
	type sha1_out is array (0 to 4) of std_logic_vector(31 downto 0);

	constant CMD_REG    : std_logic_vector    := x"80000000";
	constant STATUS_REG : std_logic_vector := x"40000000";
	constant INPUT_RDY  : integer := 0;
	constant HASH_RDY   : integer := 1;

-- "The quick brown fox jumps over the lazy dog":
--  Note1: The 0x80 must be appended to the end of text.
--  Note2: The length of the message IN BITS (not including the 0x80) is
--  located in the last 64-bits of the message.

	signal test3_msg : sha1_in := (
	x"54686520", x"71756963", x"6b206272", x"6f776e20",
	x"666f7820", x"6a756d70", x"73206f76", x"65722074",
	x"6865206c", x"617a7920", x"646f6780", x"00000000",
	x"00000000", x"00000000", x"00000000", x"00000158"
);

signal test3_hash : sha1_out := (
x"2fd4e1c6", x"7a2d28fc", x"ed849ee1", x"bb76e739", x"1b93eb12"
);

signal msg_count : integer range 0 to 2;
signal idx : integer range 0 to 16;

signal wrce : std_logic_vector(C_NUM_REG-1 downto 0);
signal rdce : std_logic_vector(C_NUM_REG-1 downto 0);

begin


-- Processes

test3 : process(clk)
begin
	if(clk = '1' and clk'event) then
		Bus2IP_WrCE <= (others => '0');
		Bus2IP_RdCE <= (others => '0');
		Bus2IP_Data <= (others => '0');
		Bus2IP_BE <= (others => '0');

		if(Bus2IP_Resetn = '0') then
			current_state <= wait_for_ready;
			idx <= 0;
			wrce <= x"00400000";
			rdce <= x"08000000";
			msg_count <= 0;

		else
			-- Wait until the pcore is ready:
			if( current_state = wait_for_ready ) then
				Bus2IP_RdCE <= STATUS_REG;
				idx <= 0;
				wrce <= x"00400000";
				rdce <= x"08000000";
				if( IP2Bus_RdAck = '1' and IP2Bus_Data(INPUT_RDY) = '1') then
					current_state <= write_data;
				end if;
			elsif( current_state = write_data ) then
				Bus2IP_RdCE <= (others => '0');
				Bus2IP_WrCE <= wrce;
				Bus2IP_Data <= test3_msg(idx);
				Bus2IP_BE   <= (others => '1');
				if( IP2Bus_WrAck = '1' ) then
					current_state <= write_data_done;
				end if;
			elsif( current_state = write_data_done ) then
				Bus2IP_WrCE <= (others => '0');
				Bus2IP_Data <= (others => '0');
				Bus2IP_BE   <= (others => '0');
				if( IP2Bus_WrAck = '0' ) then
					if( idx < 15 ) then
						idx <= idx + 1;
						wrce <= '0' & wrce(wrce'length-1 downto 1);
						current_state <= write_data;
					else
						current_state <= begin_hash;
					end if;
				end if;
			elsif( current_state = begin_hash ) then
				Bus2IP_WrCE <= CMD_REG;
				Bus2IP_Data <= x"00000001";
				Bus2IP_BE	<= (others => '1');
				if( IP2Bus_WrAck = '1' ) then
					current_state <= wait_hash;
				end if;
			elsif( current_state = wait_hash ) then
				Bus2IP_WrCE <= (others => '0');
				Bus2IP_RdCE <= STATUS_REG;
				Bus2IP_Data <= (others => '0');
				Bus2IP_BE   <= (others => '0');
				if( IP2Bus_RdAck = '1' and IP2Bus_Data(HASH_RDY) = '1') then
					current_state <= wait_clear;
					idx <= 0;
				end if;
			elsif( current_state = wait_clear ) then
				Bus2IP_RdCE <= (others => '0');
				if( IP2Bus_RdAck = '0') then
					current_state <= validate;
				end if;
			elsif( current_state = validate ) then
				Bus2IP_RdCE <= rdce;
				if( IP2Bus_RdAck = '1' ) then
					if( idx < 5 ) then
						assert( IP2Bus_Data = test3_hash(idx));
						idx <= idx + 1;
						rdce <= '0' & rdce(rdce'length-1 downto 1);
						current_state <= wait_clear;
					elsif( msg_count < 1 ) then
						current_state <= wait_for_ready;
						msg_count <= msg_count + 1;
					else
						current_state <= done;
					end if;
				end if;
			else
				Bus2IP_WrCE <= (others => '0');
				Bus2IP_RdCE <= (others => '0');
				Bus2IP_Data <= (others => '0');
				Bus2IP_BE <= (others => '0');
			end if;
		end if;
	end if;

end process test3;

finished <= '1' when current_state = done else '0';

end test3_i;
