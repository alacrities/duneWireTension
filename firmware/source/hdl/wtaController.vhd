--------------------------------------------------------------------------------
-- Title       : <Title Block>
-- Project     : Default Project Name
--------------------------------------------------------------------------------
-- File        : wtaController.vhd
-- Author      : User Name <user.email@user.company.com>
-- Company     : User Company Name
-- Created     : Thu May  2 11:04:21 2019
-- Last update : Sun Jul 14 18:51:00 2019
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

		stimTime     : in unsigned(31 downto 0) := (others => '0');
		adc_nSamples : in unsigned(15 downto 0) := (others => '0');


		ctrlStart : in std_logic := '0';

		freqSet       : out unsigned(31 downto 0) := (others => '0');
		acStim_enable : out std_logic             := '0';

		acStim_nPeriod : in unsigned(31 downto 0) := (others => '0');
		adcHScale      : in unsigned(4 downto 0)  := (others => '0');

		adcAutoDc_af     : in  std_logic           := '0';
		adcAutoDc_wen    : out std_logic           := '0';
		adcAutoDc_data   : in  signed(15 downto 0) := (others => '0');
		adcAutoDC_dValid : in  std_logic           := '0';

		mainsAvg_nAvg      : in  unsigned(7 downto 0)  := (others => '0');
		adcAutoDc_headData : out unsigned(15 downto 0) := (others => '0');

		mainsTrig         : in  std_logic             := '0';
		mainsMinus_enable : in  std_logic             := '0';
		mainsMinus_data   : out signed(15 downto 0) := (others => '0');
		mainsMinus_wen    : out std_logic             := '0';

		busy  : out std_logic := '0';
		reset : in  std_logic := '0';
		clk   : in  std_logic := '0'
	);
end entity wtaController;
architecture rtl of wtaController is

	COMPONENT blkMem_mainsAvg
		PORT (
			clka      : IN  STD_LOGIC;
			rsta      : IN  STD_LOGIC;
			wea       : IN  STD_LOGIC_VECTOR(0 DOWNTO 0);
			addra     : IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
			dina      : IN  STD_LOGIC_VECTOR(23 DOWNTO 0);
			douta     : OUT STD_LOGIC_VECTOR(23 DOWNTO 0);
			rsta_busy : OUT STD_LOGIC
		);
	END COMPONENT;

type ctrlState_type is (idle_s, stimPrep_s, stimHeader1_s, stimHeader2_s, stimHeader3_s, stimHeader4_s,mainsSync_s, mainsAvgLoop_s, mainsAvgInc_s, stimRun_s, adcReadout_s, adcDownSample_s);
signal ctrlState, ctrlState_next : ctrlState_type := idle_s;

signal stimTimeCnt   : unsigned(31 downto 0) := (others => '0');
signal adc_wstrbCnt  : unsigned(31 downto 0) := (others => '0');
signal nDwnSample    : unsigned(31 downto 0) := (others => '0');
signal dwnSampleCnt  : unsigned(31 downto 0) := (others => '0');
signal ctrlStart_del : std_logic             := '0';

signal adc_nSamplesDone : boolean   := false;
signal mainsAvg_active  : std_logic := '0';
signal scanDone         : boolean   := false;

signal mainsAvg_cnt     : unsigned(7 downto 0)          := (others => '0');
signal mainsAvgMem_din  : signed(23 downto 0)           := (others => '0');
signal mainsAvgMem_dout : std_logic_vector(23 downto 0) := (others => '0');
signal mainsAvgMem_addr : std_logic_vector(15 downto 0) := (others => '0');
signal mainsAvgMem_wen  : std_logic                     := '0';

signal mainsAvgMem_rsta      : std_logic := '0';
signal mainsAvgMem_rsta_busy : std_logic := '0';

begin
ctrlState_seq : process (clk)
begin
	if rising_edge(clk) then
		stimTimeCnt <= (others => '0'); --reset by default

		if reset then
			ctrlState <= idle_s;
		else
			ctrlState <= ctrlState_next;
		end if;
		case (ctrlState) is

			when idle_s => --test is done and set freq to the beginning
				freqSet       <= x"000"& freqMin & x"0";
				ctrlStart_del <= ctrlStart;
				--turn off stimulus 
				acStim_enable <= '0';

			when stimPrep_s => -- increment frequency and reset counters
				               -- the freqSet will need ~4 clock cycles to update the period counter
				freqSet      <= freqSet+freqStep;
				adc_wstrbCnt <= (others => '0');
				mainsAvgMem_addr <= (others => '0');
				--change to reset only on freq change
				mainsAvg_cnt <= (others => '0');

			when stimRun_s => -- count the number of clock cycles we stim before ADC readout
				stimTimeCnt   <= stimTimeCnt+1;
				acStim_enable <= not mainsAvg_active;

			when adcReadout_s => -- count the number of samples that go into the readout FIFO
				if adcAutoDC_dValid then
					adc_wstrbCnt <= adc_wstrbCnt+1;
					mainsAvgMem_addr <= mainsAvgMem_addr+1;
					dwnSampleCnt <= (others => '0'); -- reset the downsample count
				end if;

			when mainsAvgInc_s => -- count the number of samples that go into the readout FIFO
				mainsAvg_cnt <= mainsAvg_cnt+1;
				adc_wstrbCnt <= (others => '0'); -- reset the ADC sample counter
				mainsAvgMem_addr <= (others => '0');
			when mainsAvgLoop_s =>

			when adcDownSample_s => -- count the down sample
				if adcAutoDC_dValid then
					dwnSampleCnt <= dwnSampleCnt+1;
					-- mainsAvgMem_addr follows adc_wstrbCnt 
					-- and also gets incremented in down-sample
					mainsAvgMem_addr <= mainsAvgMem_addr+1;
				end if;

			when others =>
				null;
		end case;
	end if;
end process ctrlState_seq;

ctrlState_comb : process (all)
begin
	scanDone               <= freqSet > (freqMax & x"0");
	adc_nSamplesDone       <= adc_wstrbCnt = adc_nSamples;
	mainsAvg_active        <= '1' when mainsMinus_enable = '1' and (mainsAvg_cnt < mainsAvg_nAvg);
	ctrlState_next         <= ctrlState;
	adcAutoDc_wen          <= '0';
	adcAutoDc_headData(15) <= '0';
	busy                   <= '1';
	mainsAvgMem_rsta       <= '0';
	nDwnSample             <= shift_right(acStim_nPeriod,to_integer(adcHScale));
	case (ctrlState) is

		when idle_s =>
			if ctrlStart and not ctrlStart_del then
				ctrlState_next <= stimPrep_s;
			end if;
			busy <= '0';

		when stimPrep_s => --wait for FIFO to be ready
			if not adcAutoDc_af then
				ctrlState_next <= stimHeader1_s;
			end if;
			mainsAvgMem_rsta <= '1';
		when stimHeader1_s =>              -- write header info
			adcAutoDc_headData <= x"CAFE"; -- CAFE with header flag
			ctrlState_next     <= stimHeader2_s;

		when stimHeader2_s =>
			adcAutoDc_headData <= x"8" & acStim_nPeriod(23 downto 12);
			ctrlState_next     <= stimHeader3_s;

		when stimHeader3_s =>
			adcAutoDc_headData <= x"8" & acStim_nPeriod(11 downto 0);
			ctrlState_next     <= stimHeader4_s;

		when stimHeader4_s =>
			adcAutoDc_headData <= '1' & nDwnSample(14 downto 0);
			ctrlState_next     <= stimRun_s;

		when stimRun_s => -- wait before ADC readout

			if stimTime = stimTimeCnt then
				if mainsMinus_enable then
					ctrlState_next <= mainsSync_s;
				else
					ctrlState_next <= adcReadout_s;
				end if;
			end if;

		when mainsSync_s => -- wait before ADC readout
			if mainsTrig and not mainsAvgMem_rsta_busy then
				ctrlState_next <= adcReadout_s;
			end if;

		when adcReadout_s =>
			adcAutoDc_wen <= '1';       --0'when mainsAvg_active else '1';
			if adc_nSamplesDone then    --we have all of the contiguous samples
				if mainsAvg_active then -- we have finished sampling this freq and can move on
					ctrlState_next <= mainsAvgInc_s;
				else
					if scanDone then
						ctrlState_next <= idle_s;
					else
						ctrlState_next <= stimPrep_s;
					end if;
				end if;
			elsif adcAutoDC_dValid then
				ctrlState_next <= adcDownSample_s;
			end if;

		when mainsAvgInc_s =>
			-- update the number of averaging loops
			-- the mainsAvgLoop_s state needs the updated value
			ctrlState_next <= mainsAvgLoop_s;

		when mainsAvgLoop_s =>
			if mainsAvg_active then -- still averaging
				ctrlState_next <= mainsSync_s;
			else -- finished averaging now get the stimulus enabled samples
				ctrlState_next <= stimRun_s;
			end if;

		when adcDownSample_s =>
			if dwnSampleCnt = nDwnSample then
				ctrlState_next <= adcReadout_s;
			end if;

		when others =>
			ctrlState_next <= idle_s;
			null;
	end case;
end process ctrlState_comb;

compute_avg : process (clk)
begin
	if rising_edge(clk) then
	if mainsAvg_cnt = x"00" then
		mainsAvgMem_din <= resize(adcAutoDc_data,mainsAvgMem_din'length);
		else
		mainsAvgMem_din <= signed(mainsAvgMem_dout) + resize(adcAutoDc_data,mainsAvgMem_din'length);
	end if;
		--mainsAvgMem_din <= signed(mainsAvgMem_dout) + adcAutoDc_data;
		--mainsAvgMem_wen <= adcAutoDC_dValid and mainsAvg_active;
		--mainsAvgMem_wen <= adcAutoDc_wen and adcAutoDC_dValid and mainsAvg_active;
	
		-- collect samples once for all frequencies 
		mainsAvgMem_wen <= adcAutoDC_dValid and mainsAvg_active;
		--mainsAvgMem_addr  <= std_logic_vector(adc_wstrbCnt(8 downto 0));

		-- mainsMinus_data <= adcAutoDc_data - mainsAvgMem_dout(18 downto 3);
		-- temp just watch avg build.
		-- mainsMinus_wen <= adcAutoDC_dValid and not mainsAvg_active and adcAutoDc_wen;
		--mainsMinus_data <= unsigned(mainsAvgMem_dout(18 downto 3));
		--mainsMinus_wen <= adcAutoDC_dValid and adcAutoDc_wen;
		--mainsMinus_data(10)  <= '1' when ctrlState = idle_s else '0';
		--mainsMinus_data(11)  <= '1' when ctrlState = stimPrep_s else '0';
		--mainsMinus_data(12)  <= '1' when ctrlState = stimRun_s else '0';
		--mainsMinus_data(13)  <= '1' when ctrlState = mainsSync_s else '0';
		--mainsMinus_data(14)  <= '1' when ctrlState = adcReadout_s else '0';
		--mainsMinus_data(15)  <= '1' when ctrlState = mainsAvgLoop_s else '0';
		--
		--mainsMinus_data(9 downto 0) <= adc_wstrbCnt(9 downto 0);
		--mainsMinus_data <= adcAutoDc_data;
		--mainsMinus_wen <= adcAutoDc_wen and adcAutoDC_dValid and mainsAvg_active;
		--mainsMinus_data <= unsigned(mainsAvgMem_dout(18 downto 3));
		--mainsMinus_data(8 downto 0) <= adcAutoDc_data(8 downto 0);
		if mainsAvg_active then
			mainsMinus_data <= signed(mainsAvgMem_dout(18 downto 3));
		else
			mainsMinus_data <= adcAutoDc_data - signed(mainsAvgMem_dout(18 downto 3));
		end if;

		mainsMinus_wen <= adcAutoDc_wen and adcAutoDC_dValid and not mainsAvg_active;
	end if;
end process;


blkMem_mainsAvg_inst : blkMem_mainsAvg
	PORT MAP (
		clka      => clk,
		wea(0)    => mainsAvgMem_wen,
		addra     => mainsAvgMem_addr,
		dina      => std_logic_vector(mainsAvgMem_din),
		douta     => mainsAvgMem_dout,
		rsta      => mainsAvgMem_rsta,
		rsta_busy => mainsAvgMem_rsta_busy
	);

end architecture rtl;