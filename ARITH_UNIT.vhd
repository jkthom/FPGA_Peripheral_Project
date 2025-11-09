library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ARITH_UNIT is
  port (
    CLOCK    : in  std_logic;
    RESETN   : in  std_logic;

    IO_ADDR  : in  std_logic_vector(10 downto 0);
    IO_DATA  : inout std_logic_vector(15 downto 0);
    IO_READ  : in  std_logic;
    IO_WRITE : in  std_logic
  );
end ARITH_UNIT;

architecture rtl of ARITH_UNIT is
  -- I/O addresses
  constant A_ADDR     : std_logic_vector(10 downto 0) := std_logic_vector(to_unsigned(16#090#, 11));
  constant B_ADDR     : std_logic_vector(10 downto 0) := std_logic_vector(to_unsigned(16#091#, 11));
  constant CTRL_ADDR  : std_logic_vector(10 downto 0) := std_logic_vector(to_unsigned(16#092#, 11));
  constant RESLO_ADDR : std_logic_vector(10 downto 0) := std_logic_vector(to_unsigned(16#093#, 11));
  constant RESHI_ADDR : std_logic_vector(10 downto 0) := std_logic_vector(to_unsigned(16#094#, 11));

  -- regs
  signal a_reg, b_reg   : std_logic_vector(15 downto 0);
  signal res_lo, res_hi : std_logic_vector(15 downto 0);

  -- status
  signal op_div      : std_logic;  -- 0=mul,1=div (last cmd)
  signal busy        : std_logic;
  signal done        : std_logic;  -- sticky until cleared
  signal div_by_zero : std_logic;

  -- readback
  signal read_data   : std_logic_vector(15 downto 0);
  signal drive_en    : std_logic;

  -- status word
  signal status_word : std_logic_vector(15 downto 0);
begin

  -- Build STATUS word (combinational)
  status_comb : process(done, busy, div_by_zero, op_div)
  begin
    status_word <= (others => '0');
    status_word(7) <= done;
    status_word(6) <= busy;
    status_word(5) <= div_by_zero;
    status_word(0) <= op_div;
  end process;

  -- SINGLE driver for all registers, including DONE
  write_proc : process (CLOCK, RESETN)
    variable prod32 : unsigned(31 downto 0);
    variable quot16 : unsigned(15 downto 0);
  begin
    if RESETN = '0' then
      a_reg       <= (others => '0');
      b_reg       <= (others => '0');
      res_lo      <= (others => '0');
      res_hi      <= (others => '0');
      op_div      <= '0';
      busy        <= '0';
      done        <= '0';
      div_by_zero <= '0';

    elsif rising_edge(CLOCK) then
      -- Default: keep current status
      -- Optional: clear DONE when CPU reads CTRL (ack)
      if (IO_READ = '1') and (IO_ADDR = CTRL_ADDR) then
        done <= '0';
      end if;

      if IO_WRITE = '1' then
        if IO_ADDR = A_ADDR then
          a_reg <= IO_DATA;

        elsif IO_ADDR = B_ADDR then
          b_reg <= IO_DATA;

        elsif IO_ADDR = CTRL_ADDR then
          -- New command: bit0 selects op (0=mul,1=div)
          op_div      <= IO_DATA(0);
          busy        <= '1';
          done        <= '0';
          div_by_zero <= '0';

          if IO_DATA(0) = '0' then
            -- Multiply
            prod32 := unsigned(a_reg) * unsigned(b_reg);
            res_lo <= std_logic_vector(prod32(15 downto 0));
            res_hi <= std_logic_vector(prod32(31 downto 16));
            busy   <= '0';
            done   <= '1';

          else
            -- Divide (unsigned)
            if b_reg = x"0000" then
              res_lo      <= (others => '0');
              res_hi      <= (others => '0');
              div_by_zero <= '1';
              busy        <= '0';
              done        <= '1';
            else
              quot16 := unsigned(a_reg) / unsigned(b_reg);
              res_lo <= std_logic_vector(quot16);
              res_hi <= (others => '0');
              busy   <= '0';
              done   <= '1';
            end if;
          end if;
        end if;
      end if;
    end if;
  end process;

  -- Readback mux
  with IO_ADDR select
    read_data <=
      a_reg        when A_ADDR,
      b_reg        when B_ADDR,
      status_word  when CTRL_ADDR,
      res_lo       when RESLO_ADDR,
      res_hi       when RESHI_ADDR,
      (others => '0') when others;

  -- Tri-state the shared bus only on read + address match
  drive_en <= '1' when (IO_READ = '1') and
                       (IO_ADDR = A_ADDR or IO_ADDR = B_ADDR or
                        IO_ADDR = CTRL_ADDR or IO_ADDR = RESLO_ADDR or IO_ADDR = RESHI_ADDR)
              else '0';

  IO_DATA <= read_data when drive_en = '1' else (others => 'Z');

end rtl;





