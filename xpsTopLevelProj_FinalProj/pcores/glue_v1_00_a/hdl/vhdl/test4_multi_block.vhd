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

entity test4_multi_block is
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
end test4_multi_block;

architecture test4_i of test4_multi_block is

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
	constant HASH_BUSY  : integer := 2;


	-- A multi-block message:
	signal test4_1_msg : sha1_in := (
	x"61616161", x"61616161", x"61616161", x"61616161",
	x"61616161", x"61616161", x"61616161", x"61616161",
	x"61616161", x"61616161", x"61616161", x"61616161",
	x"61616161", x"61616161", x"61616161", x"61616161"
	);

	signal test4_2_msg : sha1_in := (
	x"61616161", x"61616161", x"61616161", x"61616161",
	x"61616161", x"61616161", x"61616161", x"61616161",
	x"61616161", x"61616161", x"61616161", x"61616161",
	x"61616161", x"61616180", x"00000000", x"000003b8"
	);

	signal test4_hash : sha1_out := (
	x"ee971065", x"aaa017e0", x"632a8ca6", x"c77bb3bf", x"8b1dfc56"
	);

	signal msg_count : integer range 0 to 2;
	signal idx : integer range 0 to 16;

	signal wrce : std_logic_vector(C_NUM_REG-1 downto 0);
	signal rdce : std_logic_vector(C_NUM_REG-1 downto 0);

begin


-- Processes

test4 : process(clk)
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
				Bus2IP_BE   <= (others => '1');
				if (msg_count = 0) then
					Bus2IP_Data <= test4_1_msg(idx);
				else
					Bus2IP_Data <= test4_2_msg(idx);
				end if;

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
				Bus2IP_BE	<= (others => '1');
				if( msg_count = 0 ) then
					Bus2IP_Data <= x"00000001";
				else
					Bus2IP_Data <= x"00000002";
				end if;
				if( IP2Bus_WrAck = '1' ) then
					if(msg_count = 0 ) then
						msg_count <= msg_count + 1;
						current_state <= wait_for_ready;
					else
						current_state <= wait_hash;
					end if;
				end if;
			elsif( current_state = wait_hash ) then
				Bus2IP_WrCE <= (others => '0');
				Bus2IP_RdCE <= STATUS_REG;
				Bus2IP_Data <= (others => '0');
				Bus2IP_BE   <= (others => '0');
				if( IP2Bus_RdAck = '1' and IP2Bus_Data(HASH_RDY) = '1' and
			        IP2Bus_Data(HASH_BUSY) = '0')  then
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
						assert( IP2Bus_Data = test4_hash(idx));
						idx <= idx + 1;
						rdce <= '0' & rdce(rdce'length-1 downto 1);
						current_state <= wait_clear;
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

end process test4;

finished <= '1' when current_state = done else '0';

end test4_i;
