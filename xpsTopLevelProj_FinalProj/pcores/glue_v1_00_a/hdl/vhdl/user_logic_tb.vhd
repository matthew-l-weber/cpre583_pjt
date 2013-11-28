-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
--                                                                           --
-- File Name: user_logic_tb.vhd                                              --
-- Author: Nathan Miller (nathanm2@iastate.edu  )                            --
-- Date: 11/23/2013                                                          --
--                                                                           --
-- Description: Testbench for user_logic_tb                                  --
--                                                                           --
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;

library glue_v1_00_a;
use glue_v1_00_a.user_logic;

library proc_common_v3_00_a;
use proc_common_v3_00_a.ipif_pkg.all;

entity user_logic_tb is
port
(
my_in : in std_logic -- input need to keep modelsim from
                     -- compaining???
);
end user_logic_tb;

architecture rtl of user_logic_tb is

----------------------------------------------
--       Constants declarations             --
----------------------------------------------

constant C_S_AXI_DATA_WIDTH             : integer              := 32;
constant C_S_AXI_ADDR_WIDTH             : integer              := 32;
constant IPIF_SLV_DWIDTH                : integer              := C_S_AXI_DATA_WIDTH;
constant USER_SLV_DWIDTH                : integer              := C_S_AXI_DATA_WIDTH;
constant RST_NUM_CE                     : integer              := 1;
constant USER_SLV_NUM_REG               : integer              := 32;
constant USER_NUM_REG                   : integer              := USER_SLV_NUM_REG;

constant IPIF_ARD_NUM_CE_ARRAY          : INTEGER_ARRAY_TYPE   := 
(
0  => (RST_NUM_CE),                 -- number of ce for soft reset space
1  => (USER_SLV_NUM_REG)            -- number of ce for user logic slave space
);

----------------------------------------------
--       Signal Declarations                --
----------------------------------------------
signal clk						: std_logic;  -- system clock
signal reset_n					: std_logic;  -- Reset active low
signal ipif_Bus2IP_Data         : std_logic_vector(IPIF_SLV_DWIDTH-1 downto 0);
signal ipif_Bus2IP_BE                 : std_logic_vector(IPIF_SLV_DWIDTH/8-1 downto 0);

signal user_Bus2IP_RdCE               : std_logic_vector(USER_NUM_REG-1 downto 0);
signal user_Bus2IP_WrCE               : std_logic_vector(USER_NUM_REG-1 downto 0);
signal user_IP2Bus_Data               : std_logic_vector(USER_SLV_DWIDTH-1 downto 0);
signal user_IP2Bus_RdAck              : std_logic;
signal user_IP2Bus_WrAck              : std_logic;
signal user_IP2Bus_Error              : std_logic;

type test_states is (t1_write, t1_write_ack, t1_read, t1_read_ack, done);
signal current_state : test_states;

signal idx : integer range 0 to 256;


begin


-- Processes

-------------------------------------------
-------------------------------------------
-- Process Name: system_clk_gen          --
--                                       --
-- Description: Generat clock to run the --
-- simulation.                           --
--                                       --
--                                       --
-------------------------------------------
-------------------------------------------
system_clk_gen : process
begin
  clk <= '0';
  wait for 10 ns;
    loop
      wait for 1 ns;
      clk <= '1';
      wait for 1 ns;
      clk <= '0';
    end loop;
end process system_clk_gen;


-------------------------------------------
-------------------------------------------
-- Process Name: toggle_reset            --
--                                       --
-- Description: Generate reset to run the --
-- simulation.                           --
--                                       --
--                                       --
-------------------------------------------
-------------------------------------------
toggle_reset : process
begin
  reset_n <= '0'; -- place circuit in reset
  wait for 100 ns;
  reset_n <= '1';
  wait;
end process toggle_reset;


-- Combinational assignments


  -- Port map MP1_top_driver
user_logic_i : entity glue_v1_00_a.user_logic
generic map
(
	C_NUM_REG                      => USER_NUM_REG,
	C_SLV_DWIDTH                   => USER_SLV_DWIDTH
)
port map
(
	  -- MAP USER PORTS BELOW THIS LINE ------------------
	  --USER ports mapped here
	  -- MAP USER PORTS ABOVE THIS LINE ------------------
      Bus2IP_Clk                     => clk,
      Bus2IP_Resetn                  => reset_n,
      Bus2IP_Data                    => ipif_Bus2IP_Data,
      Bus2IP_BE                      => ipif_Bus2IP_BE,
      Bus2IP_RdCE                    => user_Bus2IP_RdCE,
      Bus2IP_WrCE                    => user_Bus2IP_WrCE,
      IP2Bus_Data                    => user_IP2Bus_Data,
      IP2Bus_RdAck                   => user_IP2Bus_RdAck,
      IP2Bus_WrAck                   => user_IP2Bus_WrAck,
      IP2Bus_Error                   => user_IP2Bus_Error
);


test_harness : process(clk)
begin
	if(clk = '1' and clk'event) then
		if(reset_n = '0') then
			current_state <= t1_write;
			idx <= 0;
		else
			if( current_state = t1_write ) then
				user_Bus2IP_WrCE <= x"00400000"; -- Data0 register.
				ipif_Bus2IP_Data <= x"11223344";
				ipif_Bus2IP_BE <= (others => '1');
				if( user_IP2Bus_WrAck = '1' ) then
					current_state <= t1_read;
				end if;
			elsif( current_state = t1_read ) then
				user_Bus2IP_WrCE <= (others => '0');
				ipif_Bus2IP_Data <= (others => '0');
				ipif_Bus2IP_BE <= (others => '0');
				user_Bus2IP_RdCE <= x"00400000";
				if( user_IP2Bus_RdAck = '1' ) then
					assert(user_IP2Bus_Data = x"11223344");
					current_state <= done;
				end if;
			end if;
		end if;
	end if;

end process test_harness;

end rtl;
