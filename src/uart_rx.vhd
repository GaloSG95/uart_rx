-- Design       : Galo Sanchez
-- Verification : Nicklas Wright
-- Reviewers    : Hampus Lang
-- Module       : uart_rx.vhd
-- Parent       : various
-- Children     : uart_rx_ctl.vhd, uart_baud.vhd, meta_harden.vhd

-- Description: UART RX top level description

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity uart_rx is
  port (  uart_clk         : in std_logic;                     -- 100 Mhz clock
          uart_rst         : in std_logic;                     -- reset
          uart_rxd_rx      : in std_logic;                     -- rx wire
          uart_rx_data     : out std_logic_vector(7 downto 0); -- caputured data
          uart_wr_en       : out std_logic);                   -- data ready
end uart_rx;

architecture uart_rx_arch of uart_rx is

component uart_baud is
  generic(  baud_rate   : real:=115200.0;
            clock_rate  : real:=100.0e6);
  port (    clk     : in    std_logic;
            rst     : in    std_logic;
            baud_en : out   std_logic);
end component uart_baud;

component uart_rx_ctl is
  port (    clk         : in    std_logic;
            rst         : in    std_logic;
            baud_en     : in    std_logic;
            rxd_rx      : in    std_logic;
            rx_data     : out   std_logic_vector(7 downto 0);
            wr_en       : out   std_logic);
end component uart_rx_ctl;

component meta_harden is
  port(   clk     : in std_logic;
          rst     : in std_logic;
          sig_src : in std_logic;
          sig_dst : out std_logic);
end component meta_harden;


signal wire_baud_en     : std_logic;
signal stable_rxd_rx    : std_logic;

begin

-- uart baud instance and port mapping
uart_baud_inst: component uart_baud
  -- use default generics
  port map  ( clk     => uart_clk,
              rst     => uart_rst,
              baud_en => wire_baud_en);

uart_rx_ctl_inst: component uart_rx_ctl
  port map  ( clk     => uart_clk,
              rst     => uart_rst,
              baud_en => wire_baud_en,
              rxd_rx  => stable_rxd_rx,
              rx_data => uart_rx_data,
              wr_en   => uart_wr_en);

meta_harden_inst: component meta_harden
  port map  ( clk     => uart_clk,
              rst     => uart_rst,
              sig_src => uart_rxd_rx,
              sig_dst => stable_rxd_rx);
end uart_rx_arch;
