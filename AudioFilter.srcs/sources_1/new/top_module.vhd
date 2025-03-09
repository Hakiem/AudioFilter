library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity top_module is
    port (
        clk         : in  std_logic;                        -- 100 MHz System Clock
        button_raw  : in  std_logic;                        -- Button Input (Active High)
        miso        : in  std_logic;                        -- Data from MCP3202 (ADC output)
        mosi        : out std_logic;                        -- Data to MCP3202 (Config input)
        cs          : out std_logic;                        -- Chip Select (Active Low)
        spi_clk     : out std_logic                        -- SPI Clock
    );
end top_module;

architecture Behavioral of top_module is

    -- **Internal Signals**
    signal rst_debounced : std_logic;    -- Debounced reset signal (Active Low)
    signal adc_result    : std_logic_vector(11 downto 0);  -- Local ADC result

begin

    uut_button_debouncer : entity work.button_debouncer
        generic map (
            CLK_FREQ         => 100_000_000,  -- 100 MHz
            DEBOUNCE_TIME_MS => 10            -- 10 ms debounce
        )
        port map (
            clk        => clk,
            button_in  => button_raw,  -- Active High Button
            button_out => rst_debounced -- Active Low Reset
        );

    uut_spi_controller : entity work.spi_controller
        port map (
            clk         => clk,
            rst         => rst_debounced,  -- Use debounced reset signal
            channel_sel => '0',            -- Always reading from Channel 0
            miso        => miso,
            mosi        => mosi,
            cs          => cs,
            busy        => open,           -- Not connected for now
            adc_result  => adc_result,     -- Store ADC result
            spi_clk     => spi_clk
        );
        
end Behavioral;
