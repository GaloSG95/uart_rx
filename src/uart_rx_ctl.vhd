-- Design       : Galo Sanchez
-- Verification : Nicklas Wright
-- Reviewers    : Hampus Lang
-- Module       : uart_rx_ctl.vhd
-- Parent       : uart.vhd
-- Children     : none

-- Description: rx control RS232 reception

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity uart_rx_ctl is
  port (    clk         : in    std_logic;
            rst         : in    std_logic;
            baud_en     : in    std_logic;
            rxd_rx      : in    std_logic;
            rx_data     : out   std_logic_vector(7 downto 0);
            wr_en       : out   std_logic);
end uart_rx_ctl;

architecture uart_rx_ctl_arch of uart_rx_ctl is

type state_type is (IDLE, START, DATA, STOP);
signal state, next_state : state_type;

-- output register
signal reg_rx_data      : std_logic_vector(7 downto 0);
signal reg_wr_en        : std_logic;
-- counter signals
signal over_sample_cnt  : unsigned(3 downto 0):=(others => '0');
signal bit_cnt          : unsigned(2 downto 0):=(others => '0');
-- counter flags
signal over_sample_done : std_logic:='0';
signal bit_cnt_done     : std_logic:='0';

-- constants
constant half_bit  : unsigned(3 downto 0):= "0111"; -- halft bit alignment

begin

-- state machine: state sync
SYNC_PROC: process (clk)
begin
  if (clk'event and clk = '1') then
      if (rst = '1') then
        state <= IDLE;
      else
        state <= next_state;
      end if;
  end if;
end process SYNC_PROC;

NEXT_STATE_DECODE: process (state, baud_en, rxd_rx, over_sample_done, bit_cnt_done)
begin
  --declare default state for next_state to avoid latches
  next_state <= state;

  if(baud_en = '1') then
    case (state) is
        when IDLE =>
          if rxd_rx = '0' then
              next_state <= START;
          end if;
        when START =>
          if over_sample_done = '1' then
            if rxd_rx = '0' then
              -- not a glitch
              next_state <= DATA;
            else
              -- was a glitch
              next_state <= IDLE;
            end if;
          end if;
        when DATA =>
          if((over_sample_done = '1') and (bit_cnt_done = '1')) then
            -- check for stop bite
            next_state <= STOP;
          end if;
        when STOP =>
          if(over_sample_done = '1') then
            next_state <= IDLE;
          end if;
    end case;
  end if;
end process NEXT_STATE_DECODE;


OVERSAMPLE_COUNTER: process(clk)
begin
  if(clk'event and clk = '1') then
    if(rst = '1') then
      over_sample_cnt <= (others => '0');
    else
      if(baud_en = '1') then
        if(over_sample_done = '0') then
          over_sample_cnt <= over_sample_cnt - 1;
        else
          if((state = IDLE) and (rxd_rx = '0')) then
            over_sample_cnt <= half_bit;
          elsif(((state = START) and rxd_rx = '0') or (state = DATA)) then
            over_sample_cnt <= "1111";
          end if;
        end if;
      end if;
    end if;
  end if;
end process OVERSAMPLE_COUNTER;

over_sample_done <= '1' when over_sample_cnt = "0000" else '0';

BIT_COUNTER: process(clk)
begin
  if(clk'event and clk = '1') then
    if (rst = '1') then
      bit_cnt <= (others => '0');
    else
      if baud_en = '1' then
        if over_sample_done = '1' then
          if state = START then
            bit_cnt <= (others => '0');
          elsif state = DATA then
            bit_cnt <= bit_cnt + 1;
          end if ;
        end if ;
      end if ;
    end if ;
  end if;
end process BIT_COUNTER;

bit_cnt_done <= '1' when bit_cnt = "111" else '0';

-- Caputure single bits into vector and wr_en generation
OUTPUT_DATA: process(clk)
begin
  if clk'event and clk = '1' then
    if rst = '1' then
      reg_rx_data <= (others => '0');
      reg_wr_en   <= '0';
    else
      if (baud_en = '1' and over_sample_done = '1') then
        if state = DATA then
          reg_rx_data(to_integer(bit_cnt)) <= rxd_rx;
          if bit_cnt = "111" then
            reg_wr_en <= '1';
          else
            reg_wr_en <= '0';
          end if ;
        else
          reg_wr_en <= '0';
        end if ;
      end if ;
    end if ;
  end if ;
end process OUTPUT_DATA;

-- Register to output
rx_data <= reg_rx_data;
wr_en   <= reg_wr_en;

end uart_rx_ctl_arch;
