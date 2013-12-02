------------------------------------------------------------------------------
-- user_logic.vhd - entity/architecture pair
------------------------------------------------------------------------------
--
-- ***************************************************************************
-- ** Copyright (c) 1995-2012 Xilinx, Inc.  All rights reserved.            **
-- **                                                                       **
-- ** Xilinx, Inc.                                                          **
-- ** XILINX IS PROVIDING THIS DESIGN, CODE, OR INFORMATION "AS IS"         **
-- ** AS A COURTESY TO YOU, SOLELY FOR USE IN DEVELOPING PROGRAMS AND       **
-- ** SOLUTIONS FOR XILINX DEVICES.  BY PROVIDING THIS DESIGN, CODE,        **
-- ** OR INFORMATION AS ONE POSSIBLE IMPLEMENTATION OF THIS FEATURE,        **
-- ** APPLICATION OR STANDARD, XILINX IS MAKING NO REPRESENTATION           **
-- ** THAT THIS IMPLEMENTATION IS FREE FROM ANY CLAIMS OF INFRINGEMENT,     **
-- ** AND YOU ARE RESPONSIBLE FOR OBTAINING ANY RIGHTS YOU MAY REQUIRE      **
-- ** FOR YOUR IMPLEMENTATION.  XILINX EXPRESSLY DISCLAIMS ANY              **
-- ** WARRANTY WHATSOEVER WITH RESPECT TO THE ADEQUACY OF THE               **
-- ** IMPLEMENTATION, INCLUDING BUT NOT LIMITED TO ANY WARRANTIES OR        **
-- ** REPRESENTATIONS THAT THIS IMPLEMENTATION IS FREE FROM CLAIMS OF       **
-- ** INFRINGEMENT, IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS       **
-- ** FOR A PARTICULAR PURPOSE.                                             **
-- **                                                                       **
-- ***************************************************************************
--
------------------------------------------------------------------------------
-- Filename:          user_logic.vhd
-- Version:           1.00.a
-- Description:       User logic.
-- Date:              Mon Nov 04 20:20:54 2013 (by Create and Import Peripheral Wizard)
-- VHDL Standard:     VHDL'93
------------------------------------------------------------------------------
-- Naming Conventions:
--   active low signals:                    "*_n"
--   clock signals:                         "clk", "clk_div#", "clk_#x"
--   reset signals:                         "rst", "rst_n"
--   generics:                              "C_*"
--   user defined types:                    "*_TYPE"
--   state machine next state:              "*_ns"
--   state machine current state:           "*_cs"
--   combinatorial signals:                 "*_com"
--   pipelined or register delay signals:   "*_d#"
--   counter signals:                       "*cnt*"
--   clock enable signals:                  "*_ce"
--   internal version of output port:       "*_i"
--   device pins:                           "*_pin"
--   ports:                                 "- Names begin with Uppercase"
--   processes:                             "*_PROCESS"
--   component instantiations:              "<ENTITY_>I_<#|FUNC>"
------------------------------------------------------------------------------

-- DO NOT EDIT BELOW THIS LINE --------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library proc_common_v3_00_a;
use proc_common_v3_00_a.proc_common_pkg.all;

-- DO NOT EDIT ABOVE THIS LINE --------------------

--USER libraries added here
library glue_v1_00_a;

------------------------------------------------------------------------------
-- Entity section
------------------------------------------------------------------------------
-- Definition of Generics:
--   C_NUM_REG                    -- Number of software accessible registers
--   C_SLV_DWIDTH                 -- Slave interface data bus width
--
-- Definition of Ports:
--   Bus2IP_Clk                   -- Bus to IP clock
--   Bus2IP_Resetn                -- Bus to IP reset
--   Bus2IP_Data                  -- Bus to IP data bus
--   Bus2IP_BE                    -- Bus to IP byte enables
--   Bus2IP_RdCE                  -- Bus to IP read chip enable
--   Bus2IP_WrCE                  -- Bus to IP write chip enable
--   IP2Bus_Data                  -- IP to Bus data bus
--   IP2Bus_RdAck                 -- IP to Bus read transfer acknowledgement
--   IP2Bus_WrAck                 -- IP to Bus write transfer acknowledgement
--   IP2Bus_Error                 -- IP to Bus error response
------------------------------------------------------------------------------

entity user_logic is
  generic
  (
    -- ADD USER GENERICS BELOW THIS LINE ---------------
    --USER generics added here
    -- ADD USER GENERICS ABOVE THIS LINE ---------------

    -- DO NOT EDIT BELOW THIS LINE ---------------------
    -- Bus protocol parameters, do not add to or delete
    C_NUM_REG                      : integer              := 32;
    C_SLV_DWIDTH                   : integer              := 32
    -- DO NOT EDIT ABOVE THIS LINE ---------------------
  );
  port
  (
    -- ADD USER PORTS BELOW THIS LINE ------------------
    --USER ports added here
    -- ADD USER PORTS ABOVE THIS LINE ------------------

    -- DO NOT EDIT BELOW THIS LINE ---------------------
    -- Bus protocol ports, do not add to or delete
    Bus2IP_Clk                     : in  std_logic;
    Bus2IP_Resetn                  : in  std_logic;
    Bus2IP_Data                    : in  std_logic_vector(C_SLV_DWIDTH-1 downto 0);
    Bus2IP_BE                      : in  std_logic_vector(C_SLV_DWIDTH/8-1 downto 0);
    Bus2IP_RdCE                    : in  std_logic_vector(C_NUM_REG-1 downto 0);
    Bus2IP_WrCE                    : in  std_logic_vector(C_NUM_REG-1 downto 0);
    IP2Bus_Data                    : out std_logic_vector(C_SLV_DWIDTH-1 downto 0);
    IP2Bus_RdAck                   : out std_logic;
    IP2Bus_WrAck                   : out std_logic;
    IP2Bus_Error                   : out std_logic
    -- DO NOT EDIT ABOVE THIS LINE ---------------------
  );

  attribute MAX_FANOUT : string;
  attribute SIGIS : string;

  attribute SIGIS of Bus2IP_Clk    : signal is "CLK";
  attribute SIGIS of Bus2IP_Resetn : signal is "RST";

end entity user_logic;

------------------------------------------------------------------------------
-- Architecture section
------------------------------------------------------------------------------

architecture IMP of user_logic is

	component sha1
	port
	(
		sha_msg   : in std_logic_vector ( 31 downto 0);
		sha_init  : in std_logic; -- initial message
		sha_load  : in std_logic; -- load signal
		sha_hash  : out std_logic_vector ( 31 downto 0); --
		sha_valid : out std_logic;
		sha_clk   : in std_logic; -- master clock signal
		sha_reset : in std_logic -- master reset signal
);
end component;

	-- State info:
	type algo_states is (algoWait, dataXfer, hashWait, saveHash, algoDone);
	signal algoState :  algo_states;
  
	-- Status bits: 
	signal input_rdy : std_logic;		-- Input data can safely be written.
	signal hash_rdy  : std_logic;		-- Hash operation is complete.
	signal hash_busy : std_logic;		-- Hash operation in progress.

	signal ul_msg   : std_logic_vector ( 31 downto 0);
	signal ul_init  : std_logic;
	signal ul_load  : std_logic;
	signal ul_hash  : std_logic_vector ( 31 downto 0);
	signal ul_valid : std_logic;
	signal ul_reset : std_logic;


	signal ld_map : std_logic_vector ( 16 downto 0 );

	-- These local_ reg and the bus_slv_reg# are used to allow the user
	-- logic to modify bus regs which could also be set via the bus
	signal bus_slv_reg0   : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
	signal bus_slv_reg1   : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
	signal bus_slv_reg2   : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
	signal bus_slv_reg3   : std_logic_vector(C_SLV_DWIDTH-1 downto 0);

	signal local_rst      : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
	signal local_status   : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
	signal local_startBlk : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
	signal local_finished : std_logic_vector(C_SLV_DWIDTH-1 downto 0);

  ------------------------------------------
  -- Signals for user logic slave model s/w accessible register example
  ------------------------------------------
  signal slv_reg0_rst      : std_logic_vector(C_SLV_DWIDTH-1 downto 0); --rst 0-no,1-yes                        (bus driven and user_logic clrs)  (bus RW)
  signal slv_reg1_status   : std_logic_vector(C_SLV_DWIDTH-1 downto 0); --rdy 0-no,1-rdy for data, 2-hash rdy   (user_logic driven)   (bus RO)
  signal slv_reg2_startBlk : std_logic_vector(C_SLV_DWIDTH-1 downto 0); --blk rdy            (0-no,1-yes)       (bus driven and user_logic clrs)  (bus RW)
  signal slv_reg3_finished : std_logic_vector(C_SLV_DWIDTH-1 downto 0); --finished multi-blk (0-no,1-yes)       (bus driven and user_logic clrs)  (bus RW)
  signal slv_reg4_h0 : std_logic_vector(C_SLV_DWIDTH-1 downto 0); --Hash0  (user_logic driven) (bus RO)
  signal slv_reg5_h1 : std_logic_vector(C_SLV_DWIDTH-1 downto 0); --Hash1  (user_logic driven) (bus RO)
  signal slv_reg6_h2 : std_logic_vector(C_SLV_DWIDTH-1 downto 0); --Hash2  (user_logic driven) (bus RO)
  signal slv_reg7_h3 : std_logic_vector(C_SLV_DWIDTH-1 downto 0); --Hash3  (user_logic driven) (bus RO)
  signal slv_reg8_h4 : std_logic_vector(C_SLV_DWIDTH-1 downto 0); --Hash4  (user_logic driven) (bus RO)
  signal slv_reg9    : std_logic_vector(C_SLV_DWIDTH-1 downto 0); --Data0  (bus driven)   (bus RW)
  signal slv_reg10   : std_logic_vector(C_SLV_DWIDTH-1 downto 0); --Data1  (bus driven)   (bus RW)
  signal slv_reg11   : std_logic_vector(C_SLV_DWIDTH-1 downto 0); --Data2  (bus driven)   (bus RW)
  signal slv_reg12   : std_logic_vector(C_SLV_DWIDTH-1 downto 0); --Data3  (bus driven)   (bus RW)
  signal slv_reg13   : std_logic_vector(C_SLV_DWIDTH-1 downto 0); --Data4  (bus driven)   (bus RW)
  signal slv_reg14   : std_logic_vector(C_SLV_DWIDTH-1 downto 0); --Data5  (bus driven)   (bus RW)
  signal slv_reg15   : std_logic_vector(C_SLV_DWIDTH-1 downto 0); --Data6  (bus driven)   (bus RW)
  signal slv_reg16   : std_logic_vector(C_SLV_DWIDTH-1 downto 0); --Data7  (bus driven)   (bus RW)
  signal slv_reg17   : std_logic_vector(C_SLV_DWIDTH-1 downto 0); --Data8  (bus driven)   (bus RW)
  signal slv_reg18   : std_logic_vector(C_SLV_DWIDTH-1 downto 0); --Data9  (bus driven)   (bus RW)
  signal slv_reg19   : std_logic_vector(C_SLV_DWIDTH-1 downto 0); --Data10 (bus driven)   (bus RW)
  signal slv_reg20   : std_logic_vector(C_SLV_DWIDTH-1 downto 0); --Data11 (bus driven)   (bus RW)
  signal slv_reg21   : std_logic_vector(C_SLV_DWIDTH-1 downto 0); --Data12 (bus driven)   (bus RW)
  signal slv_reg22   : std_logic_vector(C_SLV_DWIDTH-1 downto 0); --Data13 (bus driven)   (bus RW)
  signal slv_reg23   : std_logic_vector(C_SLV_DWIDTH-1 downto 0); --Data14 (bus driven)   (bus RW)
  signal slv_reg24   : std_logic_vector(C_SLV_DWIDTH-1 downto 0); --Data15 (bus driven)   (bus RW)
  signal slv_reg25                      : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
  signal slv_reg26                      : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
  signal slv_reg27                      : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
  signal slv_reg28                      : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
  signal slv_reg29                      : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
  signal slv_reg30_state                : std_logic_vector(C_SLV_DWIDTH-1 downto 0);  -- Current state (user_logic driven) (bus RO)
  signal slv_reg31                      : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
  signal slv_reg_write_sel              : std_logic_vector(31 downto 0);
  signal slv_reg_read_sel               : std_logic_vector(31 downto 0);
  signal slv_ip2bus_data                : std_logic_vector(C_SLV_DWIDTH-1 downto 0);
  signal slv_read_ack                   : std_logic;
  signal slv_write_ack                  : std_logic;

begin

  --USER logic implementation added here

  ------------------------------------------
  -- Example code to read/write user logic slave model s/w accessible registers
  -- 
  -- Note:
  -- The example code presented here is to show you one way of reading/writing
  -- software accessible registers implemented in the user logic slave model.
  -- Each bit of the Bus2IP_WrCE/Bus2IP_RdCE signals is configured to correspond
  -- to one software accessible register by the top level template. For example,
  -- if you have four 32 bit software accessible registers in the user logic,
  -- you are basically operating on the following memory mapped registers:
  -- 
  --    Bus2IP_WrCE/Bus2IP_RdCE   Memory Mapped Register
  --                     "1000"   C_BASEADDR + 0x0
  --                     "0100"   C_BASEADDR + 0x4
  --                     "0010"   C_BASEADDR + 0x8
  --                     "0001"   C_BASEADDR + 0xC
  -- 
  ------------------------------------------
  slv_reg_write_sel <= Bus2IP_WrCE(31 downto 0);
  slv_reg_read_sel  <= Bus2IP_RdCE(31 downto 0);
  slv_write_ack     <= Bus2IP_WrCE(0) or Bus2IP_WrCE(1) or Bus2IP_WrCE(2) or Bus2IP_WrCE(3) or Bus2IP_WrCE(4) or Bus2IP_WrCE(5) or Bus2IP_WrCE(6) or Bus2IP_WrCE(7) or Bus2IP_WrCE(8) or Bus2IP_WrCE(9) or Bus2IP_WrCE(10) or Bus2IP_WrCE(11) or Bus2IP_WrCE(12) or Bus2IP_WrCE(13) or Bus2IP_WrCE(14) or Bus2IP_WrCE(15) or Bus2IP_WrCE(16) or Bus2IP_WrCE(17) or Bus2IP_WrCE(18) or Bus2IP_WrCE(19) or Bus2IP_WrCE(20) or Bus2IP_WrCE(21) or Bus2IP_WrCE(22) or Bus2IP_WrCE(23) or Bus2IP_WrCE(24) or Bus2IP_WrCE(25) or Bus2IP_WrCE(26) or Bus2IP_WrCE(27) or Bus2IP_WrCE(28) or Bus2IP_WrCE(29) or Bus2IP_WrCE(30) or Bus2IP_WrCE(31);
  slv_read_ack      <= Bus2IP_RdCE(0) or Bus2IP_RdCE(1) or Bus2IP_RdCE(2) or Bus2IP_RdCE(3) or Bus2IP_RdCE(4) or Bus2IP_RdCE(5) or Bus2IP_RdCE(6) or Bus2IP_RdCE(7) or Bus2IP_RdCE(8) or Bus2IP_RdCE(9) or Bus2IP_RdCE(10) or Bus2IP_RdCE(11) or Bus2IP_RdCE(12) or Bus2IP_RdCE(13) or Bus2IP_RdCE(14) or Bus2IP_RdCE(15) or Bus2IP_RdCE(16) or Bus2IP_RdCE(17) or Bus2IP_RdCE(18) or Bus2IP_RdCE(19) or Bus2IP_RdCE(20) or Bus2IP_RdCE(21) or Bus2IP_RdCE(22) or Bus2IP_RdCE(23) or Bus2IP_RdCE(24) or Bus2IP_RdCE(25) or Bus2IP_RdCE(26) or Bus2IP_RdCE(27) or Bus2IP_RdCE(28) or Bus2IP_RdCE(29) or Bus2IP_RdCE(30) or Bus2IP_RdCE(31);

  -- implement slave model software accessible register(s)
  SLAVE_REG_WRITE_PROC : process( Bus2IP_Clk ) is
  begin

    if Bus2IP_Clk'event and Bus2IP_Clk = '1' then
      if Bus2IP_Resetn = '0' then
        bus_slv_reg0 <= (others => '0');
        bus_slv_reg1 <= (others => '0');
        bus_slv_reg2 <= (others => '0');
        bus_slv_reg3 <= (others => '0');
		--slv_reg4_h0 <= (others => '0');
		--slv_reg5_h1 <= (others => '0');
		--slv_reg6_h2 <= (others => '0');
		--slv_reg7_h3 <= (others => '0');
		--slv_reg8_h4 <= (others => '0');
        slv_reg9  <= (others => '0');
        slv_reg10 <= (others => '0');
        slv_reg11 <= (others => '0');
        slv_reg12 <= (others => '0');
        slv_reg13 <= (others => '0');
        slv_reg14 <= (others => '0');
        slv_reg15 <= (others => '0');
        slv_reg16 <= (others => '0');
        slv_reg17 <= (others => '0');
        slv_reg18 <= (others => '0');
        slv_reg19 <= (others => '0');
        slv_reg20 <= (others => '0');
        slv_reg21 <= (others => '0');
        slv_reg22 <= (others => '0');
        slv_reg23 <= (others => '0');
        slv_reg24 <= (others => '0');
        slv_reg25 <= (others => '0');
        slv_reg26 <= (others => '0');
        slv_reg27 <= (others => '0');
        slv_reg28 <= (others => '0');
        slv_reg29 <= (others => '0');
        slv_reg31 <= (others => '0');
      else
        case slv_reg_write_sel is
          when "10000000000000000000000000000000" =>
            for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
              if ( Bus2IP_BE(byte_index) = '1' ) then
                bus_slv_reg0(byte_index*8+7 downto byte_index*8) <= Bus2IP_Data(byte_index*8+7 downto byte_index*8);
              end if;
            end loop;
          when "01000000000000000000000000000000" =>
            for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
              if ( Bus2IP_BE(byte_index) = '1' ) then
                bus_slv_reg1(byte_index*8+7 downto byte_index*8) <= Bus2IP_Data(byte_index*8+7 downto byte_index*8);
              end if;
            end loop;
          when "00100000000000000000000000000000" =>
            for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
              if ( Bus2IP_BE(byte_index) = '1' ) then
                bus_slv_reg2(byte_index*8+7 downto byte_index*8) <= Bus2IP_Data(byte_index*8+7 downto byte_index*8);
              end if;
            end loop;
          when "00010000000000000000000000000000" =>
            for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
              if ( Bus2IP_BE(byte_index) = '1' ) then
                bus_slv_reg3(byte_index*8+7 downto byte_index*8) <= Bus2IP_Data(byte_index*8+7 downto byte_index*8);
              end if;
            end loop;
-- read only
--          when "00001000000000000000000000000000" =>
--            for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
--              if ( Bus2IP_BE(byte_index) = '1' ) then
--                slv_reg4_h0(byte_index*8+7 downto byte_index*8) <= Bus2IP_Data(byte_index*8+7 downto byte_index*8);
--              end if;
--            end loop;
--          when "00000100000000000000000000000000" =>
--            for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
--              if ( Bus2IP_BE(byte_index) = '1' ) then
--                slv_reg5_h1(byte_index*8+7 downto byte_index*8) <= Bus2IP_Data(byte_index*8+7 downto byte_index*8);
--              end if;
--            end loop;
--          when "00000010000000000000000000000000" =>
--            for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
--              if ( Bus2IP_BE(byte_index) = '1' ) then
--                slv_reg6_h2(byte_index*8+7 downto byte_index*8) <= Bus2IP_Data(byte_index*8+7 downto byte_index*8);
--              end if;
--            end loop;
--          when "00000001000000000000000000000000" =>
--            for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
--              if ( Bus2IP_BE(byte_index) = '1' ) then
--                slv_reg7_h3(byte_index*8+7 downto byte_index*8) <= Bus2IP_Data(byte_index*8+7 downto byte_index*8);
--              end if;
--            end loop;
--          when "00000000100000000000000000000000" =>
--            for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
--              if ( Bus2IP_BE(byte_index) = '1' ) then
--                slv_reg8_h4(byte_index*8+7 downto byte_index*8) <= Bus2IP_Data(byte_index*8+7 downto byte_index*8);
--              end if;
--            end loop;
          when "00000000010000000000000000000000" =>
            for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
              if ( Bus2IP_BE(byte_index) = '1' ) then
                slv_reg9(byte_index*8+7 downto byte_index*8) <= Bus2IP_Data(byte_index*8+7 downto byte_index*8);
              end if;
            end loop;
          when "00000000001000000000000000000000" =>
            for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
              if ( Bus2IP_BE(byte_index) = '1' ) then
                slv_reg10(byte_index*8+7 downto byte_index*8) <= Bus2IP_Data(byte_index*8+7 downto byte_index*8);
              end if;
            end loop;
          when "00000000000100000000000000000000" =>
            for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
              if ( Bus2IP_BE(byte_index) = '1' ) then
                slv_reg11(byte_index*8+7 downto byte_index*8) <= Bus2IP_Data(byte_index*8+7 downto byte_index*8);
              end if;
            end loop;
          when "00000000000010000000000000000000" =>
            for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
              if ( Bus2IP_BE(byte_index) = '1' ) then
                slv_reg12(byte_index*8+7 downto byte_index*8) <= Bus2IP_Data(byte_index*8+7 downto byte_index*8);
              end if;
            end loop;
          when "00000000000001000000000000000000" =>
            for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
              if ( Bus2IP_BE(byte_index) = '1' ) then
                slv_reg13(byte_index*8+7 downto byte_index*8) <= Bus2IP_Data(byte_index*8+7 downto byte_index*8);
              end if;
            end loop;
          when "00000000000000100000000000000000" =>
            for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
              if ( Bus2IP_BE(byte_index) = '1' ) then
                slv_reg14(byte_index*8+7 downto byte_index*8) <= Bus2IP_Data(byte_index*8+7 downto byte_index*8);
              end if;
            end loop;
          when "00000000000000010000000000000000" =>
            for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
              if ( Bus2IP_BE(byte_index) = '1' ) then
                slv_reg15(byte_index*8+7 downto byte_index*8) <= Bus2IP_Data(byte_index*8+7 downto byte_index*8);
              end if;
            end loop;
          when "00000000000000001000000000000000" =>
            for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
              if ( Bus2IP_BE(byte_index) = '1' ) then
                slv_reg16(byte_index*8+7 downto byte_index*8) <= Bus2IP_Data(byte_index*8+7 downto byte_index*8);
              end if;
            end loop;
          when "00000000000000000100000000000000" =>
            for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
              if ( Bus2IP_BE(byte_index) = '1' ) then
                slv_reg17(byte_index*8+7 downto byte_index*8) <= Bus2IP_Data(byte_index*8+7 downto byte_index*8);
              end if;
            end loop;
          when "00000000000000000010000000000000" =>
            for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
              if ( Bus2IP_BE(byte_index) = '1' ) then
                slv_reg18(byte_index*8+7 downto byte_index*8) <= Bus2IP_Data(byte_index*8+7 downto byte_index*8);
              end if;
            end loop;
          when "00000000000000000001000000000000" =>
            for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
              if ( Bus2IP_BE(byte_index) = '1' ) then
                slv_reg19(byte_index*8+7 downto byte_index*8) <= Bus2IP_Data(byte_index*8+7 downto byte_index*8);
              end if;
            end loop;
          when "00000000000000000000100000000000" =>
            for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
              if ( Bus2IP_BE(byte_index) = '1' ) then
                slv_reg20(byte_index*8+7 downto byte_index*8) <= Bus2IP_Data(byte_index*8+7 downto byte_index*8);
              end if;
            end loop;
          when "00000000000000000000010000000000" =>
            for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
              if ( Bus2IP_BE(byte_index) = '1' ) then
                slv_reg21(byte_index*8+7 downto byte_index*8) <= Bus2IP_Data(byte_index*8+7 downto byte_index*8);
              end if;
            end loop;
          when "00000000000000000000001000000000" =>
            for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
              if ( Bus2IP_BE(byte_index) = '1' ) then
                slv_reg22(byte_index*8+7 downto byte_index*8) <= Bus2IP_Data(byte_index*8+7 downto byte_index*8);
              end if;
            end loop;
          when "00000000000000000000000100000000" =>
            for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
              if ( Bus2IP_BE(byte_index) = '1' ) then
                slv_reg23(byte_index*8+7 downto byte_index*8) <= Bus2IP_Data(byte_index*8+7 downto byte_index*8);
              end if;
            end loop;
          when "00000000000000000000000010000000" =>
            for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
              if ( Bus2IP_BE(byte_index) = '1' ) then
                slv_reg24(byte_index*8+7 downto byte_index*8) <= Bus2IP_Data(byte_index*8+7 downto byte_index*8);
              end if;
            end loop;
          when "00000000000000000000000001000000" =>
            for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
              if ( Bus2IP_BE(byte_index) = '1' ) then
                slv_reg25(byte_index*8+7 downto byte_index*8) <= Bus2IP_Data(byte_index*8+7 downto byte_index*8);
              end if;
            end loop;
          when "00000000000000000000000000100000" =>
            for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
              if ( Bus2IP_BE(byte_index) = '1' ) then
                slv_reg26(byte_index*8+7 downto byte_index*8) <= Bus2IP_Data(byte_index*8+7 downto byte_index*8);
              end if;
            end loop;
          when "00000000000000000000000000010000" =>
            for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
              if ( Bus2IP_BE(byte_index) = '1' ) then
                slv_reg27(byte_index*8+7 downto byte_index*8) <= Bus2IP_Data(byte_index*8+7 downto byte_index*8);
              end if;
            end loop;
          when "00000000000000000000000000001000" =>
            for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
              if ( Bus2IP_BE(byte_index) = '1' ) then
                slv_reg28(byte_index*8+7 downto byte_index*8) <= Bus2IP_Data(byte_index*8+7 downto byte_index*8);
              end if;
            end loop;
          when "00000000000000000000000000000100" =>
            for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
              if ( Bus2IP_BE(byte_index) = '1' ) then
                slv_reg29(byte_index*8+7 downto byte_index*8) <= Bus2IP_Data(byte_index*8+7 downto byte_index*8);
              end if;
            end loop;
          when "00000000000000000000000000000001" =>
            for byte_index in 0 to (C_SLV_DWIDTH/8)-1 loop
              if ( Bus2IP_BE(byte_index) = '1' ) then
                slv_reg31(byte_index*8+7 downto byte_index*8) <= Bus2IP_Data(byte_index*8+7 downto byte_index*8);
              end if;
            end loop;
          when others => null;
        end case;
      end if;
    end if;

  end process SLAVE_REG_WRITE_PROC;

  -- implement slave model software accessible register(s) read mux
  SLAVE_REG_READ_PROC : process( slv_reg_read_sel, slv_reg0_rst,
	  slv_reg1_status, slv_reg2_startBlk, slv_reg3_finished, slv_reg4_h0,
	  slv_reg5_h1, slv_reg6_h2, slv_reg7_h3, slv_reg8_h4, slv_reg9, slv_reg10,
	  slv_reg11, slv_reg12, slv_reg13, slv_reg14, slv_reg15, slv_reg16,
	  slv_reg17, slv_reg18, slv_reg19, slv_reg20, slv_reg21, slv_reg22,
	  slv_reg23, slv_reg24, slv_reg25, slv_reg26, slv_reg27, slv_reg28,
	  slv_reg29, slv_reg30_state, slv_reg31 ) is
  begin

    case slv_reg_read_sel is
      when "10000000000000000000000000000000" => slv_ip2bus_data <= slv_reg0_rst;
      when "01000000000000000000000000000000" => slv_ip2bus_data <= slv_reg1_status;
      when "00100000000000000000000000000000" => slv_ip2bus_data <= slv_reg2_startBlk;
      when "00010000000000000000000000000000" => slv_ip2bus_data <= slv_reg3_finished;
      when "00001000000000000000000000000000" => slv_ip2bus_data <= slv_reg4_h0;
      when "00000100000000000000000000000000" => slv_ip2bus_data <= slv_reg5_h1;
      when "00000010000000000000000000000000" => slv_ip2bus_data <= slv_reg6_h2;
      when "00000001000000000000000000000000" => slv_ip2bus_data <= slv_reg7_h3;
      when "00000000100000000000000000000000" => slv_ip2bus_data <= slv_reg8_h4;
      when "00000000010000000000000000000000" => slv_ip2bus_data <= slv_reg9;
      when "00000000001000000000000000000000" => slv_ip2bus_data <= slv_reg10;
      when "00000000000100000000000000000000" => slv_ip2bus_data <= slv_reg11;
      when "00000000000010000000000000000000" => slv_ip2bus_data <= slv_reg12;
      when "00000000000001000000000000000000" => slv_ip2bus_data <= slv_reg13;
      when "00000000000000100000000000000000" => slv_ip2bus_data <= slv_reg14;
      when "00000000000000010000000000000000" => slv_ip2bus_data <= slv_reg15;
      when "00000000000000001000000000000000" => slv_ip2bus_data <= slv_reg16;
      when "00000000000000000100000000000000" => slv_ip2bus_data <= slv_reg17;
      when "00000000000000000010000000000000" => slv_ip2bus_data <= slv_reg18;
      when "00000000000000000001000000000000" => slv_ip2bus_data <= slv_reg19;
      when "00000000000000000000100000000000" => slv_ip2bus_data <= slv_reg20;
      when "00000000000000000000010000000000" => slv_ip2bus_data <= slv_reg21;
      when "00000000000000000000001000000000" => slv_ip2bus_data <= slv_reg22;
      when "00000000000000000000000100000000" => slv_ip2bus_data <= slv_reg23;
      when "00000000000000000000000010000000" => slv_ip2bus_data <= slv_reg24;
      when "00000000000000000000000001000000" => slv_ip2bus_data <= slv_reg25;
      when "00000000000000000000000000100000" => slv_ip2bus_data <= slv_reg26;
      when "00000000000000000000000000010000" => slv_ip2bus_data <= slv_reg27;
      when "00000000000000000000000000001000" => slv_ip2bus_data <= slv_reg28;
      when "00000000000000000000000000000100" => slv_ip2bus_data <= slv_reg29;
      when "00000000000000000000000000000010" => slv_ip2bus_data <= slv_reg30_state;
      when "00000000000000000000000000000001" => slv_ip2bus_data <= slv_reg31;
      when others => slv_ip2bus_data <= (others => '0');
    end case;

  end process SLAVE_REG_READ_PROC;

  ------------------------------------------
  -- Example code to drive IP to Bus signals
  ------------------------------------------
  IP2Bus_Data  <= slv_ip2bus_data when slv_read_ack = '1' else
                  (others => '0');

  IP2Bus_WrAck <= slv_write_ack;
  IP2Bus_RdAck <= slv_read_ack;
  IP2Bus_Error <= '0';

  sha1_hw : sha1
  port map
  (
	sha_msg		=> ul_msg,
	sha_init	=> ul_init,
	sha_load	=> ul_load,
	sha_hash	=> ul_hash,
	sha_valid	=> ul_valid,
	sha_clk		=> Bus2IP_Clk,
	sha_reset	=> ul_reset
  );
  
  ---------------------------------------------------------
  -- FSM to glue together processor interface to custom algo
  ---------------------------------------------------------
	user_fsm : process(Bus2IP_Clk)
	begin
		if Bus2IP_Clk'event and Bus2IP_Clk = '1' then
			-- Defaults:
			ul_load <= '0';
			ul_msg  <= (others => '0');

			if Bus2IP_Resetn = '0' then
				algoState		<= algoWait;
				input_rdy		<= '0';
				hash_rdy		<= '0';
				hash_busy		<= '0';
				local_rst       <= (others => '0');
				slv_reg4_h0     <= (others => '0');
				slv_reg5_h1     <= (others => '0');
				slv_reg6_h2     <= (others => '0');
				slv_reg7_h3     <= (others => '0');
				slv_reg8_h4     <= (others => '0');  
			else
				case algoState is
					when algoWait =>
						input_rdy	<= '1';
						hash_busy <= '0';
						if slv_reg0_rst = x"00000001" then     -- begin hash!
							algoState <= dataXfer;
							ld_map <= "10000000000000000";
						end if;
					when dataXfer =>
						ul_load		<= '1';
						hash_busy	<= '1';
						input_rdy	<= '0';		-- We no longer accept input data.
						case ld_map is
							when "10000000000000000" =>
								ul_msg <= slv_reg9;
							when "01000000000000000" =>
								ul_msg <= slv_reg10;
							when "00100000000000000" =>
								ul_msg <= slv_reg11;
							when "00010000000000000" =>
								ul_msg <= slv_reg12;
							when "00001000000000000" =>
								ul_msg <= slv_reg13;
							when "00000100000000000" =>
								ul_msg <= slv_reg14;
							when "00000010000000000" =>
								ul_msg <= slv_reg15;
							when "00000001000000000" =>
								ul_msg <= slv_reg16;
							when "00000000100000000" =>
								ul_msg <= slv_reg17;
							when "00000000010000000" =>
								ul_msg <= slv_reg18;
							when "00000000001000000" =>
								ul_msg <= slv_reg19;
							when "00000000000100000" =>
								ul_msg <= slv_reg20;
							when "00000000000010000" =>
								ul_msg <= slv_reg21;
							when "00000000000001000" =>
								ul_msg <= slv_reg22;
							when "00000000000000100" =>
								ul_msg <= slv_reg23;
							when "00000000000000010" =>
								ul_msg <= slv_reg24;
							when "00000000000000001" =>
								ul_load <= '0';
								algoState <= hashWait;
							when others =>
								ul_load <= '0';
								algoState <= hashWait;
							end case;
							ld_map <= '0' & ld_map(ld_map'length-1 downto 1);
					when hashWait =>
						input_rdy <= '1';
						if ul_valid = '1' then
							algoState <= saveHash;
							ld_map <= "00000000000100000";
						end if;
					when saveHash =>
						case ld_map is
							when "00000000000100000" =>
								slv_reg4_h0 <= ul_hash; 
							when "00000000000010000" =>
								slv_reg5_h1 <= ul_hash; 
							when "00000000000001000" =>
								slv_reg6_h2 <= ul_hash; 
							when "00000000000000100" =>
								slv_reg7_h3 <= ul_hash; 
							when "00000000000000010" =>
								slv_reg8_h4 <= ul_hash; 
							when "00000000000000001" =>
								algoState <= algoWait;
								hash_rdy <= '1';
							when others =>
								hash_rdy <= '1';
								algoState <= algoWait;
						end case;
						ld_map <= '0' & ld_map(ld_map'length-1 downto 1);
					when others =>
						algoState <= algoWait;
				end case;
			end if;  --if Bus2IP_Resetn = '0' then
		end if;  --if Bus2IP_Clk'event and Bus2IP_Clk = '1' then
	end process user_fsm;

-- Status is comprised of the hash ready and input ready bits:
local_status <= "00000000" & "00000000" & "00000000" & "00000" & hash_busy & hash_rdy & input_rdy;

ul_reset <= not Bus2IP_Resetn;


-- Allow either the bus or the internal logic to set bus reg value
slv_reg0_rst      <= local_rst      or bus_slv_reg0;
slv_reg1_status   <= local_status   or bus_slv_reg1;
slv_reg2_startBlk <= local_startBlk or bus_slv_reg2;
slv_reg3_finished <= local_finished or bus_slv_reg3;

  -- sha module connections  TODO
--  sha_m    <= slv_reg8_dataIn;
--  sha_ld   <= sha_ld_reg;
--  sha_init <= sha_init_reg;
--  sha_clk  <= Bus2IP_Clk;
--  sha_rst  <= Bus2IP_Resetn;

end IMP;
