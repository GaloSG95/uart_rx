-- Design       : Galo Sanchez
-- Verification : Nicklas Wright
-- Reviewers    : Hampus Lang
-- Module       : meta_harden.vhd
-- Parent       : uart.vhd
-- Children     : none

-- Description: meta-stability hardener, allows syncronization onto a different clock domain


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity meta_harden is
    port(   clk     : in std_logic;
            rst     : in std_logic;
            sig_src : in std_logic;
            sig_dst : out std_logic);
end meta_harden;


architecture meta_harden_arch of meta_harden is

signal sig_meta : std_logic;

begin

syncronization_process: process(clk)
begin
    if(clk'event and clk = '1') then
        if(rst = '1') then
            sig_meta    <= '0';
            sig_dst     <= '0';
        else
            sig_meta    <= sig_src;
            sig_dst     <= sig_meta;
        end if;
    end if;
end process syncronization_process;

end architecture meta_harden_arch;

    
