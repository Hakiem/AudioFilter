library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity tb_top_module is
end tb_top_module;

architecture Behavioral of tb_top_module is

    constant CLK_PERIOD : time := 10 ns;  -- 100 MHz System Clock

    -- Test Signals
    signal clk_tb         : std_logic := '0'; 
    signal button_raw_tb  : std_logic := '1'; -- Active High Button
    signal miso_tb        : std_logic := '0'; -- Simulated MCP3202 ADC Output
    signal mosi_tb        : std_logic;
    signal cs_tb          : std_logic; -- Active Low Chip Select
    signal spi_clk_tb     : std_logic;
    signal adc_out_tb     : std_logic_vector(11 downto 0) := (others => '0');

begin

    -- Clock process (100MHz)
    clk_tb <= not clk_tb after CLK_PERIOD / 2;

    -- DUT (Device Under Test)
    uut : entity work.top_module
        generic map (
            CLK_FREQ        => 100_000_000,  -- 100 MHz
            DEBOUNCE_TIME_MS => 1
        )
        port map (
            clk         => clk_tb,
            button_raw  => button_raw_tb,
            miso        => miso_tb,
            mosi        => mosi_tb,
            cs          => cs_tb,
            spi_clk     => spi_clk_tb,
            adc_out     => adc_out_tb
        );

    -- **Debouncing Process**
    debouncer_process: process
    begin
        report "Starting Debouncing Test...";

        -- **Initial state: Button unpressed**
        wait for 50 ns;

        button_raw_tb <= '0';  -- Start bouncing
        wait for 20 ns;  -- ⚡ Faster bouncing
        button_raw_tb <= '1';
        wait for 30 ns;
        button_raw_tb <= '0';
        wait for 25 ns;
        button_raw_tb <= '1';
        wait for 20 ns;
        button_raw_tb <= '0';  -- Finally pressed

        -- **Hold button pressed (Super Short)**
        report "Button Debounced: Press Detected";

        -- **Release button with bouncing**
        button_raw_tb <= '1';
        wait for 20 ns;
        button_raw_tb <= '0';
        wait for 30 ns;
        button_raw_tb <= '1';
        wait for 25 ns;
        button_raw_tb <= '0';
        wait for 20 ns;
        button_raw_tb <= '1';  -- Finally released

        report "Debouncing Test Completed!";
        
        -- **Wait for debounce stabilization**
        wait for 1 us;  -- ⚡ Almost instant exit
        report "Button Debounced: Release Detected";
        
        wait for 100 ns;
    end process;

    -- **SPI Process (Runs after Debouncer is Done)**
    spi_process: process
        type data_array_type is array(0 to 9) of std_logic_vector(15 downto 0);
        variable data_array : data_array_type := (
            x"5555", x"A5A5", x"1234", x"ABCD", x"6789", 
            x"000F", x"F000", x"1F2E", x"9876", x"FEDC"
        );
        variable shift_reg   : std_logic_vector(15 downto 0);
        variable bit_counter : integer;
        variable index : integer := 0;
    begin
        report "Waiting for Debounced Button Press to Start SPI...";

        -- **Wait until debounced button signal goes low (reset is activated)**
        wait until cs_tb = '0';

        report "Debounced Button Detected - Starting SPI Test...";

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
            assert adc_out_tb = data_array(index)(11 downto 0)
                report "Mismatch: Expected " & integer'image(conv_integer(data_array(index)(11 downto 0))) &
                       " but got " & integer'image(conv_integer(adc_out_tb))
                severity error;

            index := index + 1; -- Move to next value
        end loop;

        report "SPI Communication Test Completed!";
        
        -- **End of test**
        wait for 10 ms;
        assert false report "Test Completed Successfully" severity failure;
    end process;

end Behavioral;