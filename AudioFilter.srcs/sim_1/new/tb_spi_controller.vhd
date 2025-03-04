library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity tb_spi_controller is
end tb_spi_controller;

architecture Behavioral of tb_spi_controller is

    constant CLK_PERIOD : time := 10 ns;  -- 100 MHz System Clock

    -- Test Signals
    signal clk_tb        : std_logic := '0'; 
    signal rst_tb        : std_logic := '0'; -- Reset
    signal channel_sel_tb: std_logic := '0'; -- Always sampling CH0
    signal miso_tb       : std_logic := '0'; -- Simulated MCP3202 ADC Output
    signal mosi_tb       : std_logic;
    signal cs_tb         : std_logic := '1'; -- Chip Select (Active Low)
    signal busy_tb       : std_logic := '0'; -- SPI Transaction Active
    signal adc_result_tb : std_logic_vector(11 downto 0) := (others => '0');
    signal spi_clk_tb    : std_logic;

begin

    -- Clock process (100MHz)
    clk_tb <= not clk_tb after CLK_PERIOD / 2;

    -- DUT (Device Under Test)
    uut : entity work.spi_controller
        port map (
            clk        => clk_tb,
            rst        => rst_tb,
            channel_sel => channel_sel_tb,  -- Always use CH0
            miso       => miso_tb,
            mosi       => mosi_tb,
            cs         => cs_tb,
            busy       => busy_tb,
            adc_result => adc_result_tb,
            spi_clk    => spi_clk_tb 
        );

    -- Simulated MCP3203 ADC Response (Continous Sampling)
    stim_process: process
        variable i : integer := 0;  -- Track bit position
    begin
        -- Apply reset
        wait for 15 ns;
        rst_tb <= '0';
        wait for 15 ns;
        rst_tb <= '1';
        wait for 15 ns;

        -- **Start Continuous Sampling**
        while now < 1 ms loop
            wait until cs_tb = '0';  -- Wait for SPI transaction to start
            i := 0;  -- Reset bit counter

            -- **Simulate MCP3202 Sending 16-bit Data (First 4 Bits Dummy + 12-bit ADC Data)**
            while i < 16 loop
                wait until rising_edge(spi_clk_tb);  -- **Ensure MISO updates with SPI clock**

                -- **Correct Bitwise Response**
                case i is
                    -- **4-bit dummy response**
                    when 0  => miso_tb <= '0';  -- Dummy Bit 15
                    when 1  => miso_tb <= '0';  -- Dummy Bit 14
                    when 2  => miso_tb <= '0';  -- Dummy Bit 13
                    when 3  => miso_tb <= '0';  -- Dummy Bit 12
                    
                    -- **12-bit ADC Data (0x555 = 101010101010)**
                    when 4  => miso_tb <= '1';  -- Bit 11
                    when 5  => miso_tb <= '0';  -- Bit 10
                    when 6  => miso_tb <= '1';  -- Bit 9
                    when 7  => miso_tb <= '0';  -- Bit 8
                    when 8  => miso_tb <= '1';  -- Bit 7
                    when 9  => miso_tb <= '0';  -- Bit 6
                    when 10 => miso_tb <= '1';  -- Bit 5
                    when 11 => miso_tb <= '0';  -- Bit 4
                    when 12 => miso_tb <= '1';  -- Bit 3
                    when 13 => miso_tb <= '0';  -- Bit 2
                    when 14 => miso_tb <= '1';  -- Bit 1
                    when 15 => miso_tb <= '0';  -- Bit 0
                    when others => miso_tb <= '0';  -- Default to 0
                end case;

                i := i + 1;  -- Increment bit counter
            end loop;

            miso_tb <= '0';
            -- Wait for transaction completion
            wait until cs_tb = '1';  -- SPI Transaction Done
            wait for 50 ns;  -- Small delay before next transaction
        end loop;

        -- **Check ADC Results in Simulation**
        assert adc_result_tb = x"555" report "Incorrect ADC Result!" severity failure;

        -- **Stop Simulation**
        assert false report "Test Completed Successfully" severity failure;

    end process;

end Behavioral;
