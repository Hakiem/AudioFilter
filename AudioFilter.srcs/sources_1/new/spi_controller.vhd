library ieee;
use ieee.std_logic_1164.all;

entity spi_controller is
    Port (
        clk         : in  std_logic;                        -- 100 MHz System Clock
        rst         : in  std_logic;                        -- Active-Low Reset
        channel_sel : in  std_logic;                        -- Select Channel (0 = CH0, 1 = CH1)
        miso        : in  std_logic;                        -- Data from MCP3202 (ADC output)
        mosi        : out std_logic;                        -- Data to MCP3202 (Config input)
        cs          : out std_logic;                        -- Chip Select (Active Low)
        busy        : out std_logic;                        -- 1 = SPI Transaction Active, 0 = Ready
        adc_result  : out std_logic_vector(11 downto 0);    -- Final 12-bit ADC Output
        spi_clk     : out std_logic
    );
end spi_controller;

architecture Behavioral of spi_controller is

    -- Internal Signals
    signal spi_clk_internal     : std_logic := '0'; -- Internal SPI Clock
    signal shift_enable         : std_logic := '0';
    signal shift_data           : std_logic_vector(15 downto 0);
    signal received_data        : std_logic_vector(15 downto 0);
    signal transaction_done     : std_logic := '0';

    type state_type is (IDLE, ASSERT_CS, SEND, RECEIVE, DONE);
    signal state : state_type := IDLE;

begin

    spi_clk <= spi_clk_internal;

    -- Instantiate SPI Clock Generator (Generates ~1.8 MHz SPI Clock)
    uut_spi_clk : entity work.spi_clock_gen
        generic map (CLK_DIV => 56)
        port map (
            clk         => clk,
            rst         => rst,
            spi_clk     => spi_clk_internal -- Internal SPI Clock signal
        );

    -- Instantiate SPI Shift Register
    uut_spi_shift : entity work.spi_shift_register
        port map (
            spi_clk  => spi_clk_internal,    
            rst      => rst,
            shift    => shift_enable,
            miso     => miso,
            mosi     => mosi,
            data_in  => shift_data,
            data_out => received_data(15 downto 4)
        );

    -- SPI Controller FSM (State Machine)
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '0' then
                state               <= IDLE;
                cs                  <= '1'; -- Deselect MCP3202
                busy                <= '0'; -- Ready
                shift_enable        <= '0';
            else
                case state is
                    -- **IDLE State**: Wait before starting a new transaction
                    when IDLE => 
                        busy    <= '1';
                        cs      <= '0'; -- Deselect MCP3202. Chip select High (Not Active)
                        state   <= ASSERT_CS;
                    -- **ASSERT_CS State**: Enable MCP3202 and prepare SPI transaction
                    when ASSERT_CS =>
                        cs      <= '0'; -- Select MCP3202. Chip select Low (Active)
                        busy    <= '1'; -- Indicate SPI transaction is in progress

                        -- **Select MCP3202 Channel (CH0 or CH1)**
                        if channel_sel = '0' then
                            shift_data <= x"C000";  -- CH0, Single-Ended Command
                        else
                            shift_data <= x"E000";  -- CH1, Single-Ended Command
                        end if;

                        shift_enable <= '1';        -- Start shifting data to MCP3202
                        state <= SEND;              -- Move to SEND state
                    -- **SEND State**: Send the command word to MCP3202
                    when SEND =>
                        shift_enable <= '1';       -- Continue shifting data
                        if received_data(15 downto 4) /= "000000000000" then
                            -- If data has started shifting in, move to RECEIVE state
                            shift_enable <= '0';    -- Stop shifting data
                            state <= RECEIVE;       -- Move to RECEIVE state
                        end if;
                    -- **RECEIVE State**: Capture the ADC data from MCP3202
                    when RECEIVE =>
                        shift_enable        <= '0';    -- Stop shifting data
                        transaction_done    <= '1';    -- Mark transaction as complete
                        state               <= DONE;   -- Move to DONE state
                    -- **DONE State**: Transaction is complete
                    when DONE =>
                        busy                <= '0';     -- Ready and transaction complete
                        cs                  <= '1';     -- Deselect MCP3202 (CS HIGH)
                        state               <= IDLE;    -- Move back to IDLE state
                        transaction_done    <= '0';     -- Clear/Reset transaction done flag

                        -- **Restart Sampling Immediately**
                        state <= IDLE;
                    -- **Default Case**: Safety fallback
                    when others =>
                        state <= IDLE;
                end case;
            end if;
        end if;
    end process;

end Behavioral;
