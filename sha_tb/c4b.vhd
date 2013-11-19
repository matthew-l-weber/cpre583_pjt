library ieee;
use ieee.std_logic_1164.all; -- std_logic stuff
use ieee.numeric_std.all;    -- basic math for std_logic

entity c4b is
	port(
		cnt		: out std_logic_vector( 3 downto 0 );
		clk		: in std_logic;
		rst		: in std_logic
	);
end c4b;

architecture rtl_c4b of c4b is
	signal	reg		: std_logic_vector( 3 downto 0 );
begin

		process(clk)
		begin
			if ((clk = '1') and clk'event) then
				if( rst = '1') then
					reg <= (others => '0');
				else
					reg <= std_logic_vector(unsigned(reg) + 1);
				end if;
			end if;
		end process;

		cnt <= reg;

end rtl_c4b;


