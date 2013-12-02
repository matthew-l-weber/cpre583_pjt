-- ------------------------------------------------------------------------
-- Copyright (C) 2010 Arif Endro Nugroho
-- All rights reserved.
-- 
-- Redistribution and use in source and binary forms, with or without
-- modification, are permitted provided that the following conditions
-- are met:
-- 
-- 1. Redistributions of source code must retain the above copyright
--    notice, this list of conditions and the following disclaimer.
-- 2. Redistributions in binary form must reproduce the above copyright
--    notice, this list of conditions and the following disclaimer in the
--    documentation and/or other materials provided with the distribution.
-- 
-- THIS SOFTWARE IS PROVIDED BY ARIF ENDRO NUGROHO "AS IS" AND ANY EXPRESS
-- OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
-- WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
-- DISCLAIMED. IN NO EVENT SHALL ARIF ENDRO NUGROHO BE LIABLE FOR ANY
-- DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
-- DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
-- OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
-- HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
-- STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
-- ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
-- POSSIBILITY OF SUCH DAMAGE.
-- 
-- End Of License.
-- ------------------------------------------------------------------------
--
-- MaxMessage  <= 2^64 bits
-- BlockSize   ==  512 bits
-- WordSize    ==   32 bits
-- MDigestSize ==  160 bits
-- Security    ==  128 bits
--
-- SHLnx  = (x<<n)
-- SHRnx  = (x>>n)
-- ROTRnx = (x>>n) or (x<<w-n)
-- ROTLnx = (x<<n) or (x>>w-n)
--
-- f  = ((x and y) xor (not(x) and z))           0 <= t <=  19
-- f  = (x xor y xor z)                         20 <= t <=  39
-- f  = ((x and y) xor (x and z) xor (y and z)  40 <= t <=  59
-- f  = (x xor y xor z)                         60 <= t <=  79
--
-- h0 = 0x67452301
-- h1 = 0xefcdab89
-- h2 = 0x98badcfe
-- h3 = 0x10325476
-- h4 = 0xc3d2e1f0
--
-- k0 = 0x5a827999   0 <= t <=  19
-- k1 = 0x6ed9eba1  20 <= t <=  39
-- k2 = 0x8f1bbcdc  40 <= t <=  59
-- k3 = 0xca62c1d6  60 <= t <=  79
--
-- Step 1
-- W(t) = M(t)                                                 0 <= t <=  15 -- we need 16x32 (512) std_logic registers
-- W(t) = (W(t-3) xor W(t-8) xor W(t-14) xor W(t-16)) ROTL 1  16 <= t <=  79
-- W    = (W(  2) xor W(  7) xor W(  13) xor W(  15)) ROTL 1; 16 <= t <=  79
--
-- Step 2
-- a = h0; b = h1; c = h2; d = h3; e = h4
--
-- Step 3
-- for t 0 step 1 to 79 do
-- T = ROTL5(a) xor f(b, c, d) xor e xor k(t) xor W(t)
-- e = d
-- d = c
-- c = ROTL30(b) -- c = ROTR2(b)
-- b = a
-- a = T
--
-- Step 4
-- H0 = a xor h0;
-- H1 = b xor h1;
-- H2 = c xor h2;
-- H3 = d xor h3;
-- H4 = e xor H4;
--
--  31 63 95 127 159 191 223 255 287 319 351 383 415 447 479 511
-- 0 32 64 96 128 160 192 224 256 288 320 352 384 416 448 480 512
--    0  1  2   3   4   5   6   7   8   9   a   b   c   d   e   f

library ieee;
use ieee.std_logic_1164.all; -- std_logic stuff
use ieee.numeric_std.all;    -- basic math for std_logic


entity sha1 is
  port(
  sha_msg          : in  std_logic_vector ( 31 downto 0); --    32 std_logic data path require 16 clock to load all 512 bits
														  --    of each block
  sha_init         : in  std_logic;                       --    initial message
  sha_load         : in  std_logic;                       --    load signal
  sha_hash         : out std_logic_vector ( 31 downto 0); --    5 clock after active valid signal is the message hash result
  sha_valid        : out std_logic;                       --    hash output valid signal one clock advance
  sha_clk          : in  std_logic;                       --    master clock signal
  sha_reset        : in  std_logic                        --    master reset signal
  );
end sha1;

architecture phy of sha1 is

  component c4b
    port (
    cnt            : out std_logic_vector (  3 downto 0);
    clk            : in  std_logic;
    rst            : in  std_logic
    );
  end component;
 
  component c6b
    port (
    cnt            : out std_logic_vector (  5 downto 0);
    clk            : in  std_logic;
    rst            : in  std_logic
    );
  end component;
 
  signal   ih      :     std_logic_vector ( 31 downto 0);
  signal   h0      :     std_logic_vector ( 31 downto 0);
  signal   h1      :     std_logic_vector ( 31 downto 0);
  signal   h2      :     std_logic_vector ( 31 downto 0);
  signal   h3      :     std_logic_vector ( 31 downto 0);
  signal   h4      :     std_logic_vector ( 31 downto 0);
 
  constant k0      :     std_logic_vector ( 31 downto 0) := X"5a827999";
  constant k1      :     std_logic_vector ( 31 downto 0) := X"6ed9eba1";
  constant k2      :     std_logic_vector ( 31 downto 0) := X"8f1bbcdc";
  constant k3      :     std_logic_vector ( 31 downto 0) := X"ca62c1d6";
  signal   k       :     std_logic_vector ( 31 downto 0);
 
  signal   im      :     std_logic_vector ( 31 downto 0);
  signal   iw      :     std_logic_vector ( 31 downto 0);
  signal   w       :     std_logic_vector ( 31 downto 0); -- current working register
  signal   w0      :     std_logic_vector (511 downto 0); -- working register 1
 
  signal   a       :     std_logic_vector ( 31 downto 0); -- a register
  signal   b       :     std_logic_vector ( 31 downto 0); -- b register
  signal   c       :     std_logic_vector ( 31 downto 0); -- c register
  signal   d       :     std_logic_vector ( 31 downto 0); -- d register
  signal   e       :     std_logic_vector ( 31 downto 0); -- e register
 
  signal   f       :     std_logic_vector ( 31 downto 0); 
 
  signal   ctr2    :     std_logic_vector (  3 downto 0); --  4  std_logic counter (zero to  16)
  signal   ctr2_rst:     std_logic;
  signal   ctr3    :     std_logic_vector (  5 downto 0); --  6  std_logic counter (zero to  64)
  signal   ctr3_rst:     std_logic;
 
  signal   vld     :     std_logic;
  signal   nld     :     std_logic;
  signal   ild     :     std_logic;
  signal   ild_rst :     std_logic;
  signal   commit  :     std_logic;
 
  signal   sr      :     std_logic_vector (  1 downto 0);
  signal   sc      :     std_logic_vector (  1 downto 0);
 
begin
 
  ct2              : c4b
  port map (
  cnt              => ctr2,
  clk              => sha_clk,
  rst              => ctr2_rst
  );
  ct3              : c6b
  port map (
  cnt              => ctr3,
  clk              => sha_clk,
  rst              => ctr3_rst
  );

--persistent connection
  with sc (  1 downto 0) select
  f                <= ((b and c) xor (not(b) and d))          when B"00", --  0 <= t <= 19
                      ( b xor c  xor d)                       when B"01", -- 20 <= t <= 39
                      ((b and c) xor (b and d) xor (c and d)) when B"10", -- 40 <= t <= 59
                      ( b xor c  xor d)                       when B"11", -- 60 <= t <= 79
					  (others => '0')						  when others;
  with sc (  1 downto 0) select
  k                <= k0                                      when B"00",
                      k1                                      when B"01",
                      k2                                      when B"10",
                      k3                                      when B"11",
					  (others => '0')                         when others;
  with ctr2( 3 downto 0) select
  ih               <= h0                                      when B"0000",
                      h1                                      when B"0001",
                      h2                                      when B"0010",
                      h3                                      when B"0011",
                      h4                                      when B"0100",
		      (others => '0')                         when others;
 
--W                =  (W(  2)            xor W(  7)             xor W(  13)            xor W(  15)) ROTL 1; 16 <= t <=  79
  iw               <= w0( 95 downto  64) xor w0(255 downto 224) xor w0(447 downto 416) xor w0(511 downto 480);
 
  process (sha_clk)
  begin
    if ((sha_clk = '1') and sha_clk'event) then
      if    (sha_reset = '1') then
        w          <= (others => '0');
        w0         <= (others => '0');
      elsif (nld = '1') then                                              -- 0 <= t <= 15 first 512 std_logic block
        w          <=              im;
		w0(511 downto 0) <= (w0(479 downto  0) & im);
      else                                                                -- ROTL1
        w          <= (iw( 30 downto   0) & iw( 31));
		w0(511 downto 0) <= (w0(479 downto   0) & iw( 30 downto   0) & iw( 31)); 
      end if;
    end if;
  end process;
 
  process (sha_clk)
  begin
    if ((sha_clk = '1') and sha_clk'event) then
      if (sha_reset = '1') then
        ild        <=  '0';
		nld        <=  '0';
		im         <= (others => '0');
      else
        ild        <=  nld;
		nld        <=   sha_load;
		im         <=    sha_msg;
      end if;
    end if;
  end process;
 
  sr               <= (sc(0) & '0');
 
  process (sha_clk)
  begin
    if ((sha_clk = '1') and sha_clk'event) then
      if ((ild_rst or sha_reset) = '1') then
        sc         <= (others => '0');
      elsif (ctr3 = B"010011") then
        sc         <= ((sc xor B"01") xor sr);
      end if;
    end if;
  end process;
 
  process (sha_clk)
  begin
    if ((sha_clk = '1') and sha_clk'event) then
      if ((ild_rst or sha_reset) = '1') then
        vld        <=  '0';
      elsif (ctr3 = B"010011") and (sc = B"11") then
        vld        <=  '1';
      else
        vld        <=  '0';
      end if;
    end if;
  end process;
 
  process (sha_clk)
  begin
	  if ((sha_clk = '1') and sha_clk'event) then
		  if( sha_reset = '1') then
			  commit <= '0';
		  elsif( ild_rst = '1' ) then
			  commit <= '1';
		  elsif( vld = '1' ) then
			  commit <= '0';
		  end if;
	 end if;
  end process;

  ild_rst          <= (ild xor sha_load) and sha_load;
--ctr2_rst         <=  ild_rst     or rst or vld or (ctr2 = B"0100");     -- set to count to  4 (  5 clock)
  ctr2_rst         <=  ild_rst     or sha_reset or vld or not(ctr2(3) or not(ctr2(2)) or ctr2(1) or ctr2(0));
--ctr3_rst         <=  ild_rst     or rst or (ctr3 = B"010011");          -- set to count to 19 ( 20 clock)
  ctr3_rst         <=  ild_rst     or sha_reset or not(ctr3(5) or not(ctr3(4)) or ctr3(3) or ctr3(2) or not(ctr3(1)) or not(ctr3(0)));
 
  process (sha_clk)
  begin
    if ((sha_clk = '1') and sha_clk'event) then
      if (sha_init = '1')  or (sha_reset = '1')then
        h0         <= X"67452301";
        h1         <= X"efcdab89";
        h2         <= X"98badcfe";
        h3         <= X"10325476";
        h4         <= X"c3d2e1f0";
      elsif (vld = '1') and (commit = '1') then -- FIXME this adder is very costly and NOT A PORTABLE CODE
		h0         <= std_logic_vector( unsigned(a) + unsigned(h0));
        h1         <= std_logic_vector( unsigned(b) + unsigned(h1));
        h2         <= std_logic_vector( unsigned(c) + unsigned(h2));
        h3         <= std_logic_vector( unsigned(d) + unsigned(h3));
        h4         <= std_logic_vector( unsigned(e) + unsigned(h4));
      end if;
    end if;
  end process;

  process (sha_clk)
  begin
    if ((sha_clk = '1') and sha_clk'event) then
      if ((ild_rst or sha_reset) = '1') then
        a          <= h0;
        b          <= h1;
        c          <= h2;
        d          <= h3;
        e          <= h4;
       else
--      a          <= (a(26 downto 0) & a(31 downto 27)) + f + e + k + w; -- ROTL5(a)  -- FIXME this adder is very costly and NOT A PORTABLE CODE
        a          <= std_logic_vector( unsigned(a(26 downto 0) & a(31 downto 27)) + unsigned(f) + unsigned(e) + unsigned(k) + unsigned(w) );
        b          <=  a;
        c          <= (b( 1 downto 0) & b(31 downto  2));                 -- ROTL30(b) -- ROTR2(b)
        d          <=  c;
		e          <=  d;
      end if;
    end if;
  end process;
 
  sha_hash         <=  ih;
  sha_valid        <=  vld and commit;
 
end phy;
