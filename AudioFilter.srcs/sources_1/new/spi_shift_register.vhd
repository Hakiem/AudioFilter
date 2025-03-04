library ieee;
use ieee.std_logic_1164.all;

entity spi_shift_register is
    port(
        spi_clk             : in std_logic;     -- SPI Clock input (~1.8 MHz)
        rst                 : in std_logic;     -- Reset signal
        shift               : in std_logic;  -- Shift Enable
        miso                : in std_logic;  -- Data from MCP3202 (ADC output)
        mosi                : out std_logic; -- Data to MCP3202 (Config input)
        data_in             : in std_logic_vector(15 downto 0);  -- 16-bit Data to Send (MOSI)
        data_out            : out std_logic_vector(11 downto 0)  -- 12-bit Data Received (MISO)
    );
end spi_shift_register;

architecture Behavioral of spi_shift_register is
    signal shift_reg : std_logic_vector(15 downto 0) := (others => '0'); -- Outgoing data
    signal recv_reg  : std_logic_vector(11 downto 0) := (others => '0'); -- Incoming data
begin

    process(spi_clk, rst)
    begin
        if rst = '0' then
            shift_reg <= (others => '0');
            recv_reg  <= (others => '0');
        elsif rising_edge(spi_clk) then
            if shift = '1' then
                shift_reg <= shift_reg(14 downto 0) & '0'; -- Shift Left
                recv_reg  <= recv_reg(10 downto 0) & miso; -- Shift in Data from MCP3202
            end if;
        end if;
    end process;

    mosi <= shift_reg(15);  -- Send MSB First
    data_out <= recv_reg;   -- Output received ADC data
end Behavioral;
