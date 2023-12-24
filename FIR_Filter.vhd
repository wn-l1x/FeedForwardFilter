-- FILEPATH: /d:/Wendy/PSD/FIR_Filter.vhd
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.delay_pkg.all;

entity FIR_Filter is
    port (
        clk : in std_logic;
        control_word : in std_logic_vector(7 downto 0)
    );
end FIR_Filter;

architecture rtl of FIR_Filter is
    
---port initialization---------------------------
    component Adder is
        port (
            adder_in : array_8:= (others => (others => '0'));
            adder_out : out std_logic_vector(7 downto 0)
        );
    end component Adder;

    component Amplifier is
        port(
            coefficient : in std_logic_vector(7 downto 0);
            amp_in : in std_logic_vector(7 downto 0);
            amp_out : out std_logic_vector(7 downto 0)
        );
    end component Amplifier;

    component Sample_Delay is
        port(
        data_current : in integer;
        order : in integer;
        delay_in : in array_8;  
        delay_out : out std_logic_vector(7 downto 0)
        );
    end component Sample_Delay;

---signal initialization-------------------------
    type state_list is (FETCH_ORDER, FETCH_INPUT, FETCH_AMP, COUNT, DONE);
    signal state : state_list := FETCH_ORDER;
    signal order : integer;
    signal data_c : integer := 0;
    signal s_delay_in : array_8;
    signal s_delay_out : array_8;
    signal s_coefficient_list : array_8;
    signal s_amp_in : array_8;
    signal s_amp_out : array_8;
    signal s_adder_in : array_8;
    signal s_adder_out : std_logic_vector(7 downto 0);
    
    begin
        --component generation
        amp_delay: for i in 0 to 7 generate
                gen_delay: Sample_Delay port map(
                    data_current => data_c,
                    order => i,
                    delay_in => s_delay_in,
                    delay_out => s_delay_out(i)
                );
                gen_amp: Amplifier port map(
                    coefficient => s_coefficient_list(i),
                    amp_in => s_amp_in(i),
                    amp_out => s_amp_out(i)
                );
            end generate;

            gen_adder: Adder port map(
                adder_in => s_adder_in,
                adder_out => s_adder_out
            );

        process(clk)
        begin
            if rising_edge(clk) then
                case state is
                    when FETCH_ORDER=>
                        order <= to_integer(unsigned(control_word(7 downto 5)));
                        state <= FETCH_INPUT;
                    
                        when FETCH_INPUT=>
                        if rising_edge(clk) then
                            s_delay_in(data_c) <= control_word(7 downto 0); 
                            data_c <= data_c + 1; 
                        end if;
                        if data_c = order then 
                            data_c <= 0;
                            state <= FETCH_AMP;
                        end if;

                    when FETCH_AMP =>
                            if rising_edge(clk) then
                                s_coefficient_list(data_c) <= control_word(7 downto 0); 
                                data_c <= data_c + 1; 
                                end if;
                                if data_c = order then 
                                    data_c <= 0;
                                    state <= count;
                                end if;

                    when COUNT =>
                        data_c <= 0;
                        s_amp_in(data_c) <= s_delay_out(data_c);
                    when DONE =>
                        state <= FETCH_ORDER;   
                end case;
            end if;
        end process;
                          
    end architecture rtl;
