library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity button_debouncer is
    generic(
        CLK_FREQ         : integer  := 100_000_000;  -- 100 MHz
        DEBOUNCE_TIME_MS : integer  := 10           -- Debounce time in milliseconds
    );
    port(
        clk        : in std_logic;  -- System Clock (100 MHz)
        button_in  : in std_logic;  -- Raw Button Input (Active High)
        button_out : out std_logic  -- Debounced Button Output (Active High)
    );
end button_debouncer;

architecture Behavioral of button_debouncer is

    -- **1. Clock Enable Generation** (Debounce Processing Every Few ms)
    constant DEBOUNCE_COUNT : integer := (CLK_FREQ / 1000) * DEBOUNCE_TIME_MS;  
    signal slow_clk_enable : std_logic := '0';
    signal debounce_counter : integer range 0 to DEBOUNCE_COUNT := 0;

    -- **2. Flip-Flops for Synchronization & Stability**
    signal button_sync   : std_logic_vector(1 downto 0) := (others => '1'); -- Metastability Removal
    signal button_stable : std_logic := '1';  -- Stable button state

begin

    -- **Generate Slow Clock Enable for Debouncing**
    process(clk)
    begin
        if rising_edge(clk) then
            if debounce_counter < DEBOUNCE_COUNT then
                debounce_counter <= debounce_counter + 1;
                slow_clk_enable <= '0'; -- Hold low while counting
            else
                debounce_counter <= 0; -- Reset counter
                slow_clk_enable <= '1'; -- Enable debounce check
            end if;
        end if;
    end process;

    -- **Double Flip-Flop Synchronization for Metastability Removal**
    process(clk)
    begin
        if rising_edge(clk) then
            button_sync(0) <= button_in;
            button_sync(1) <= button_sync(0);
        end if;
    end process;

    -- **Debounce Logic with Slow Clock Enable**
    process(clk)
    begin
        if rising_edge(clk) then
            if slow_clk_enable = '1' then  -- Check button state only when enabled
                if button_sync(1) /= button_stable then
                    button_stable <= button_sync(1); -- Update stable button state
                end if;
            end if;
        end if;
    end process;

    -- **Final Output (Active High)**
    button_out <= button_stable;

end Behavioral;
