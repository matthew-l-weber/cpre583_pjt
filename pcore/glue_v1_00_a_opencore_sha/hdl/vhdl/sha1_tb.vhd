-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
--                                                                           --
-- File Name: MP1_tb.vhd                                                     --
-- Author: Nathan Miller (nathanm2@iastate.edu  )                            --
-- Date: 11/09/2013                                                          --
--                                                                           --
-- Description: Testbench for sha1_oc                                        --
--                                                                           --
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;


entity sha1_tb is
port
(
my_in : in std_logic -- input need to keep modelsim from                        
                     -- compaining???
);
end sha1_tb;

architecture rtl of sha1_tb is

----------------------------------------------
--       Component declarations             --
----------------------------------------------

-- Component that get put on the FPGA
component sha1
port
(
	m				: in  std_logic_vector ( 31 downto 0);
    init			: in  std_logic;                       --    initial message
	ld				: in  std_logic;                       --    load signal
    h               : out std_logic_vector ( 31 downto 0); --
	v               : out std_logic;
	clk             : in  std_logic;                       --    master clock signal
	rst             : in  std_logic                       --    master reset signal
);
end component;


component sha1_tb_driver
port
(
	msg				: out  std_logic_vector ( 31 downto 0);
    init			: out  std_logic;                     --    initial message
	ld				: out  std_logic;                     --    load signal
    hash            : in std_logic_vector ( 31 downto 0); --
	valid           : in std_logic;
    clk             : in  std_logic;  -- system clock
    rst             : in  std_logic  -- Active low
);
end component;


----------------------------------------------
--          Signal declarations             --
----------------------------------------------
signal system_clk : std_logic;  -- system clock
signal reset_n    : std_logic;  -- Reset active low
signal reset      : std_logic;

signal msg : std_logic_vector( 31 downto 0 );
signal init : std_logic;
signal ld : std_logic;
signal hash : std_logic_vector( 31 downto 0);
signal valid : std_logic;

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
  system_clk <= '0';
  wait for 10 ns;
    loop
      wait for 1 ns;
      system_clk <= '1';
      wait for 1 ns;
      system_clk <= '0';
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
sha1_driver : sha1_tb_driver
port map
(
	msg			=> msg,
	init		=> init,
	ld			=> ld,
	hash		=> hash,
	valid		=> valid,
	clk			=> system_clk,  -- system clock
	rst			=> reset     -- Active low reset
);


  -- Port map MP1_top
sha1_hw : sha1
port map
(
	m			=> msg,
	init		=> init,
	ld			=> ld,
	h			=> hash,
	v			=> valid,
	clk			=> system_clk,  -- system clock
	rst			=> reset     -- Active low reset
);

reset <= not(reset_n);

end rtl;
