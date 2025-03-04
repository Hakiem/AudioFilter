library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity spi_clock_gen is
    generic (
        clk_div : integer := 56             -- Divider to generate ~1.8 MHz SPI Clock
    );
    port (
        clk         : in std_logic;     -- 100MHz FPGA System clock
        rst         : in std_logic;     -- Reset signal
        spi_clk     : out std_logic     -- SPI Clock output (~1.8 MHz)
    );
end spi_clock_gen;

architecture Behavioral of spi_clock_gen is
    signal clk_count    : integer := 0;
    signal sck_reg      : std_logic := '0';
begin

    process(clk, rst)
    begin
        if rst = '0' then
            clk_count   <= 0;
            sck_reg     <= '0';
        elsif rising_edge(clk) then
            if clk_count = clk_div - 1 then
                sck_reg     <= not sck_reg; -- Toggle SPI Clock 
                clk_count   <= 0;
            else
                clk_count <= clk_count + 1;
            end if;
        end if;
    end process;

    spi_clk <= sck_reg;
end Behavioral;
