library ieee;
use ieee.std_logic_1164.all;

entity tb_button_debouncer is
end tb_button_debouncer;

architecture Behavioral of tb_button_debouncer is

    -- **Test Parameters**
    constant CLK_PERIOD       : time := 10 ns;  -- 100 MHz Clock
    constant DEBOUNCE_TIME_MS : integer := 1;   -- Fast debounce time for simulation

    -- **Test Signals**
    signal clk_tb        : std_logic := '0';
    signal button_in_tb  : std_logic := '1';  -- Button starts unpressed (Active High)
    signal button_out_tb : std_logic;  -- Debounced Output

begin

    -- **Clock Process (100 MHz)**
    clk_tb <= not clk_tb after CLK_PERIOD / 2;

    -- **DUT: Button Debouncer**
    uut: entity work.button_debouncer
        generic map (
            CLK_FREQ         => 100_000_000,  -- 100 MHz
            DEBOUNCE_TIME_MS => DEBOUNCE_TIME_MS
        )
        port map (
            clk        => clk_tb,
            button_in  => button_in_tb,
            button_out => button_out_tb
        );

    -- **Debouncing Simulation with Multiple Button Presses**
    stim_process: process
    begin
        report "Starting Multiple Button Press Simulation...";

        -- **Initial State: Button Not Pressed**
        wait for 50 ns;

        -- **First Button Press (Short Bounce)**
        button_in_tb <= '0';  -- Button Pressed (Start bouncing)
        wait for 20 ns;
        button_in_tb <= '1';
        wait for 30 ns;
        button_in_tb <= '0';  
        wait for 25 ns;
        button_in_tb <= '1';
        wait for 20 ns;
        button_in_tb <= '0';  -- Finally pressed
        wait for 1 ms;  -- Hold press
        assert button_out_tb = '0'
            report "Error: Button should be debounced LOW after press!"
            severity error;
        report "Button Debounced: Press Detected";
        wait for 500 ns;

        -- **First Button Release (More Bouncing)**
        button_in_tb <= '1';
        wait for 10 ns;
        button_in_tb <= '0';
        wait for 15 ns;
        button_in_tb <= '1';
        wait for 25 ns;
        button_in_tb <= '0';
        wait for 30 ns;
        button_in_tb <= '1';
        wait for 40 ns;
        button_in_tb <= '0';
        wait for 50 ns;
        button_in_tb <= '1';  -- Finally released
        wait for 1 ms;
        assert button_out_tb = '1'
            report "Error: Button should be debounced HIGH after release!"
            severity error;
        report "Button Debounced: Release Detected";

        -- **Second Button Press (Stable Press)**
        wait for 2 ms;
        button_in_tb <= '0';
        wait for 2 ms;  -- Long hold
        assert button_out_tb = '0'
            report "Error: Button should be debounced LOW after long press!"
            severity error;
        report "Button Debounced: Second Press Detected";
        
        -- **Second Button Release (Stable)**
        wait for 1 ms;
        button_in_tb <= '1';
        wait for 1 ms;
        assert button_out_tb = '1'
            report "Error: Button should be debounced HIGH after second release!"
            severity error;
        report "Button Debounced: Second Release Detected";

        -- **Third Button Press (Quick Press)**
        wait for 500 ns;
        button_in_tb <= '0';
        wait for 1 ms;
        button_in_tb <= '1';
        wait for 1 ms;
        assert button_out_tb = '1'
            report "Error: Button should be debounced HIGH after quick release!"
            severity error;
        report "Button Debounced: Third Press Detected";

        -- **End of Test**
        wait for 100 ns;
        report "Multiple Button Press Test Completed Successfully!";
        assert false report "Test Completed" severity failure;
    end process;

end Behavioral;
