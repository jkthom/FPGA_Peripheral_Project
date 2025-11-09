library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity KEY1_PERIPH is
  port(
    CLOCK    : in  std_logic;
    RESETN   : in  std_logic;
    KEY1_N   : in  std_logic;                           -- active-low pushbutton
    IO_ADDR  : in  std_logic_vector(10 downto 0);
    IO_READ  : in  std_logic;
    IO_WRITE : in  std_logic;
    IO_DATA  : inout std_logic_vector(15 downto 0)
  );
end KEY1_PERIPH;

architecture rtl of KEY1_PERIPH is
  constant KEY1_ADDR : std_logic_vector(10 downto 0)
    := std_logic_vector(to_unsigned(16#096#, 11));      -- &H096

  -- 2-FF synchronizer (recommended)
  signal key1_meta, key1_sync : std_logic := '1';
  signal key1_pressed         : std_logic;

  signal dout : std_logic_vector(15 downto 0);
  signal en   : std_logic;
begin
  -- sync the mechanical button to CLOCK
  process (CLOCK, RESETN)
  begin
    if RESETN = '0' then
      key1_meta <= '1';
      key1_sync <= '1';
    elsif rising_edge(CLOCK) then
      key1_meta <= KEY1_N;
      key1_sync <= key1_meta;
    end if;
  end process;

  key1_pressed <= not key1_sync;                         -- 1 when pressed
  dout <= (15 downto 1 => '0') & key1_pressed;           -- bit0 reflects button
  en   <= '1' when (IO_READ='1' and IO_ADDR=KEY1_ADDR) else '0';

  -- Tri-state the shared bus only on read + address match
  IO_DATA <= dout when en = '1' else (others => 'Z');
end rtl;

