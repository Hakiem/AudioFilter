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
    signal received_data        : std_logic_vector(11 downto 0);
    signal transaction_done     : std_logic := '0';
    signal spi_bit_counter      : integer range 0 to 15 := 0;

    type state_type is (IDLE, ASSERT_CS, SEND_MCP3202_CMD, RCV_DATA, DONE);
    signal state : state_type := IDLE;

begin

    spi_clk <= spi_clk_internal;
    adc_result <= received_data;

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
            data_out => received_data
        );

    process(spi_clk_internal, rst)
    begin
        if rst = '0' then
            shift_data <= (others => '0');  -- Reset shift register
            spi_bit_counter <= 0;          -- Reset bit counter
        elsif rising_edge(spi_clk_internal) then
            if shift_enable = '1' then
                shift_data <= shift_data(14 downto 0) & miso;  -- Shift in new MISO bit
                spi_bit_counter <= spi_bit_counter + 1;         -- Increment counter on each SPI clock
            elsif state = DONE then
                spi_bit_counter <= 0;  -- Reset bit counter
            end if;
        end if;
    end process;
    
    -- SPI Controller FSM (State Machine)
    process(spi_clk_internal)
    begin
        if rising_edge(spi_clk_internal) then
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
                        state <= SEND_MCP3202_CMD;  -- Move to SEND_MCP3202_CMD state
                    -- **SEND_MCP3202_CMD State**: Send the command word to MCP3202
                    when SEND_MCP3202_CMD =>
                        shift_enable <= '1';       -- Continue shifting data
                        if spi_bit_counter = 15 then
                            -- If data has started shifting in, move to RCV_DATA state
                            shift_enable <= '0';    -- Stop shifting data
                            state <= RCV_DATA;      -- Move to RCV_DATA state
                        end if;
                    -- **RECEIVE State**: Capture the ADC data from MCP3202
                    when RCV_DATA =>
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
