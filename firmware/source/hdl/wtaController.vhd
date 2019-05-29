--------------------------------------------------------------------------------
-- Title       : <Title Block>
-- Project     : Default Project Name
--------------------------------------------------------------------------------
-- File        : wtaController.vhd
-- Author      : User Name <user.email@user.company.com>
-- Company     : User Company Name
-- Created     : Thu May  2 11:04:21 2019
-- Last update : Wed May 29 11:03:02 2019
-- Platform    : Default Part Number
-- Standard    : <VHDL-2008 | VHDL-2002 | VHDL-1993 | VHDL-1987>
--------------------------------------------------------------------------------
-- Copyright (c) 2019 User Company Name
-------------------------------------------------------------------------------
-- Description: 
--------------------------------------------------------------------------------
-- Revisions:  Revisions and documentation are controlled by
-- the revision control system (RCS).  The RCS should be consulted
-- on revision history.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library duneWta;
library UNISIM;
use UNISIM.VCOMPONENTS.all;

entity wtaController is
	port (
		freqMin  : in unsigned(15 downto 0) := (others => '0');
		freqMax  : in unsigned(15 downto 0) := (others => '0');
		freqStep : in unsigned(15 downto 0) := (others => '0');

		stimTime         : in unsigned(31 downto 0) := (others => '0');
		adcFifo_nSamples : in unsigned(15 downto 0) := (others => '0');


		ctrlStart : in std_logic := '0';

		freqSet       : out unsigned(31 downto 0) := (others => '0');
		acStim_enable : out std_logic             := '0';

		acStim_nPeriod : in unsigned(31 downto 0) := (others => '0');
		adcHScale : in unsigned(4 downto 0) := (others => '0');

		adcFifo_af    : in  std_logic := '0';
		adcFifo_wen   : out std_logic := '0';
		adcFifo_wstrb : in  std_logic := '0';

		adcFifo_headData  : out unsigned(15 downto 0) := (others => '0');

		busy   : out std_logic := '0';
		reset :in std_logic  :=  '0';
		clk : in std_logic := '0'
	);
end entity wtaController;
architecture rtl of wtaController is
	type ctrlState_type is (idle, stimPrep, stimHeader1, stimHeader2, stimHeader3, stimRun, adcReadout, adcDownSample);
	signal ctrlState, ctrlState_next : ctrlState_type := idle;

	signal stimTimeCnt      : unsigned(31 downto 0) := (others => '0');
	signal adcFifo_wstrbCnt : unsigned(31 downto 0) := (others => '0');
	signal nDwnSample	 : unsigned(31 downto 0) := (others => '0');
	signal dwnSampleCnt : unsigned(31 downto 0) := (others => '0');
	signal ctrlStart_del                            :std_logic := '0';

begin

	ctrlState_seq : process (clk)
	begin
		if rising_edge(clk) then

		if reset then
			ctrlState <= idle;
			else
			ctrlState <= ctrlState_next;
			end if;
			case (ctrlState) is

				when idle => --test is done and set freq to the beginning
					freqSet       <= x"000"& freqMin & x"0";
					ctrlStart_del <= ctrlStart;

				when stimPrep => -- increment frequency and reset counters
					             -- the freqSet will need ~4 clock cycles to update the period counter
					freqSet          <= freqSet+freqStep;
					stimTimeCnt      <= (others => '0');
					adcFifo_wstrbCnt <= (others => '0');

				when stimRun => -- count the number of clock cycles we stim before ADC readout
					stimTimeCnt <= stimTimeCnt+1;

				when adcReadout => -- count the number of samples that go into the readout FIFO
					if adcFifo_wstrb then
						adcFifo_wstrbCnt <= adcFifo_wstrbCnt+1;
						dwnSampleCnt <= (others => '0'); -- reset the downsample count
					end if;

				when adcDownSample => -- count the down sample
					if adcFifo_wstrb then
						dwnSampleCnt <= dwnSampleCnt+1;
					end if;

				when others =>
					null;
			end case;
		end if;
	end process ctrlState_seq;

	ctrlState_comb : process (all)
	begin
		ctrlState_next <= ctrlState;
		adcFifo_wen    <= '0';
		adcFifo_headData(15) <= '0';
		acStim_enable  <= '0';
				busy  <= '1';
				 nDwnSample <= shift_right(acStim_nPeriod,to_integer(adcHScale));
		case (ctrlState) is

			when idle =>
				if ctrlStart and not ctrlStart_del then
					ctrlState_next <= stimPrep;
				end if;
				busy  <= '0';

			when stimPrep => --wait for FIFO to be ready
				if not adcFifo_af then
					ctrlState_next <= stimHeader1;
				end if;

			when stimHeader1 => -- write header info
				adcFifo_headData <= x"CAFE";  -- CAFE with header flag
				ctrlState_next    <= stimHeader2;

			when stimHeader2 =>
				adcFifo_headData <= x"8" & acStim_nPeriod(23 downto 12);
				ctrlState_next    <= stimHeader3;

			when stimHeader3 =>
				adcFifo_headData <= x"8" & acStim_nPeriod(11 downto 0);
				ctrlState_next    <= stimRun;

			when stimRun =>  -- wait before ADC readout
				acStim_enable <= '1';
				if stimTime = stimTimeCnt then
					ctrlState_next <= adcReadout;
				end if;

			when adcReadout =>
				adcFifo_wen <= '1';
				acStim_enable <= '1';
				if adcFifo_wstrbCnt = adcFifo_nSamples then
					if freqSet < (freqMax & x"0") then
						ctrlState_next <= stimPrep;
					else
						ctrlState_next <= idle;
					end if;
				elsif adcFifo_wstrb then
					ctrlState_next <= adcDownSample;
				end if;

			when adcDownSample =>
				acStim_enable <= '1';
				if dwnSampleCnt = nDwnSample then
					ctrlState_next <= adcReadout;
				end if;

			when others =>
				ctrlState_next <= idle;
				null;
		end case;
	end process ctrlState_comb;

end architecture rtl;