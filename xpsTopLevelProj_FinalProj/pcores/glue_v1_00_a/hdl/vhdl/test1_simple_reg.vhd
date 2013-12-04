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

library proc_common_v3_00_a;
use proc_common_v3_00_a.ipif_pkg.all;

entity user_logic_tb_test1 is
  generic
  (
    C_NUM_REG                      : integer              := 32;
    C_SLV_DWIDTH                   : integer              := 32
  );
  port
  (
    clk                            : in  std_logic;
    Bus2IP_Resetn                  : in  std_logic;
    Bus2IP_Data                    : out std_logic_vector(C_SLV_DWIDTH-1 downto 0);
    Bus2IP_BE                      : out std_logic_vector(C_SLV_DWIDTH/8-1 downto 0);
    Bus2IP_RdCE                    : out std_logic_vector(C_NUM_REG-1 downto 0);
    Bus2IP_WrCE                    : out std_logic_vector(C_NUM_REG-1 downto 0);
    IP2Bus_Data                    : in  std_logic_vector(C_SLV_DWIDTH-1 downto 0);
    IP2Bus_RdAck                   : in  std_logic;
    IP2Bus_WrAck                   : in  std_logic;
    IP2Bus_Error                   : in  std_logic;
    finished                       : out std_logic
  );
end user_logic_tb_test1;

architecture test1_i of user_logic_tb_test1 is

----------------------------------------------
--       Signal Declarations                --
----------------------------------------------
type test_states is (write, read, done);
signal current_state : test_states;


begin


-- Processes

test1 : process(clk)
begin
	if(clk = '1' and clk'event) then
		if(Bus2IP_Resetn = '0') then
			current_state <= write;
			Bus2IP_WrCE <= (others => '0');
			Bus2IP_RdCE <= (others => '0');
			Bus2IP_Data <= (others => '0');
			Bus2IP_BE <= (others => '0');
		else
			if( current_state = write ) then
				Bus2IP_WrCE <= x"00400000"; -- Data0 register.
				Bus2IP_Data <= x"11223344";
				Bus2IP_BE <= (others => '1');
				if( IP2Bus_WrAck = '1' ) then
					current_state <= read;
				end if;
			elsif( current_state = read ) then
				Bus2IP_WrCE <= (others => '0');
				Bus2IP_Data <= (others => '0');
				Bus2IP_BE <= (others => '0');
				Bus2IP_RdCE <= x"00400000";
				if( IP2Bus_RdAck = '1' ) then
					assert(IP2Bus_Data = x"11223344");
					current_state <= done;
				end if;
			end if;
		end if;
	end if;

end process test1;

finished <= '1' when current_state = done else '0';

end test1_i;

