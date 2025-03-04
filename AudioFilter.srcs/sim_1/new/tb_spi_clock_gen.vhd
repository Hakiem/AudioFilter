library ieee;
use ieee.std_logic_1164.all;

entity tb_spi_clock_gen is
end tb_spi_clock_gen;

architecture Behavioral of tb_spi_clock_gen is
    constant CLK_PERIOD : time := 10 ns; -- 100 MHz FPGA Clock (1/100M Hz)
    
    signal clk_tb  : std_logic := '0'; -- Testbench System Clock
    signal rst_tb  : std_logic := '1'; -- Reset signal
    signal sck_tb  : std_logic := '0'; -- SPI Clock Output
begin

    -- DUT (Device Under Test)
    uut : entity work.spi_clock_gen
        generic map (CLK_DIV => 56)
        port map (
            clk     => clk_tb,
            rst     => rst_tb,
            spi_clk  => sck_tb
        );

    -- Clock process (100MHz)
    clk_tb <= not clk_tb after CLK_PERIOD / 2;
    
    -- Test sequence 
    stim_process: process
    begin
        -- Hold reset high initially
        wait for 100 ns;
        rst_tb <= '0';
        
        -- Run for some time to capture SPI clock behavior
        wait for 2 ms;
        
        -- Stop Simulation
        assert false report "Test Completed" severity failure;
        
    end process; 

end Behavioral;
