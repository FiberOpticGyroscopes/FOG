LIBRARY  ieee;
USE ieee.STD_LOGIC_1164.ALL;
USE ieee.STD_LOGIC_arith.ALL;
USE ieee.STD_LOGIC_unsigned.ALL;

ENTITY  foct_closed_v3 IS
	PORT(	clk						:	IN 	STD_LOGIC;
			adin_1					:	IN 	STD_LOGIC_VECTOR(13 DOWNTO 0);
			lenth					:	IN 	STD_LOGIC_VECTOR(7 DOWNTO 0);		----光纤长度
			fre_div_startup			:	IN 	STD_LOGIC;							----分频数读取确认
			
			oo_state				:	OUT	STD_LOGIC_VECTOR(7 DOWNTO 0);		----状态
			oo_power				:	OUT	STD_LOGIC_VECTOR(15 DOWNTO 0);		----半波电压
			oo_16bit				:	OUT	STD_LOGIC_VECTOR(15 DOWNTO 0);		----测量电流
			oo_24bit				:	OUT	STD_LOGIC_VECTOR(23 DOWNTO 0);		----光功率
			daout					:	OUT	STD_LOGIC_VECTOR(15 DOWNTO 0);		----DA输出
			dkksc					:	OUT STD_LOGIC;							----输出使能
			
			adkkk					: 	OUT STD_LOGIC;							----AD时钟
			
			dakkk					:	OUT STD_LOGIC;							----DA时钟
			dakkk_Y					:	OUT STD_LOGIC;
			daout_Y					:	OUT	STD_LOGIC_VECTOR(11 DOWNTO 0);			
			
			dakkk_SLD				:	OUT STD_LOGIC;
			daout_SLD				:	OUT	STD_LOGIC_VECTOR(11 DOWNTO 0)		-----测量分频数
		);	
END  foct_closed_v3;

ARCHITECTURE GoodLuck OF foct_closed_v3 IS
	SIGNAL run_k					:	STD_LOGIC;
	SIGNAL dak						:	STD_LOGIC;
	SIGNAL dak_2pi					:	STD_LOGIC;
	SIGNAL adk						:	STD_LOGIC;
	SIGNAL adk2						:	STD_LOGIC;
	SIGNAL adk3						:	STD_LOGIC;
	SIGNAL dkk_ready				:	STD_LOGIC;

	SIGNAL fp_cnt					:	STD_LOGIC_VECTOR(15 DOWNTO 0);
	SIGNAL modu_cnt				:	STD_LOGIC_VECTOR(30 DOWNTO 0):= "0000000000000000000000000000000";
	SIGNAL cnt_2pi					:	STD_LOGIC_VECTOR(9 DOWNTO 0);
	SIGNAL cnt_2pi_z				:	STD_LOGIC_VECTOR(2 DOWNTO 0);
	SIGNAL cnt_2pi_f				:	STD_LOGIC_VECTOR(2 DOWNTO 0);
	SIGNAL s_ad_reg				:	STD_LOGIC_VECTOR(13 DOWNTO 0);

	SIGNAL out_reg					:	STD_LOGIC_VECTOR(25 DOWNTO 0);
	SIGNAL JFQ						:	STD_LOGIC_VECTOR(25 DOWNTO 0):= "00000000000000000000000000";
	SIGNAL JFQ_2pi					:	STD_LOGIC_VECTOR(25 DOWNTO 0);
	SIGNAL JFQ_shake				:	STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL power_sc_reg			:	STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL power_temp_reg		:	STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL power_add_reg			:	STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL power_last_reg		:	STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL power_out_reg			:	STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL power_aver_reg		:	STD_LOGIC_VECTOR(31 DOWNTO 0):= "00010100000000000000000000000000";
	SIGNAL power_aver_reg2		:	STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL aver_last_reg			:	STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL ready_ok				:	STD_LOGIC := '0';				

	SIGNAL ladder_reg				:	STD_LOGIC_VECTOR(25 DOWNTO 0):= "00000000000000000000000000";	
	SIGNAL ramp_reg				:	STD_LOGIC_VECTOR(25 DOWNTO 0):= "00000000000000000000000000";
	SIGNAL shake_sign				:	STD_LOGIC;
	SIGNAL shake_sign_delay		:	STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL shake_ramp				:	STD_LOGIC_VECTOR(15 DOWNTO 0);

	SIGNAL bias_phase				:	STD_LOGIC_VECTOR(15 DOWNTO 0);
	SIGNAL bias_phase_A			:	STD_LOGIC_VECTOR(15 DOWNTO 0):= "0000000000000000";
	SIGNAL bias_phase_B			:	STD_LOGIC_VECTOR(15 DOWNTO 0):= "0000000000000000";
	SIGNAL DA_reg					:	STD_LOGIC_VECTOR(15 DOWNTO 0);

	SIGNAL DA_sign_old_A			:	STD_LOGIC;
	SIGNAL DA_sign_old_B			:	STD_LOGIC;
	SIGNAL dm_sign_2pi			:	STD_LOGIC;
	SIGNAL dm_2pi_delay			:	STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL DA_reg_2pi				:	STD_LOGIC_VECTOR(11 DOWNTO 0);
	SIGNAL state_2pi				:	STD_LOGIC_VECTOR(1 DOWNTO 0);


	SIGNAL dm_2pi_reg				:	STD_LOGIC_VECTOR(25 DOWNTO 0);
	SIGNAL dm_2pi_z1				:	STD_LOGIC_VECTOR(13 DOWNTO 0);
	SIGNAL dm_2pi_f1				:	STD_LOGIC_VECTOR(13 DOWNTO 0);

	SIGNAL random_sign			:	STD_LOGIC;
	SIGNAL dm_sign_delay			:	STD_LOGIC_VECTOR(7 DOWNTO 0);
	SIGNAL dm_sign					:	STD_LOGIC;
	SIGNAL dm_k_delay				:	STD_LOGIC_VECTOR(7 DOWNTO 0);

	SIGNAL sjxl						:	STD_LOGIC_VECTOR(62 DOWNTO 0);
	SIGNAL random_k				:	STD_LOGIC;
	SIGNAL random_ready			:	STD_LOGIC;
	SIGNAL FeedBack_k				:	STD_LOGIC;
   SIGNAL dkksc_temp			   :  STD_LOGIC_VECTOR(3 DOWNTO 0);
	SIGNAL dkksc_new			   :  STD_LOGIC;
	SIGNAL div_out 			   :	STD_LOGIC_VECTOR(45 DOWNTO 0):= "0000000000000000000000000000000000000000000000";
	SIGNAL s_lenth				   :  STD_LOGIC_VECTOR(9 DOWNTO 0):= "0000000000";
	

COMPONENT div_46_22 IS
	PORT
	(
		denom		: IN STD_LOGIC_VECTOR (23 DOWNTO 0);
		numer		: IN STD_LOGIC_VECTOR (45 DOWNTO 0);
		quotient		: OUT STD_LOGIC_VECTOR (45 DOWNTO 0);
		remain		: OUT STD_LOGIC_VECTOR (23 DOWNTO 0)
	);
END COMPONENT div_46_22;

------------------------------------------------------------------------------------------------------
----------------------------------------分频时序------------------------------------------------------ 
------------------------------------------------------------------------------------------------------
BEGIN
	FP:	PROCESS(clk)
		VARIABLE N_fenpin:			STD_LOGIC_VECTOR(9 DOWNTO 0);							
	BEGIN
		IF(clk'EVENT AND clk = '1')THEN
		
		     if( s_lenth > "0001011011" and s_lenth < "0010010110")then
              N_fenpin := s_lenth;
              else
		        N_fenpin := "0001110100";----116
		     end if;
		     
			IF(fp_cnt < N_fenpin)THEN
				IF(fp_cnt = 1)THEN
					run_k <= '1';
				ELSIF(fp_cnt = 7)THEN
					run_k <= '0';
				END IF;
				
				IF(fp_cnt = 4)THEN
					random_ready <= '1';
				ELSIF(fp_cnt = 8)THEN
					random_ready <= '0';
				END IF;	
								
				IF(fp_cnt = 10)THEN
					dak <= '1';
				ELSIF(fp_cnt = 15)THEN
					dak <= '0';
				END IF;
				IF(fp_cnt = 20)THEN
					dak_2pi <= '1';
				ELSIF(fp_cnt = 25)THEN
					dak_2pi <= '0';
				END IF;

				IF((fp_cnt = N_fenpin-75))THEN
					adk <= '1';
				ELSIF((fp_cnt = N_fenpin-66))THEN
					adk <= '0';
				END IF;
				IF((fp_cnt = N_fenpin-63))THEN
					adk2 <= '1';
				ELSIF((fp_cnt = N_fenpin-59))THEN
					adk2 <= '0';
				END IF;
				
				IF((fp_cnt = N_fenpin-64))THEN
					adk3 <= '1';
				ELSIF((fp_cnt = N_fenpin-60))THEN
					adk3 <= '0';
				END IF;

				IF((fp_cnt = N_fenpin-57))THEN
					adk <= '1';
				ELSIF((fp_cnt = N_fenpin-48))THEN
					adk <= '0';
				END IF;	
				IF((fp_cnt = N_fenpin-45))THEN
					adk2 <= '1';
				ELSIF((fp_cnt = N_fenpin-41))THEN
					adk2 <= '0';
				END IF;
				IF((fp_cnt = N_fenpin-46))THEN
					adk3 <= '1';
				ELSIF((fp_cnt = N_fenpin-42))THEN
					adk3 <= '0';
				END IF;

				IF(fp_cnt = N_fenpin-29)THEN
					dakkk <= '1';
				ELSIF(fp_cnt = N_fenpin-20)THEN---115,
					dakkk <= '0';
				END IF;
				
				fp_cnt <= fp_cnt + 1;
			ELSE
				fp_cnt <= (OTHERS=>'0');
			END IF;
		END IF;
	END PROCESS FP;
------------------------------------------------------------------------------------------------------
----------------------------------------分频时序------------------------------------------------------ 
------------------------------------------------------------------------------------------------------	


------------------------------------------------------------------------------------------------------
----------------------------------------分频数读取---------------------------------------------------- 
------------------------------------------------------------------------------------------------------
fenshuduqu: process(clk)
begin
if(clk'event and clk='1')then
	if(fre_div_startup = '1')then
	s_lenth	 <= "00" & lenth;
	end if;
end if;
end process fenshuduqu;

------------------------------------------------------------------------------------------------------
----------------------------------------分频数读取---------------------------------------------------- 
------------------------------------------------------------------------------------------------------




------------------------------------------------------------------------------------------------------
----------------------------------------测量输出及报警-------------------------------------------------- 
------------------------------------------------------------------------------------------------------
	run_k_UP:	PROCESS(run_k)	
	BEGIN
		IF(run_k'EVENT AND run_k = '1')THEN
			modu_cnt <= modu_cnt + 1;
				
			IF(modu_cnt(18 DOWNTO 0) = 0)THEN				
				power_aver_reg2 <= power_add_reg - aver_last_reg;
				aver_last_reg <= power_add_reg;				
			    IF(power_aver_reg2(31 DOWNTO 16) < x"00B4")THEN----180,x"00B4"
				power_aver_reg <= "00010100000000000000000000000000";
				else
			   	power_aver_reg <= power_aver_reg2;			
			    END IF;			   			    
			END IF;
			
			IF(modu_cnt(24 DOWNTO 0) = "1000100000000000000000000")THEN			
		       ready_ok <= '1';
			end if;
			
			IF(modu_cnt(6 DOWNTO 0) = 1)THEN
				power_out_reg <= power_add_reg - power_last_reg;
				power_last_reg <= power_add_reg;
			END IF;	
			

			IF(modu_cnt(1 DOWNTO 0) = 0)THEN
				if( ready_ok = '0') then
				dkk_ready <= '0';
				oo_state(7) <= '0';	
				elsif ( ready_ok = '1') then
				dkk_ready <= '1';
				oo_state(7) <= '1';	
				end if;
				
				out_reg <= ramp_reg;						
				--oo_16bit <= ramp_reg(20 DOWNTO 5) - out_reg(20 DOWNTO 5);
				oo_16bit <= ramp_reg(18 DOWNTO 3) - out_reg(18 DOWNTO 3);--20210928
			END IF;

		

			IF( (modu_cnt(1 DOWNTO 0) = 2) )THEN
				dkk_ready <= '0';	
				
				if((ready_ok = '1'))then
				oo_24bit <= ("00000000" & power_aver_reg2(31 DOWNTO 16));	
				end if;
				
			    IF(((power_aver_reg2(31 DOWNTO 16) < x"00C8" )  or (power_out_reg(31 DOWNTO 4) < x"0010")) and  (ready_ok = '1'))THEN----200,x"00C8"
					oo_state(0) <= '1';	
				ELSE
					oo_state(0) <= '0';		
				END IF;
			    
			    IF((power_aver_reg2(31 DOWNTO 16) < x"0190" ) and  (ready_ok = '1'))THEN----400,x"0190"
					oo_state(1) <= '1';	
				ELSE
					oo_state(1) <= '0';		
			    END IF;
											
			END IF;
			
			IF((modu_cnt(1 DOWNTO 0) = 3))THEN	
				
				if((ready_ok = '1'))then
				  daout_SLD <= "00" & s_lenth;
              oo_power <= "0000" & DA_reg_2pi; 	
				end if;             
		
				IF(((DA_reg_2pi = "010000000000" ) or (DA_reg_2pi = "110000000000" )) and  (ready_ok = '1'))THEN----640,x"0080"x5
					oo_state(2) <= '1';	
				ELSE
					oo_state(2) <= '0';		
				END IF;	
				
				IF( (s_lenth < "0001011011" or s_lenth > "0010010110" ) and  (ready_ok = '1'))THEN
					oo_state(3) <= '1';	
				ELSE
					oo_state(3) <= '0';		
				END IF;					
	                
			END IF;

		END IF;
	END PROCESS run_k_UP;
------------------------------------------------------------------------------------------------------
----------------------------------------测量输出及报警-------------------------------------------------- 
------------------------------------------------------------------------------------------------------	
	
	
	
------------------------------------------------------------------------------------------------------
------------------------------------------调制反馈----------------------------------------------------- 
------------------------------------------------------------------------------------------------------
	run_k_DOWN:	PROCESS(run_k)
	BEGIN
		IF(run_k'EVENT AND run_k = '0')THEN
			IF(modu_cnt(0) = '1')THEN
				IF(random_sign = '0')THEN
					bias_phase_A <= bias_phase_A + "0100000000000000";
					dm_sign <= '0';
				ELSE
					bias_phase_A <= bias_phase_A - "0100000000000000";
					dm_sign <= '1';
				END IF;
			ELSIF(modu_cnt(0) = '0')THEN
				IF(random_sign = '0')THEN
					bias_phase_B <= bias_phase_B - "0100000000000000";
					dm_sign <= '1';
				ELSE
					bias_phase_B <= bias_phase_B + "0100000000000000";
					dm_sign <= '0';
				END IF;
			END IF;
		END IF;
	END PROCESS run_k_DOWN;

	MODULATE_GENERATOR_UP:	PROCESS(dak)
	BEGIN
		IF(dak'EVENT AND dak = '1')THEN
			IF(modu_cnt(0) = '1')THEN
				bias_phase <= bias_phase_A;
			ELSIF(modu_cnt(0) = '0')THEN
				bias_phase <= bias_phase_B;
			END IF;
		END IF;
	END PROCESS MODULATE_GENERATOR_UP;

	MODULATE_GENERATOR_DOWN:	PROCESS(dak)
	BEGIN
		IF(dak'EVENT AND dak = '0')THEN
			--DA_reg <= bias_phase + ramp_reg(17 DOWNTO 2) + shake_ramp;
			DA_reg <= bias_phase + ramp_reg(15 DOWNTO 0) + shake_ramp;  --20210928
		END IF;
	END PROCESS MODULATE_GENERATOR_DOWN;
	
	
		dak_2pi_up:	PROCESS(dak_2pi)
	BEGIN
		IF(dak_2pi'EVENT AND dak_2pi = '1')THEN
			IF(modu_cnt(0) = '1')THEN
				DA_sign_old_B <= DA_reg(15);
			ELSIF(modu_cnt(0) = '0')THEN
				DA_sign_old_A <= DA_reg(15);
			END IF;
		END IF;
	END PROCESS dak_2pi_up;

	dak_2pi_down:	PROCESS(dak_2pi)
	BEGIN
		IF(dak_2pi'EVENT AND dak_2pi = '0')THEN
			IF(modu_cnt(0) = '1')THEN
				IF((DA_sign_old_A = '0') AND (DA_reg(15) = '1') AND (dm_sign ='1'))THEN
					dm_sign_2pi <= '1';
				ELSIF((DA_sign_old_A = '1') AND (DA_reg(15) = '0') AND (dm_sign ='0'))THEN
					dm_sign_2pi <= '1';
				ELSE
					dm_sign_2pi <= '0';
				END IF;
			ELSIF(modu_cnt(0) = '0')THEN
				IF((DA_sign_old_B = '0') AND (DA_reg(15) = '1') AND (dm_sign ='1'))THEN
					dm_sign_2pi <= '1';
				ELSIF((DA_sign_old_B = '1') AND (DA_reg(15) = '0') AND (dm_sign ='0'))THEN
					dm_sign_2pi <= '1';
				ELSE
					dm_sign_2pi <= '0';
				END IF;
			END IF;
		END IF;
	END PROCESS dak_2pi_down;
	
	
------------------------------------------------------------------------------------------------------
------------------------------------------调制反馈----------------------------------------------------- 
------------------------------------------------------------------------------------------------------
	
	
	
------------------------------------------------------------------------------------------------------
------------------------------------------脉冲延时----------------------------------------------------- 
------------------------------------------------------------------------------------------------------
	
	jt_ych:	PROCESS(adk)
	BEGIN
		IF(adk'EVENT AND adk = '1')THEN
			dm_sign_delay(7) <= dm_sign_delay(6);
			dm_sign_delay(6) <= dm_sign_delay(5);
			dm_sign_delay(5) <= dm_sign_delay(4);
			dm_sign_delay(4) <= dm_sign_delay(3);
			dm_sign_delay(3) <= dm_sign_delay(2);
			dm_sign_delay(2) <= dm_sign_delay(1);
			dm_sign_delay(1) <= dm_sign_delay(0);
			dm_sign_delay(0) <= dm_sign;
		END IF;
	END PROCESS jt_ych;

	fk_ych:	PROCESS(adk)
	BEGIN
		IF(adk'EVENT AND adk = '1')THEN
			dm_k_delay(7) <= dm_k_delay(6);
			dm_k_delay(6) <= dm_k_delay(5);
			dm_k_delay(5) <= dm_k_delay(4);
			dm_k_delay(4) <= dm_k_delay(3);
			dm_k_delay(3) <= dm_k_delay(2);
			dm_k_delay(2) <= dm_k_delay(1);
			dm_k_delay(1) <= dm_k_delay(0);
			dm_k_delay(0) <= random_k;
		END IF;
	END PROCESS fk_ych;

	jt_2pi_ych:	PROCESS(adk)
	BEGIN
		IF(adk'EVENT AND adk = '1')THEN
			dm_2pi_delay(7) <= dm_2pi_delay(6);
			dm_2pi_delay(6) <= dm_2pi_delay(5);
			dm_2pi_delay(5) <= dm_2pi_delay(4);
			dm_2pi_delay(4) <= dm_2pi_delay(3);
			dm_2pi_delay(3) <= dm_2pi_delay(2);
			dm_2pi_delay(2) <= dm_2pi_delay(1);
			dm_2pi_delay(1) <= dm_2pi_delay(0);
			dm_2pi_delay(0) <= dm_sign_2pi;
		END IF;
	END PROCESS jt_2pi_ych;

	shake_ych:	PROCESS(adk)
	BEGIN
		IF(adk'EVENT AND adk = '1')THEN
			shake_sign_delay(7) <= shake_sign_delay(6);
			shake_sign_delay(6) <= shake_sign_delay(5);
			shake_sign_delay(5) <= shake_sign_delay(4);
			shake_sign_delay(4) <= shake_sign_delay(3);
			shake_sign_delay(3) <= shake_sign_delay(2);
			shake_sign_delay(2) <= shake_sign_delay(1);
			shake_sign_delay(1) <= shake_sign_delay(0);
			shake_sign_delay(0) <= shake_sign;
		END IF;
	END PROCESS shake_ych;
	
------------------------------------------------------------------------------------------------------
------------------------------------------脉冲延时----------------------------------------------------- 
------------------------------------------------------------------------------------------------------
	
	
	
------------------------------------------------------------------------------------------------------
------------------------------------------采样积分----------------------------------------------------- 
------------------------------------------------------------------------------------------------------
	ad_true:	PROCESS(adk2)
	BEGIN
		IF(adk2'EVENT AND adk2 = '1')THEN
				s_ad_reg <= adin_1;
		END IF;
	END PROCESS ad_true;


	P_jfq:	PROCESS(adk3)
	BEGIN
		IF(adk3'EVENT AND adk3 = '0')THEN
			IF(dm_sign_delay(5) = '0')THEN
				JFQ <= JFQ + ("000000000000" & s_ad_reg(13 DOWNTO 0));
			ELSE
				JFQ <= JFQ - ("000000000000" & s_ad_reg(13 DOWNTO 0));
			END IF;
		END IF;
	END PROCESS P_jfq;

	P_jfq_2pi:	PROCESS(adk3)
	BEGIN
		IF(adk3'EVENT AND adk3 = '0')THEN
			IF((cnt_2pi_z > 1) AND (cnt_2pi_f > 1))THEN
				dm_2pi_reg <= (("000000000000") & dm_2pi_z1) - (("000000000000") & dm_2pi_f1);
				IF((state_2pi = "00") OR ((state_2pi = "01") AND (dm_2pi_reg(25) = '0')) OR ((state_2pi = "10") AND (dm_2pi_reg(25) = '1')))THEN
					JFQ_2pi <= JFQ_2pi + dm_2pi_reg;
				END IF;

				cnt_2pi_z <= ("000");
				cnt_2pi_f <= ("000");
			END IF;

			IF(dm_2pi_delay(5) = '0')THEN
				dm_2pi_z1 <= s_ad_reg(13 DOWNTO 0);
				cnt_2pi_z <= cnt_2pi_z +1;
			ELSE
				dm_2pi_f1 <= s_ad_reg(13 DOWNTO 0);
				cnt_2pi_f <= cnt_2pi_f +1;
			END IF;
		END IF;
	END PROCESS P_jfq_2pi;

	P_jfq_shake:	PROCESS(adk3)
	BEGIN
		IF(adk3'EVENT AND adk3 = '0')THEN
			IF(shake_sign_delay(5) = '0')THEN
				IF(dm_sign_delay(5) = '0')THEN
					JFQ_shake <= JFQ_shake - ("000000000000000000" & s_ad_reg(13 DOWNTO 0));
				ELSE
					JFQ_shake <= JFQ_shake + ("000000000000000000" & s_ad_reg(13 DOWNTO 0));
				END IF;
			ELSE
				IF(dm_sign_delay(5) = '0')THEN
					JFQ_shake <= JFQ_shake + ("000000000000000000" & s_ad_reg(13 DOWNTO 0));
				ELSE
					JFQ_shake <= JFQ_shake - ("000000000000000000" & s_ad_reg(13 DOWNTO 0));
				END IF;
			END IF;		END IF;
	END PROCESS P_jfq_shake;
	
------------------------------------------------------------------------------------------------------
------------------------------------------采样积分----------------------------------------------------- 
------------------------------------------------------------------------------------------------------
	
	
	
------------------------------------------------------------------------------------------------------
------------------------------------------第二闭环----------------------------------------------------- 
------------------------------------------------------------------------------------------------------	
	
	DA_2pi:	PROCESS(dak_2pi)		
	BEGIN
		IF(dak_2pi'EVENT AND dak_2pi = '1')THEN
			IF(cnt_2pi < 31)THEN
				IF(cnt_2pi = 1)THEN
					DA_reg_2pi <= "100000000000" + (JFQ_2pi(23 DOWNTO 12));
				ELSIF(cnt_2pi = 6)THEN
					IF(DA_reg_2pi < 1024)THEN				--1024
						DA_reg_2pi <= "010000000000";
						state_2pi <= "01";					
					ELSIF(DA_reg_2pi > 3072)THEN			--3072
						DA_reg_2pi <= "110000000000";
						state_2pi <= "10";					
					ELSE
						state_2pi <= "00";
					END IF;
				ELSIF(cnt_2pi = 8)THEN
					daout_Y <= DA_reg_2pi;
				ELSIF(cnt_2pi = 10)THEN
					dakkk_Y <= '1';
				ELSIF(cnt_2pi = 15)THEN
					dakkk_Y <= '0';
				END IF;
				cnt_2pi <= cnt_2pi+ 1;
			ELSE
				cnt_2pi <= (OTHERS => '0');
			END IF;
		END IF;
	END PROCESS DA_2pi;
	
------------------------------------------------------------------------------------------------------
------------------------------------------第二闭环----------------------------------------------------- 
------------------------------------------------------------------------------------------------------	
	
	
	
------------------------------------------------------------------------------------------------------
------------------------------------------结算及反馈--------------------------------------------------- 
------------------------------------------------------------------------------------------------------	
	xhsc:	PROCESS(FeedBack_k)
	VARIABLE tt1:			STD_LOGIC_VECTOR(31 DOWNTO 0);
	BEGIN
		IF(FeedBack_k'EVENT AND FeedBack_k = '1')THEN
			ladder_reg <= JFQ;
			power_temp_reg <= JFQ_shake;
			tt1:= JFQ_shake - power_temp_reg;
		   if(tt1(31)= '0') then
           power_sc_reg <=tt1;
           elsif(tt1(31)= '1') then
           power_sc_reg <="11111111111111111111111111111111" - tt1 + "00000000000000000000000000000001";                         
           end if;
		END IF;
	END PROCESS xhsc;	

	

	xhlj:	PROCESS(FeedBack_k)
	BEGIN
		IF(FeedBack_k'EVENT AND FeedBack_k = '0')THEN
			power_add_reg <= power_add_reg + power_sc_reg;
		END IF;
	END PROCESS xhlj;

	RANDOM_GENERATOR:	PROCESS(random_ready)
		VARIABLE i:			STD_LOGIC_VECTOR(7 DOWNTO 0);
	BEGIN
		IF(random_ready'EVENT AND random_ready = '1' AND random_k = '1' )THEN
--			ramp_reg <= ramp_reg + ladder_reg;
			ramp_reg <= ramp_reg + div_out(35 DOWNTO 10);
			IF(modu_cnt(1) = '0')THEN
				shake_ramp <= shake_ramp + "0000001000000000";
				shake_sign <= '0';
			ELSE
				shake_ramp <= shake_ramp - "0000001000000000";
				shake_sign <= '1';
			END IF;		

			random_sign <= sjxl(0);
			IF(sjxl = 0)THEN
				sjxl <= "110011101011001110000001111011101111000100110010111000110010000";
			ELSE
				FOR i IN 0 TO 61 LOOP
					sjxl(i) <= sjxl(i+1);
				END LOOP;
				sjxl(62) <= sjxl(0) XOR sjxl(1);
			END IF;
		END IF;
	END PROCESS RANDOM_GENERATOR;
	
------------------------------------------------------------------------------------------------------
------------------------------------------结算及反馈--------------------------------------------------- 
------------------------------------------------------------------------------------------------------
	

------------------------------------------------------------------------------------------------------
------------------------------------------时序控制----------------------------------------------------- 
------------------------------------------------------------------------------------------------------	
		
	random_k <= modu_cnt(0);
	FeedBack_k <= dm_k_delay(5);

	adkkk <= adk;
	daout <= DA_reg;
	
	div1 : div_46_22
	PORT MAP
	(		
		denom		=> ("00000000" & power_aver_reg(31 DOWNTO 16)),
		numer		=> ladder_reg & "00000000000000000000",
		quotient	=> div_out 
	);	
	
	
	PROCESS(clk)	------------------使能展宽							
	BEGIN
	IF(clk'EVENT AND clk = '1')THEN
		dkksc_temp(0)			<= dkk_ready;
		dkksc_temp(3 DOWNTO 1)	<= dkksc_temp(2 DOWNTO 0);
	END IF;
	END PROCESS;
	--
	PROCESS(clk)								
	BEGIN
	IF(clk'EVENT AND clk = '1')THEN
		IF(dkksc_temp/=0)THEN
			dkksc_new	<= '1';
		ELSE
			dkksc_new	<= '0';
		END IF;
	END IF;
	END PROCESS;

dkksc <= dkksc_new;
------------------------------------------------------------------------------------------------------
------------------------------------------时序控制----------------------------------------------------- 
------------------------------------------------------------------------------------------------------
	

END GoodLuck;
