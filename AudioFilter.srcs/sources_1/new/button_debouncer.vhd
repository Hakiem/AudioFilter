library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity button_debouncer is
    generic(
        CLK_FREQ         : integer  := 100_000_000;  -- 100 MHz
        DEBOUNCE_TIME_MS : integer  := 1_000_000  -- 10 ms
    );
    port(
        clk             : in std_logic;  -- System Clock
        button_in       : in std_logic;  -- Raw Button Input (Active Low)
        button_out      : out std_logic  -- Debounced Button Output (Active Low)
    );
end button_debouncer;

architecture Behavioral of button_debouncer is

    constant DEBOUNCE_COUNT : integer := (CLK_FREQ / 1000) * DEBOUNCE_TIME_MS;   -- Number of clock cycles for debounce period
    signal button_sync  : std_logic_vector(1 downto 0) := (others => '1');       -- Flip flop 1 and 2 for metastability
    signal counter      : integer range 0 to DEBOUNCE_COUNT := 0;                -- Debounce counter
    signal button_stable: std_logic := '0';                                      -- Stable button output

begin

    -- Double flip-flop synchronizer to remove metastability
    process(clk)
    begin
        if rising_edge(clk) then

            -- Metastability filter : Double flip-flop synchronizer
            button_sync(0) <= button_in;
            button_sync(1) <= button_sync(0);

            -- Debounce logic
            if button_sync(1) /= button_stable then
                -- **If button state changes, start counting**
                if counter < DEBOUNCE_COUNT then
                    counter <= counter + 1;
                else
                    button_stable <= button_sync(1); -- Accept stable state
                    counter <= 0; -- Reset counter
                end if;
            else
                counter <= 0; -- Reset counter if input remains stable
            end if;
        end if;
    end process;

    button_out <= not button_stable; -- Output debounced button state

end Behavioral;
