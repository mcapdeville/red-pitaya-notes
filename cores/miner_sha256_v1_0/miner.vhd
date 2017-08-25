library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity miner is
	generic ( DEPTH : integer );
	Port ( clk : in  STD_LOGIC;
           data : in  STD_LOGIC_VECTOR (95 downto 0);
           state : in  STD_LOGIC_VECTOR (255 downto 0);
           result : out  STD_LOGIC_VECTOR (31 downto 0);
           found : out STD_LOGIC;
	   running  : out STD_LOGIC;
	   stop : in STD_LOGIC);
end miner;

architecture Behavioral of miner is

	COMPONENT sha256_pipeline
	generic ( DEPTH : integer );
	PORT(
		clk : IN std_logic;
      		step : in  STD_LOGIC_VECTOR (5 downto 0);
		state : IN std_logic_vector(255 downto 0);
		input : IN std_logic_vector(511 downto 0);          
		hash : OUT std_logic_vector(255 downto 0));
	END COMPONENT;
	
	constant innerprefix : std_logic_vector(383 downto 0) := x"000002800000000000000000000000000000000000000000000000000000000000000000000000000000000080000000";
	constant outerprefix : std_logic_vector(255 downto 0) := x"0000010000000000000000000000000000000000000000000000000080000000";
	constant outerstate : std_logic_vector(255 downto 0) := x"5be0cd191f83d9ab9b05688c510e527fa54ff53a3c6ef372bb67ae856a09e667";
	
	signal innerdata : std_logic_vector(511 downto 0);
	signal outerdata : std_logic_vector(511 downto 0);
	signal innerhash : std_logic_vector(255 downto 0);
	signal outerhash : std_logic_vector(255 downto 0);

	signal step : STD_LOGIC_VECTOR (5 downto 0);
	signal nonce : STD_LOGIC_VECTOR (31 downto 0);
begin
	
	innerdata <= innerprefix & nonce & data;
   	outerdata <= outerprefix & innerhash;
	result <= nonce - 2 * 2 ** DEPTH;

	inner: sha256_pipeline
	   generic map ( DEPTH => DEPTH )
		port map (
			clk => clk,
			step => step,
			state => state,
			input => innerdata,
			hash => innerhash
		);					 

	outer: sha256_pipeline
	   generic map ( DEPTH => DEPTH )
		port map (
			clk => clk,
			step => step,
			state => outerstate,
			input => outerdata,
			hash => outerhash
		);					 

	process(clk,stop)
		variable run:STD_LOGIC;
		variable oe:STD_LOGIC;
		variable istep:STD_LOGIC_VECTOR (5 downto 0);
		variable inonce:STD_LOGIC_VECTOR (31 downto 0);
	begin
		if (rising_edge(clk)) then
			if (stop = '0') then
				if (oe = '1' and outerhash(255 downto 224) = x"00000000" and istep = "000000") then
					run := '0';
					found <= '1';
				end if;
				if ( run  = '1' ) then
					if (istep = (2 ** (6 - DEPTH) - 1)) then
						istep := "000000";
						inonce := inonce + 1;
						if (inonce = 2 * 2 ** DEPTH) then
							if (oe = '1') then
								run := '0';
							else
								oe := '1';
							end if;
						end if;
					else
						istep := istep + 1;
					end if;
				end if;
				running <= run;
			else		
				run := '1';
				oe := '0';
				istep := "000000";
				inonce := x"00000000";
				found <= '0';
				running <= '0';
			end if;
			step <= istep;
			nonce <= inonce;
		end if;
	end process;

end Behavioral;
