library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

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

    type data_array_type is array(0 to 9) of std_logic_vector(15 downto 0);
    signal data_array : data_array_type := (
        x"5555", x"A5A5", x"1234", x"ABCD", x"6789", 
        x"000F", x"F000", x"1F2E", x"9876", x"FEDC"
    );  -- Example 10 values to send

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

    -- Simulated SPI Slave (MCP3203 ADC Response)
    stim_process: process
        variable shift_reg   : std_logic_vector(15 downto 0);
        variable bit_counter : integer;
        variable index : integer := 0;
    begin

        -- Apply reset
        rst_tb <= '0';
        wait for 15 ns;
        rst_tb <= '1';
        wait for 15 ns;

        index := 0;  -- Start from first value

        -- Loop through each 16-bit value in the array
        while index < 10 loop
            shift_reg := data_array(index);  -- Load current value
            bit_counter := 0;  -- Reset bit counter for each value

            -- Wait for CS to go low (Start of SPI transaction)
            wait until cs_tb = '0';

            -- Send 16 bits of the current value
            while bit_counter < 16 loop
                wait until rising_edge(spi_clk_tb);
                miso_tb <= shift_reg(15); -- Send MSB first
                shift_reg := shift_reg(14 downto 0) & '0'; -- Shift left
                bit_counter := bit_counter + 1;
            end loop;

            -- Wait for SPI transaction to complete (CS goes high)
            wait until cs_tb = '1';

            -- **VERIFY: Check if the received ADC result matches expected value**
            wait until rising_edge(clk_tb); -- Small delay after CS goes high
            assert adc_result_tb = data_array(index)(11 downto 0)
                report "Mismatch: Expected " & integer'image(conv_integer(data_array(index)(11 downto 0))) &
                       " but got " & integer'image(conv_integer(adc_result_tb))
                severity error;

            index := index + 1; -- Move to next value
        end loop;

        -- **Stop Simulation**
        assert false report "Test Completed Successfully" severity failure;

    end process;

end Behavioral;
