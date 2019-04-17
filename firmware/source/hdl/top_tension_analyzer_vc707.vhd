library IEEE;
library duneWta;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
library UNISIM;
use UNISIM.VCOMPONENTS.all;
-- Custom libraries and packages:
--use duneWta.global_def.all;
--use duneWta.LPPC_CUSTOM_FN_PKG.all;

entity top_tension_analyzer_vc707 is
  port (
    acStimX200_obuf : out std_logic := '0';
    acStim_obuf     : out std_logic := '0';
    V_p             : in  std_logic;
    V_n             : in  std_logic;
    Vaux0_n         : in  std_logic;
    Vaux0_p         : in  std_logic;
    Vaux8_n         : in  std_logic;
    Vaux8_p         : in  std_logic;
    sysclk_p        : in  std_logic;
    sysclk_n        : in  std_logic
  );

end top_tension_analyzer_vc707;

architecture STRUCT of top_tension_analyzer_vc707 is
  component clk_sysclk_mmcm
    port
    ( -- Clock in ports
      -- Clock out ports
      clk_out1 : out std_logic;
      clk_out2 : out std_logic;
      clk_out3 : out std_logic;
      clk_out4 : out std_logic;
      clk_out5 : out std_logic;
      clk_out6 : out std_logic;
      -- Status and control signals
      reset     : in  std_logic;
      locked    : out std_logic;
      clk_in1_p : in  std_logic;
      clk_in1_n : in  std_logic
    );
  end component;

  COMPONENT xadc_senseWire
    PORT (
      m_axis_tvalid : OUT STD_LOGIC;
      m_axis_tready : IN  STD_LOGIC;
      m_axis_tdata  : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
      m_axis_tid    : OUT STD_LOGIC_VECTOR(4 DOWNTO 0);
      m_axis_aclk   : IN  STD_LOGIC;
      s_axis_aclk   : IN  STD_LOGIC;
      m_axis_resetn : IN  STD_LOGIC;

      vp_in  : IN STD_LOGIC;
      vn_in  : IN STD_LOGIC;
      vauxp0 : IN STD_LOGIC;
      vauxn0 : IN STD_LOGIC;
      vauxp8 : IN STD_LOGIC;
      vauxn8 : IN STD_LOGIC;

      channel_out : OUT STD_LOGIC_VECTOR(4 DOWNTO 0);
      eoc_out     : OUT STD_LOGIC;
      alarm_out   : OUT STD_LOGIC;
      eos_out     : OUT STD_LOGIC;
      busy_out    : OUT STD_LOGIC
    );
  END COMPONENT;

  COMPONENT ila_xadc

    PORT (
      clk    : IN STD_LOGIC;
      probe0 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
      probe1 : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
      probe2 : IN STD_LOGIC_VECTOR(4 DOWNTO 0)
    );
  END COMPONENT ;

  COMPONENT vio_ctrl
    PORT (
      clk        : IN  STD_LOGIC;
      probe_in0  : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
      probe_in1  : IN  STD_LOGIC_VECTOR(31 DOWNTO 0);
      probe_out0 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
      probe_out1 : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
      probe_out2 : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
      probe_out3 : OUT STD_LOGIC_VECTOR(0 DOWNTO 0)
    );
  END COMPONENT;

  signal sysclk25  : std_logic := '0';
  signal sysclk50  : std_logic := '0';
  signal sysclk100 : std_logic := '0';
  signal sysclk200 : std_logic := '0';
  signal sysclk400 : std_logic := '0';
  signal sysclk12_5 : std_logic := '0';

  signal acStimX200 : std_logic := '0';
  signal acStimX200_oddr : std_logic := '0';
  signal acStim     : std_logic := '0';
  signal acStim_oddr     : std_logic := '0';

  signal acStim_enable        : std_logic                     := '0';
  signal acStim_periodCnt     : unsigned(31 downto 0)         := (others => '0');
  signal acStim_nPeriod       : unsigned(31 downto 0)         := (others => '0');
  signal acStimX200_periodCnt : unsigned(31 downto 0)         := (others => '0');
  signal acStimX200_nPeriod   : unsigned(31 downto 0)         := (others => '0');
  signal freqReq              : std_logic_vector(31 downto 0) := (others => '0');

  signal m_axis_tvalid : std_logic;
  signal m_axis_tready : std_logic;
  signal m_axis_tdata  : std_logic_vector(15 DOWNTO 0);
  signal m_axis_tid    : std_logic_vector(4 DOWNTO 0);
  signal m_axis_resetn : std_logic;

begin
  clk_sysclk_mmcm_inst : clk_sysclk_mmcm
    port map (
      -- Clock out ports  
      clk_out1 => sysclk25,
      clk_out2 => sysclk50,
      clk_out3 => sysclk100,
      clk_out4 => sysclk200,
      clk_out5 => sysclk400,
      clk_out6 => sysclk12_5,
      -- Status and control signals                
      reset  => '0',
      locked => open,
      -- Clock in ports
      clk_in1_p => sysclk_p,
      clk_in1_n => sysclk_n
    );

--  ODDR_acStim : ODDR
--    generic map(
--      DDR_CLK_EDGE => "SAME_EDGE", -- "OPPOSITE_EDGE" or "SAME_EDGE"
--      INIT         => '0',         -- Initial value for Q port ('1' or '0')
--      SRTYPE       => "SYNC")      -- Reset Type ("ASYNC" or "SYNC")
--    port map (
--      Q  => acStim_oddr,   -- 1-bit DDR output
--      C  => sysclk200,     -- 1-bit clock input
--      CE => acStim_enable, -- 1-bit clock enable input
--      D1 => acStim,
--      D2 => '0',
--      R  => '0', -- 1-bit reset input
--      S  => '0'  -- 1-bit set input
--    );
--
--
--  ODDR_acStimx200 : ODDR
--    generic map(
--      DDR_CLK_EDGE => "SAME_EDGE", -- "OPPOSITE_EDGE" or "SAME_EDGE"
--      INIT         => '0',         -- Initial value for Q port ('1' or '0')
--      SRTYPE       => "SYNC")      -- Reset Type ("ASYNC" or "SYNC")
--    port map (
--      Q  => acStimX200_oddr, -- 1-bit DDR output
--      C  => sysclk200,       -- 1-bit clock input
--      CE => acStim_enable,   -- 1-bit clock enable input
--      D1 => acStimX200,
--      D2 => '0',
--      R  => '0', -- 1-bit reset input
--      S  => '0'  -- 1-bit set input
--    );


OBUF_acStimX200_inst : OBUF
generic map (
DRIVE => 16,
IOSTANDARD => "LVCMOS18",
SLEW => "SLOW")
port map (
O => acStimX200_obuf, -- Buffer output (connect directly to top-level port)
I => acStimX200 -- Buffer input
);

OBUF_acStim_inst : OBUF
generic map (
DRIVE => 16,
IOSTANDARD => "LVCMOS18",
SLEW => "SLOW")
port map (
O => acStim_obuf, -- Buffer output (connect directly to top-level port)
I => acStim -- Buffer input
);

-- the 32 bit division takes forever
  compute_n_periods : process (sysclk12_5)
  begin
    if rising_edge(sysclk12_5) then
      acStimX200_nPeriod <= (x"00F42400"/ unsigned(freqReq));
      acStim_nPeriod     <= (x"BEBC2000"/unsigned(freqReq));
    end if;
  end process compute_n_periods;

  make_ac_stim : process (sysclk400)
  begin
    if rising_edge(sysclk400) then
      -- Default Increment
      acStim_periodCnt     <= acStim_periodCnt +1;
      acStimX200_periodCnt <= acStimX200_periodCnt +1;

      if acStim_periodCnt = acStim_nPeriod then
        acStim           <= not acStim;
        acStim_periodCnt <= (acStim_periodCnt'left downto 1  => '0', 0  => '1');--x"000001";
      end if;

      if acStimX200_periodCnt = acStimX200_nPeriod then
        acStimX200           <= not acStimX200;
        acStimX200_periodCnt <=(acStimX200_periodCnt'left downto 1  => '0', 0  => '1');--x"000001";
      end if;

    end if;
  end process make_ac_stim;

  xadc_senseWire_inst : xadc_senseWire
    PORT MAP (
      m_axis_tvalid => m_axis_tvalid,
      m_axis_tready => m_axis_tready,
      m_axis_tdata  => m_axis_tdata,
      m_axis_tid    => m_axis_tid,
      m_axis_aclk   => sysclk25,
      s_axis_aclk   => sysclk25,
      m_axis_resetn => m_axis_resetn,

      vp_in  => V_p,
      vn_in  => V_n,
      vauxp0 => Vaux0_p,
      vauxn0 => Vaux0_n,
      vauxp8 => Vaux8_p,
      vauxn8 => Vaux8_n,

      channel_out => open,
      eoc_out     => open,
      alarm_out   => open,
      eos_out     => open,
      busy_out    => open
    );

  ila_xadc_inst : ila_xadc
    PORT MAP (
      clk       => sysclk25,
      probe0(0) => m_axis_tvalid,
      probe1    => m_axis_tdata,
      probe2    => m_axis_tid
    );

  vio_ctrl_inst : vio_ctrl
    PORT MAP (
      clk                      => sysclk12_5,
      --probe_in0(31 downto 24)  => x"00",
      probe_in0(31 downto 0)   => std_logic_vector(acStim_nPeriod),
      --probe_in1(31 downto 24)  => x"00",
      probe_in1(31 downto 0)   => std_logic_vector(acStimX200_nPeriod),
      --probe_out0(31 downto 24) => open,
      probe_out0(31 downto 0)  => freqReq,
      probe_out1(0)            => m_axis_resetn,
      probe_out2(0)            => m_axis_tready,
      probe_out3(0)            => acStim_enable
    );

end STRUCT;

