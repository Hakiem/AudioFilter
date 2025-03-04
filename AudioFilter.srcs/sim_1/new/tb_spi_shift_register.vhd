library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity tb_spi_shift_register is

end tb_spi_shift_register;

architecture Behavioral of tb_spi_shift_register is

    -- FPGA System clock parameters
    constant SYS_CLK_PERIOD : time := 10 ns;    -- 100 MHz System Clock

    -- Testbench Signals
    signal sys_clk_tb           : std_logic := '0';                                     -- FPGA System Clock (100 MHz)
    signal rst_tb               : std_logic := '1';                                     -- Reset
    signal shift_tb             : std_logic := '0';                                     -- Shift Enable
    signal miso_tb              : std_logic := '0';                                     -- Simulated MCP3202 Data Output
    signal mosi_tb              : std_logic;                                            -- SPI Data Output (to MCP3202)
    signal sck_tb               : std_logic;                                            -- SPI Clock (1.8 MHz)
    signal data_in_tb           : std_logic_vector(15 downto 0) := "1100000000000000";  -- Command to MCP3202 0xC000
    signal data_out_tb          : std_logic_vector(11 downto 0);                        -- Captured ADC output

begin

    -- Clock process (100MHz)
    sys_clk_tb <= not sys_clk_tb after SYS_CLK_PERIOD / 2;

    -- DUT - SPI Clock Generator
    uut_spi_clk : entity work.spi_clock_gen
        generic map (
            clk_div => 56
        )
        port map (
            clk         => sys_clk_tb,      -- 100 MHz FPGA clock
            rst         => rst_tb,          -- Reset    
            spi_clk     => sck_tb           -- SPI Clock output (~1.8 MHz)
        );

    -- Instantiate SPI Shift Register
    uut_spi_shift : entity work.spi_shift_register
        port map (
            spi_clk     => sck_tb,          -- SPI Clock input (~1.8 MHz)
            rst         => rst_tb,          -- Reset
            shift       => shift_tb,        -- Shift Enable
            miso        => miso_tb,         -- Data from MCP3202 (ADC output)
            mosi        => mosi_tb,         -- Data to MCP3202 (Config input)
            data_in     => data_in_tb,      -- 16-bit Data to Send (MOSI)
            data_out    => data_out_tb      -- 12-bit Data Received (MISO)
        );


    -- Test sequence
    stim_process: process
    begin
        -- Start in Reset (Active-Low)
        wait for 100 ns;
        rst_tb <= '0';
        wait for 100 ns;

        -- Release Reset (Active-Low Deasserted)
        rst_tb <= '1';

        -- Wait a few cycles
        wait for 5 * SYS_CLK_PERIOD;

        -- Start shifting
        shift_tb <= '1';

        for i in 0 to 15 loop
            wait until rising_edge(sck_tb);
            miso_tb <= not miso_tb; -- Simulate MCP3202 response
        end loop;

        shift_tb <= '0'; -- Stop shifting

        -- Wait to see the final data
        wait for 5 * SYS_CLK_PERIOD;

        -- Stop Simulation
        assert false report "Test Completed Successfully" severity failure;

    end process;

end Behavioral;
