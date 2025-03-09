library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity tb_button_debouncer is
end tb_button_debouncer;

architecture Behavioral of tb_button_debouncer is

    constant CLK_FREQ         : integer := 100_000_000; 
    constant DEBOUNCE_TIME_MS : integer := 10;          
    constant CLK_PERIOD       : time := 10 ns;          

    signal clk        : std_logic := '0';
    signal button_in  : std_logic := '1';  -- Active Low (1 = unpressed, 0 = pressed)
    signal button_out : std_logic;

begin

    clk <= not clk after CLK_PERIOD / 2;

    uut: entity work.button_debouncer
        generic map (
            CLK_FREQ         => CLK_FREQ,
            DEBOUNCE_TIME_MS => DEBOUNCE_TIME_MS
        )
        port map (
            clk        => clk,
            button_in  => button_in,
            button_out => button_out
        );

    -- **Button Press Simulation with Bouncing**
    stim_process: process
    begin
        -- **Initial state: Button unpressed**
        wait for 100 us;

        -- **Introduce button bouncing before a stable press**
        button_in <= '0';  -- Start bouncing
        wait for 500 us;
        button_in <= '1';
        wait for 700 us;
        button_in <= '0';
        wait for 600 us;
        button_in <= '1';
        wait for 500 us;
        button_in <= '0';  -- Finally pressed

        -- **Hold button pressed for 20ms**
        wait for 20 ms;

        -- **Introduce button bouncing before release**
        button_in <= '1';
        wait for 500 us;
        button_in <= '0';
        wait for 700 us;
        button_in <= '1';
        wait for 600 us;
        button_in <= '0';
        wait for 500 us;
        button_in <= '1';  -- Finally released

        -- **End of test**
        wait for 10 ms;
        assert false report "Test Completed Successfully" severity failure;
    end process;

end Behavioral;
