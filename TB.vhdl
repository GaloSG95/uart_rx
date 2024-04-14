-- Verification : Nicklas Wright
-- Design       : Galo Sanchez
-- Reviewers    : Hampus Lang
-- Module       : TB.vhdl
-- Parent       : none
-- Children     : uart_rx.vhd

-- Description: TB for uart_rx

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_textio.all;
use STD.textio.all;

entity tb is
end entity tb;

architecture tb_arch of tb is

	-- constants
constant clk_period		: time := 10 ns;	--clock period
constant uart_period	: time := 8800 ns;	--115200 transmission period
constant CYCLES     	: positive := 1000; -- Number of test vectors
-- type used to store 8-bit test vectors for CYCLES cycles

type word_array is array (0 to CYCLES-1) of std_logic_vector(7 downto 0);


-- signals
signal reg_uart_clk    	: std_logic:='0';
signal reg_uart_rst    	: std_logic:='0';
signal reg_uart_rxd_rx 	: std_logic:='1';				-- sent data bit
signal reg_uart_rx_data	: std_logic_vector(7 downto 0); -- received 8-bit word
signal stimuli			: std_logic_vector(7 downto 0); -- Current word being tested
signal reg_uart_wr_en  	: std_logic;
signal test_data		: word_array;

-- file to which error message is written
file LOG : text open write_mode is "uart_rx_log.txt";

-- Component declaration
component uart_rx is
	port (  uart_clk         : in std_logic;                     -- 100 Mhz clock
			uart_rst         : in std_logic;                     -- reset
			uart_rxd_rx      : in std_logic;                     -- rx wire
			uart_rx_data     : out std_logic_vector(7 downto 0); -- caputured data
			uart_wr_en       : out std_logic);                   -- data ready
end component uart_rx;


  -- functions
  
  -- Convert read character to std_logic
  function to_std_logic (char : character) return std_logic is
    variable result : std_logic;
  begin
    case char is
      when '0'    => result := '0';
      when '1'    => result := '1';
      when 'x'    => result := '0';
      when others => assert (false) report "no valid binary character read" severity failure;
    end case;
    return result;
  end to_std_logic;

	-- Load 8-bit word from list
  function load_words (file_name : string) return word_array is
    file object_file : text open read_mode is file_name;
    variable memory  : word_array;
    variable L       : line;
    variable index   : natural := 0;
    variable char    : character;
  begin
    while not endfile(object_file) loop
      readline(object_file, L);
      for i in 7 downto 0 loop
        read(L, char);
        memory(index)(i) := to_std_logic(char);
      end loop;
      index := index + 1;
    end loop;
    return memory;
  end load_words;

  -- Functions for converting to vectors to strings
  -- Convert a std_logic to a one character string, all possible values included.
  function to_string(input : std_logic) return string is
    begin
      case input is
        when 'U'    => return "U";
        when 'X'    => return "X";
        when '0'    => return "0";
        when '1'    => return "1";
        when 'Z'    => return "Z";
        when 'W'    => return "W";
        when 'L'    => return "L";
        when 'H'    => return "H";
        when '-'    => return "-";
        when others => return " ";
      end case;
    end function to_string;
  
    -- Convert a std_logic to a string. This function apply to_string(input : std_logic)
    -- to each bit in the vector. It supports both std_logic_vector(A to B) and
    -- (A downto B) by checking the ascending attribute of the input signal. 
    function to_string(input : std_logic_vector) return string is
      variable result : string(1 to input'length);
    begin
      if input'ascending then
        for idx in input'range loop
          result(idx+1) := to_string(input(idx))(1);
        end loop;
      else
        for idx in input'range loop
          result(input'length-idx) := to_string(input(idx))(1);
        end loop;
      end if;
      return result;
    end function to_string;

-- Testbench code begins
begin
-- Component instantiation
dut: component uart_rx
	port map (	uart_clk		=> reg_uart_clk,   
				uart_rst		=> reg_uart_rst,
				uart_rxd_rx		=> reg_uart_rxd_rx,
				uart_rx_data	=> reg_uart_rx_data,
				uart_wr_en		=> reg_uart_wr_en);

-- Load test_vector from text file (needs to be in same directory as project!"
test_data <= load_words("./1000_RANDOM_TEST_VECTORS.txt");
-- Generate 100 MHz clock
clock_gen: process
begin
	wait for clk_period/2;
	reg_uart_clk <= not reg_uart_clk;
end process clock_gen;

-- reset
reset: process
begin
	wait for clk_period*2;
	reg_uart_rst <= '1';
	wait for clk_period*2;
	reg_uart_rst <= '0';
	wait;
end process reset;

-- Send 1000 data vectors process
tx_data: process
begin
	wait for clk_period*8;	--Arbitrary delay

	-- Generate start bit, cycle through bitwise all 1000 test vectors, and then generate stop bit
	for row_idx in 0 to CYCLES-1 loop
		reg_uart_rxd_rx <= '0'; --START BIT

		stimuli <= test_data(row_idx)(7 downto 0); -- Load one vector from list

		wait for uart_period;

		for bit_idx in 0 to 7 loop
			reg_uart_rxd_rx <= stimuli(bit_idx);	-- transmit data
			wait for uart_period;
		end loop;

		reg_uart_rxd_rx <= '1'; --Stop bit, go to IDLE

		wait for uart_period;
	end loop;
end process tx_data;

-- captured byte verification
rx_verification: process
variable L     : line;
begin
	for idx in 0 to CYCLES-1 loop
		wait until rising_edge(reg_uart_wr_en);
		assert(reg_uart_rx_data = test_data(idx)) 
		report "Captured data does not match! Received = " &to_string(reg_uart_rx_data) &
		", but transmitted: " & to_string(test_data(idx))
		severity warning;
	-- Write to text file
		if (reg_uart_rx_data /= test_data(idx)) then
		write(L, string'("Error! Recieved data = "));
		write(L, reg_uart_rx_data);
		writeline(LOG, L);

		write(L, string'(", but transmitted = "));
		write(L,test_data(idx));
		writeline(LOG, L);
		end if;	
		wait for uart_period;
	end loop;
	report "Testbench finished!" severity failure;
end process rx_verification;

end architecture tb_arch;
