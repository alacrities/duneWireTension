--------------------------------------------------------------------------------
-- Title       : <Title Block>
-- Project     : Default Project Name
--------------------------------------------------------------------------------
-- File        : wtaController.vhd
-- Author      : User Name <user.email@user.company.com>
-- Company     : User Company Name
-- Created     : Thu May  2 11:04:21 2019
-- Last update : Mon Jun 24 22:31:23 2019
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
		adc_nSamples : in unsigned(15 downto 0) := (others => '0');


		ctrlStart : in std_logic := '0';

		freqSet       : out unsigned(31 downto 0) := (others => '0');
		acStim_enable : out std_logic             := '0';

		acStim_nPeriod : in unsigned(31 downto 0) := (others => '0');
		adcHScale      : in unsigned(4 downto 0)  := (others => '0');

		adcAutoDc_af    : in  std_logic := '0';
		adcAutoDc_wen   : out std_logic := '0';
		adcAutoDC_dValid : in  std_logic := '0';

		adcAutoDc_headData : out unsigned(15 downto 0) := (others => '0');
		adcAutoDc_data : in unsigned(15 downto 0) := (others => '0');

		mainsMinus_enable : in std_logic             := '0';
		mainsMinus_data: out unsigned(15 downto 0) := (others => '0');
		mainsMinus_wen : out std_logic             := '0';

		busy  : out std_logic := '0';
		reset : in  std_logic := '0';
		clk   : in  std_logic := '0'
	);
end entity wtaController;

COMPONENT blkMem_mainsAvg
	PORT (
		clka  : IN  STD_LOGIC;
		wea   : IN  STD_LOGIC_VECTOR(0 DOWNTO 0);
		addra : IN  STD_LOGIC_VECTOR(8 DOWNTO 0);
		dina  : IN  STD_LOGIC_VECTOR(23 DOWNTO 0);
		douta : OUT STD_LOGIC_VECTOR(23 DOWNTO 0)
	);
END COMPONENT;

architecture rtl of wtaController is
	type ctrlState_type is (idle, stimPrep, stimHeader1, stimHeader2, stimHeader3, stimHeader4, mainsAvgLoop, mainsAvgInc, stimRun, adcReadout, adcDownSample);
	signal ctrlState, ctrlState_next : ctrlState_type := idle;

	signal stimTimeCnt      : unsigned(31 downto 0) := (others => '0');
	signal adc_wstrbCnt : unsigned(31 downto 0) := (others => '0');
	signal nDwnSample       : unsigned(31 downto 0) := (others => '0');
	signal dwnSampleCnt     : unsigned(31 downto 0) := (others => '0');
	signal ctrlStart_del    : std_logic             := '0';

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
					--turn off stimulus 
					acStim_enable <= '0';


				when stimPrep => -- increment frequency and reset counters
					             -- the freqSet will need ~4 clock cycles to update the period counter
					freqSet          <= freqSet+freqStep;
					stimTimeCnt      <= (others => '0');
					adc_wstrbCnt <= (others => '0');

				when stimRun => -- count the number of clock cycles we stim before ADC readout
					stimTimeCnt   <= stimTimeCnt+1;
					acStim_enable <= '1'when mainsAvg_done else '0';

				when adcReadout => -- count the number of samples that go into the readout FIFO
					if adcAutoDC_dValid then
						adc_wstrbCnt <= adc_wstrbCnt+1;
						dwnSampleCnt     <= (others => '0'); -- reset the downsample count
					end if;

				when mainsAvg_cnt => -- count the number of samples that go into the readout FIFO
					mainsAvg_cnt <= mainsAvg_cnt+1;
					adc_wstrbCnt <= (others => '0'); -- reset the ADC sample counter

				when mainsAvgLoop =>

				when adcDownSample => -- count the down sample
					if adcAutoDC_dValid then
						dwnSampleCnt <= dwnSampleCnt+1;
					end if;

				when others =>
					null;
			end case;
		end if;
	end process ctrlState_seq;

	ctrlState_comb : process (all)
	begin
		scanDone <= freqSet > (freqMax & x"0");
		adc_nSamplesDone  <= adc_wstrbCnt = adc_nSamples;
		mainsAvg_active <= mainsAvg_enable and (mainsAvg_cnt < mainsAvg_nAvg);
		ctrlState_next       <= ctrlState;
		adcAutoDc_wen          <= '0';
		adcAutoDc_headData(15) <= '0';
		busy                 <= '1';
		nDwnSample           <= shift_right(acStim_nPeriod,to_integer(adcHScale));
		case (ctrlState) is

			when idle =>
				if ctrlStart and not ctrlStart_del then
					ctrlState_next <= stimPrep;
				end if;
				busy <= '0';

			when stimPrep => --wait for FIFO to be ready
				if not adcAutoDc_af then
					ctrlState_next <= stimHeader1;
				end if;

			when stimHeader1 =>              -- write header info
				adcAutoDc_headData <= x"CAFE"; -- CAFE with header flag
				ctrlState_next   <= stimHeader2;

			when stimHeader2 =>
				adcAutoDc_headData <= x"8" & acStim_nPeriod(23 downto 12);
				ctrlState_next   <= stimHeader3;

			when stimHeader3 =>
				adcAutoDc_headData <= x"8" & acStim_nPeriod(11 downto 0);
				ctrlState_next   <= stimHeader4;

			when stimHeader4 =>
				adcAutoDc_headData <= '1' & nDwnSample(14 downto 0);
				ctrlState_next   <= stimRun;

			when stimRun => -- wait before ADC readout

				if stimTime = stimTimeCnt then
					if mainsAvg_enable then
						ctrlState_next <= mainsSync;
					else
						ctrlState_next <= adcReadout;
					end if;
				end if;

			when mainsSync => -- wait before ADC readout
				if mainsTrig then
					ctrlState_next <= adcReadout;
				end if;

			when adcReadout =>
				adcAutoDc_wen <= '1'when mainsMinus_enable or mainsAvg_done else '0';
				if adc_nSamplesDone then  --we have all of the contiguous samples
					if mainsAvg_active then -- we have finished sampling this freq and can move on
						ctrlState_next <= mainsAvgInc;
					else 
						if scanDone then
							ctrlState_next <= idle;
						else
							ctrlState_next <= stimPrep;
						end if;
					end if;
				elsif adcAutoDC_dValid then
					ctrlState_next <= adcDownSample;
				end if;

			when mainsAvgInc =>
				-- update the number of averaging loops
				-- the mainsAvgLoop state needs the updated value
					ctrlState_next <= mainsAvgLoop;

			when mainsAvgLoop =>
			if mainsAvg_active then -- still averaging
				ctrlState_next <= mainsSync;
			else -- finished averaging now get the stimulus enabled samples
				ctrlState_next <= stimRun;
			end if;

			when adcDownSample =>
				if dwnSampleCnt = nDwnSample then
					ctrlState_next <= adcReadout;
				end if;

			when others =>
				ctrlState_next <= idle;
				null;
		end case;
	end process ctrlState_comb;

	compute_avg : process (clk)
	begin
		if rising_edge(clk) then
			mainsAvgMem_din(18 downto 0) <= mainsAvgMem_dout + "000" & adcAutoDc_data;
			mainsAvgMem_wen <= adcAutoDC_dValid and mainsAvg_active;
			mainsMinus_data <= adcAutoDc_data(18 downto 3) - mainsAvgMem_dout;
			mainsMinus_wen <= adcAutoDC_dValid and not mainsAvg_active;
		end if;
	end process;


	blkMem_mainsAvg : blkMem_mainsAvg
		PORT MAP (
			clka  => clk,
			wea   => mainsAvgMem_wen,
			addra => adc_wstrbCnt(8 downto 0),
			dina  => mainsAvgMem_din,
			douta => mainsAvgMem_dout
		);

end architecture rtl;