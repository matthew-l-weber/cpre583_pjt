-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
--                                                                           --
-- File Name: sha1_tb_driver.vhd                                             --
-- Author: Nathan Miller (nathanm2@iastate.edu)                              --
-- Date: 11/09/2013                                                           --
--                                                                           --
-- Description: Drives the SHA1 simulation.                                  --
--                                                                           --
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;


entity sha1_tb_driver is
port
(
	msg				: out  std_logic_vector ( 31 downto 0);
    init			: out  std_logic;                     --    initial message
	ld				: out  std_logic;                      --    load signal
    hash            : in   std_logic_vector ( 31 downto 0); --
	valid           : in   std_logic;
    clk             : in   std_logic;  -- system clock
    rst             : in   std_logic  -- Active low
);
end sha1_tb_driver;

architecture rtl of sha1_tb_driver is

type sha1_in is array (0 to 15) of std_logic_vector(31 downto 0);
type sha1_out is array (0 to 4) of std_logic_vector(31 downto 0);


-- The simplest message possible:
signal test1_msg : sha1_in := (
	x"80000000", x"00000000", x"00000000", x"00000000",
	x"00000000", x"00000000", x"00000000", x"00000000",
	x"00000000", x"00000000", x"00000000", x"00000000",
	x"00000000", x"00000000", x"00000000", x"00000000"
);

signal test1_hash : sha1_out := (
	x"da39a3ee", x"5e6b4b0d", x"3255bfef", x"95601890", x"afd80709"
);

-- "The quick brown fox jumps over the lazy dog":
--  Note1: The 0x80 must be appended to the end of text.
--  Note2: The length of the message IN BITS (not including the 0x80) is
--  located in the last 64-bits of the message.

signal test2_msg : sha1_in := (
	x"54686520", x"71756963", x"6b206272", x"6f776e20",
	x"666f7820", x"6a756d70", x"73206f76", x"65722074",
	x"6865206c", x"617a7920", x"646f6780", x"00000000",
	x"00000000", x"00000000", x"00000000", x"00000158"
);

signal test2_hash : sha1_out := (
	x"2fd4e1c6", x"7a2d28fc", x"ed849ee1", x"bb76e739", x"1b93eb12"
);

-- A multi-block message:
signal test3_1_msg : sha1_in := (
	x"61616161", x"61616161", x"61616161", x"61616161",
	x"61616161", x"61616161", x"61616161", x"61616161",
	x"61616161", x"61616161", x"61616161", x"61616161",
	x"61616161", x"61616161", x"61616161", x"61616161"
);

signal test3_2_msg : sha1_in := (
	x"61616161", x"61616161", x"61616161", x"61616161",
	x"61616161", x"61616161", x"61616161", x"61616161",
	x"61616161", x"61616161", x"61616161", x"61616161",
	x"61616161", x"61616180", x"00000000", x"000003b8"
);

signal test3_hash : sha1_out := (
	x"ee971065", x"aaa017e0", x"632a8ca6", x"c77bb3bf", x"8b1dfc56"
);

type test_states is (t1_send, t1_wait, t1_validate,
					 t2_send, t2_wait, t2_validate,
					 t3_1_send, t3_1_wait, t3_2_delay, t3_2_send, t3_2_wait,
					 t3_validate, done);
signal current_state : test_states;

signal msg_out : std_logic_vector( 31 downto 0 );
signal ld_out : std_logic;
signal init_out : std_logic;

signal idx : integer range 0 to 256;

begin

test_harness : process(clk)
begin

	if (clk = '1' and clk'event) then
		if(rst = '1' ) then
			current_state <= t1_send;
			ld_out <= '0';
			msg_out <= (others => '0');
			init_out <= '0';
			idx <= 0;

		else

			if( current_state = t1_send ) then
				if( idx < test1_msg'length ) then
					msg_out <= test1_msg(idx);
					idx <= idx + 1;
					ld_out <= '1';
				else
					current_state <= t1_wait;
					idx <= 0;
					ld_out <= '0';
					msg_out <= (others => '0');
				end if;

			elsif( current_state = t1_wait ) then
				if( valid = '1') then
					current_state <= t1_validate;
				end if;

			elsif( current_state = t1_validate ) then
				if( idx < test1_hash'length ) then
					assert (hash = test1_hash(idx)) report
					 "test1 failed!" severity failure;
					idx <= idx + 1;
				else
					current_state <= t2_send;
					idx <= 0;
				end if;
			elsif( current_state = t2_send ) then
				if( idx < test2_msg'length ) then
					msg_out <= test2_msg(idx);
					idx <= idx + 1;
					ld_out <= '1';
					init_out <= '1';
				else
					current_state <= t2_wait;
					idx <= 0;
					ld_out <= '0';
					msg_out <= (others => '0');
					init_out <= '0';
				end if;

			elsif( current_state = t2_wait ) then
				if( valid = '1') then
					current_state <= t2_validate;
				end if;

			elsif( current_state = t2_validate ) then
				if( idx < test2_hash'length ) then
					assert (hash = test2_hash(idx)) report
					 "test2 failed!" severity failure;
					idx <= idx + 1;
				else
					current_state <= t3_1_send;
					idx <= 0;
				end if;
			elsif( current_state = t3_1_send ) then
				if( idx < test3_1_msg'length ) then
					msg_out <= test3_1_msg(idx);
					idx <= idx + 1;
					ld_out <= '1';
					init_out <= '1';
				else
					current_state <= t3_1_wait;
					idx <= 0;
					ld_out <= '0';
					msg_out <= (others => '0');
					init_out <= '0';
				end if;

			elsif( current_state = t3_1_wait ) then
				if( valid = '1') then
					current_state <= t3_2_delay;
				end if;

			-- Let's see what happens if we delay the second block by a few
			-- cycles:
			elsif( current_state = t3_2_delay ) then
				if( idx < 89 ) then
					idx <= idx + 1;
				else
					current_state <= t3_2_send;
					idx <= 0;
				end if;

			elsif( current_state = t3_2_send ) then
				if( idx < test3_2_msg'length ) then
					msg_out <= test3_2_msg(idx);
					idx <= idx + 1;
					ld_out <= '1';
				else
					current_state <= t3_2_wait;
					idx <= 0;
					ld_out <= '0';
					msg_out <= (others => '0');
				end if;
			elsif( current_state = t3_2_wait ) then
				if( valid = '1') then
					current_state <= t3_validate;
				end if;
			elsif( current_state = t3_validate ) then
				if( idx < test3_hash'length ) then
					assert (hash = test3_hash(idx)) report
					 "test3 failed!" severity failure;
					idx <= idx + 1;
				else
					current_state <= done;
					idx <= 0;
				end if;
			end if;
		end if;
	end if;

end process test_harness;

msg <= msg_out;
ld <= ld_out;
init <= init_out;


end rtl;

