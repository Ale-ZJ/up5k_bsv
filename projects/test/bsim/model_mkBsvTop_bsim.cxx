/*
 * Generated by Bluespec Compiler, version 2014.07.A (build 34078, 2014-07-30)
 * 
 * On Tue May 19 23:26:45 PDT 2020
 * 
 */
#include "bluesim_primitives.h"
#include "model_mkBsvTop_bsim.h"

#include <cstdlib>
#include <time.h>
#include "bluesim_kernel_api.h"
#include "bs_vcd.h"
#include "bs_reset.h"


/* Constructor */
MODEL_mkBsvTop_bsim::MODEL_mkBsvTop_bsim()
{
  mkBsvTop_bsim_instance = NULL;
}

/* Function for creating a new model */
void * new_MODEL_mkBsvTop_bsim()
{
  MODEL_mkBsvTop_bsim *model = new MODEL_mkBsvTop_bsim();
  return (void *)(model);
}

/* Schedule functions */

static void schedule_posedge_CLK(tSimStateHdl simHdl, void *instance_ptr)
       {
	 MOD_mkBsvTop_bsim &INST_top = *((MOD_mkBsvTop_bsim *)(instance_ptr));
	 tUInt8 DEF_INST_top_DEF_initialized__h1415;
	 tUInt8 DEF_INST_top_DEF_hwmain_relayUart_i_notFull____d18;
	 tUInt8 DEF_INST_top_DEF_CAN_FIRE_RL_uart_relayOut;
	 tUInt8 DEF_INST_top_DEF_WILL_FIRE_RL_uart_relayOut;
	 tUInt8 DEF_INST_top_DEF_CAN_FIRE_RL_uart_relayIn;
	 tUInt8 DEF_INST_top_DEF_WILL_FIRE_RL_uart_relayIn;
	 tUInt8 DEF_INST_top_DEF_CAN_FIRE_RL_hwmain_ram_dodelay;
	 tUInt8 DEF_INST_top_DEF_WILL_FIRE_RL_hwmain_ram_dodelay;
	 tUInt8 DEF_INST_top_DEF_CAN_FIRE_RL_hwmain_ttt;
	 tUInt8 DEF_INST_top_DEF_WILL_FIRE_RL_hwmain_ttt;
	 tUInt8 DEF_INST_top_DEF_CAN_FIRE_RL_doinit;
	 tUInt8 DEF_INST_top_DEF_WILL_FIRE_RL_doinit;
	 tUInt8 DEF_INST_top_DEF_CAN_FIRE_RL_relayUartIn;
	 tUInt8 DEF_INST_top_DEF_WILL_FIRE_RL_relayUartIn;
	 tUInt8 DEF_INST_top_DEF_CAN_FIRE_RL_relayUartOut;
	 tUInt8 DEF_INST_top_DEF_WILL_FIRE_RL_relayUartOut;
	 DEF_INST_top_DEF_initialized__h1415 = INST_top.INST_initialized.METH_read();
	 DEF_INST_top_DEF_CAN_FIRE_RL_doinit = !DEF_INST_top_DEF_initialized__h1415;
	 DEF_INST_top_DEF_WILL_FIRE_RL_doinit = DEF_INST_top_DEF_CAN_FIRE_RL_doinit;
	 DEF_INST_top_DEF_CAN_FIRE_RL_hwmain_ram_dodelay = INST_top.INST_hwmain_ram_delayQ.METH_i_notEmpty() && INST_top.INST_hwmain_ram_outQ.METH_i_notFull();
	 DEF_INST_top_DEF_WILL_FIRE_RL_hwmain_ram_dodelay = DEF_INST_top_DEF_CAN_FIRE_RL_hwmain_ram_dodelay;
	 INST_top.DEF_v__h1457 = INST_top.INST_uart_outQ.METH_first();
	 INST_top.DEF__read__h760 = INST_top.INST_hwmain_ram_outCnt.METH_read();
	 INST_top.DEF__read__h668 = INST_top.INST_hwmain_ram_inCnt.METH_read();
	 DEF_INST_top_DEF_hwmain_relayUart_i_notFull____d18 = INST_top.INST_hwmain_relayUart.METH_i_notFull();
	 INST_top.DEF_uart_outQ_first__0_BIT_0___d31 = (tUInt8)((tUInt8)1u & (INST_top.DEF_v__h1457));
	 DEF_INST_top_DEF_CAN_FIRE_RL_relayUartIn = ((tUInt8)3u & ((INST_top.DEF__read__h668) - (INST_top.DEF__read__h760))) < (tUInt8)2u && (DEF_INST_top_DEF_hwmain_relayUart_i_notFull____d18 && (INST_top.INST_uart_outQ.METH_i_notEmpty() && (INST_top.DEF_uart_outQ_first__0_BIT_0___d31 || INST_top.INST_hwmain_ram_delayQ.METH_i_notFull())));
	 DEF_INST_top_DEF_WILL_FIRE_RL_relayUartIn = DEF_INST_top_DEF_CAN_FIRE_RL_relayUartIn;
	 DEF_INST_top_DEF_CAN_FIRE_RL_hwmain_ttt = INST_top.INST_hwmain_ram_outQ.METH_i_notEmpty() && DEF_INST_top_DEF_hwmain_relayUart_i_notFull____d18;
	 DEF_INST_top_DEF_WILL_FIRE_RL_hwmain_ttt = DEF_INST_top_DEF_CAN_FIRE_RL_hwmain_ttt && !DEF_INST_top_DEF_WILL_FIRE_RL_relayUartIn;
	 DEF_INST_top_DEF_CAN_FIRE_RL_relayUartOut = INST_top.INST_hwmain_relayUart.METH_i_notEmpty() && INST_top.INST_uart_inQ.METH_i_notFull();
	 DEF_INST_top_DEF_WILL_FIRE_RL_relayUartOut = DEF_INST_top_DEF_CAN_FIRE_RL_relayUartOut;
	 DEF_INST_top_DEF_CAN_FIRE_RL_uart_relayOut = INST_top.INST_uart_outQ.METH_i_notFull();
	 DEF_INST_top_DEF_WILL_FIRE_RL_uart_relayOut = DEF_INST_top_DEF_CAN_FIRE_RL_uart_relayOut;
	 DEF_INST_top_DEF_CAN_FIRE_RL_uart_relayIn = INST_top.INST_uart_inQ.METH_i_notEmpty();
	 DEF_INST_top_DEF_WILL_FIRE_RL_uart_relayIn = DEF_INST_top_DEF_CAN_FIRE_RL_uart_relayIn;
	 if (DEF_INST_top_DEF_WILL_FIRE_RL_doinit)
	   INST_top.RL_doinit();
	 if (DEF_INST_top_DEF_WILL_FIRE_RL_hwmain_ram_dodelay)
	   INST_top.RL_hwmain_ram_dodelay();
	 if (DEF_INST_top_DEF_WILL_FIRE_RL_hwmain_ttt)
	   INST_top.RL_hwmain_ttt();
	 if (DEF_INST_top_DEF_WILL_FIRE_RL_relayUartIn)
	   INST_top.RL_relayUartIn();
	 if (DEF_INST_top_DEF_WILL_FIRE_RL_relayUartOut)
	   INST_top.RL_relayUartOut();
	 if (DEF_INST_top_DEF_WILL_FIRE_RL_uart_relayOut)
	   INST_top.RL_uart_relayOut();
	 if (DEF_INST_top_DEF_WILL_FIRE_RL_uart_relayIn)
	   INST_top.RL_uart_relayIn();
	 if (do_reset_ticks(simHdl))
	 {
	   INST_top.INST_uart_inQ.rst_tick_clk((tUInt8)1u);
	   INST_top.INST_uart_outQ.rst_tick_clk((tUInt8)1u);
	   INST_top.INST_uart_outCnt.rst_tick__clk__1((tUInt8)1u);
	   INST_top.INST_uart_inReqId.rst_tick__clk__1((tUInt8)1u);
	   INST_top.INST_hwmain_ram_outQ.rst_tick_clk((tUInt8)1u);
	   INST_top.INST_hwmain_ram_inCnt.rst_tick__clk__1((tUInt8)1u);
	   INST_top.INST_hwmain_ram_readCnt.rst_tick__clk__1((tUInt8)1u);
	   INST_top.INST_hwmain_ram_outCnt.rst_tick__clk__1((tUInt8)1u);
	   INST_top.INST_hwmain_ram_delayQ.rst_tick_clk((tUInt8)1u);
	   INST_top.INST_hwmain_relayUart.rst_tick_clk((tUInt8)1u);
	   INST_top.INST_initialized.rst_tick__clk__1((tUInt8)1u);
	 }
       };

/* Model creation/destruction functions */

void MODEL_mkBsvTop_bsim::create_model(tSimStateHdl simHdl, bool master)
{
  sim_hdl = simHdl;
  init_reset_request_counters(sim_hdl);
  mkBsvTop_bsim_instance = new MOD_mkBsvTop_bsim(sim_hdl, "top", NULL);
  bk_get_or_define_clock(sim_hdl, "CLK");
  if (master)
  {
    bk_alter_clock(sim_hdl, bk_get_clock_by_name(sim_hdl, "CLK"), CLK_LOW, false, 0llu, 5llu, 5llu);
    bk_use_default_reset(sim_hdl);
  }
  bk_set_clock_event_fn(sim_hdl,
			bk_get_clock_by_name(sim_hdl, "CLK"),
			schedule_posedge_CLK,
			NULL,
			(tEdgeDirection)(POSEDGE));
  (mkBsvTop_bsim_instance->INST_uart_inQ.set_clk_0)("CLK");
  (mkBsvTop_bsim_instance->INST_uart_outQ.set_clk_0)("CLK");
  (mkBsvTop_bsim_instance->INST_hwmain_ram_outQ.set_clk_0)("CLK");
  (mkBsvTop_bsim_instance->INST_hwmain_ram_delayQ.set_clk_0)("CLK");
  (mkBsvTop_bsim_instance->INST_hwmain_relayUart.set_clk_0)("CLK");
  (mkBsvTop_bsim_instance->set_clk_0)("CLK");
}
void MODEL_mkBsvTop_bsim::destroy_model()
{
  delete mkBsvTop_bsim_instance;
  mkBsvTop_bsim_instance = NULL;
}
void MODEL_mkBsvTop_bsim::reset_model(bool asserted)
{
  (mkBsvTop_bsim_instance->reset_RST_N)(asserted ? (tUInt8)0u : (tUInt8)1u);
}
void * MODEL_mkBsvTop_bsim::get_instance()
{
  return mkBsvTop_bsim_instance;
}

/* Fill in version numbers */
void MODEL_mkBsvTop_bsim::get_version(unsigned int *year,
				      unsigned int *month,
				      char const **annotation,
				      char const **build)
{
  *year = 2014u;
  *month = 7u;
  *annotation = "A";
  *build = "34078";
}

/* Get the model creation time */
time_t MODEL_mkBsvTop_bsim::get_creation_time()
{
  
  /* Wed May 20 06:26:45 UTC 2020 */
  return 1589956005llu;
}

/* Control run-time licensing */
tUInt64 MODEL_mkBsvTop_bsim::skip_license_check()
{
  return 0llu;
}

/* State dumping function */
void MODEL_mkBsvTop_bsim::dump_state()
{
  (mkBsvTop_bsim_instance->dump_state)(0u);
}

/* VCD dumping functions */
MOD_mkBsvTop_bsim & mkBsvTop_bsim_backing(tSimStateHdl simHdl)
{
  static MOD_mkBsvTop_bsim *instance = NULL;
  if (instance == NULL)
  {
    vcd_set_backing_instance(simHdl, true);
    instance = new MOD_mkBsvTop_bsim(simHdl, "top", NULL);
    vcd_set_backing_instance(simHdl, false);
  }
  return *instance;
}
void MODEL_mkBsvTop_bsim::dump_VCD_defs()
{
  (mkBsvTop_bsim_instance->dump_VCD_defs)(vcd_depth(sim_hdl));
}
void MODEL_mkBsvTop_bsim::dump_VCD(tVCDDumpType dt)
{
  (mkBsvTop_bsim_instance->dump_VCD)(dt, vcd_depth(sim_hdl), mkBsvTop_bsim_backing(sim_hdl));
}
