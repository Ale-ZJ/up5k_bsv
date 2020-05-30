/*
 * Generated by Bluespec Compiler, version 2014.07.A (build 34078, 2014-07-30)
 * 
 * On Tue May 19 15:33:31 PDT 2020
 * 
 */

/* Generation options: */
#ifndef __model_mkBsvTop_bsim_h__
#define __model_mkBsvTop_bsim_h__

#include "bluesim_types.h"
#include "bs_module.h"
#include "bluesim_primitives.h"
#include "bs_vcd.h"

#include "bs_model.h"
#include "mkBsvTop_bsim.h"

/* Class declaration for a model of mkBsvTop_bsim */
class MODEL_mkBsvTop_bsim : public Model {
 
 /* Top-level module instance */
 private:
  MOD_mkBsvTop_bsim *mkBsvTop_bsim_instance;
 
 /* Handle to the simulation kernel */
 private:
  tSimStateHdl sim_hdl;
 
 /* Constructor */
 public:
  MODEL_mkBsvTop_bsim();
 
 /* Functions required by the kernel */
 public:
  void create_model(tSimStateHdl simHdl, bool master);
  void destroy_model();
  void reset_model(bool asserted);
  void get_version(unsigned int *year,
		   unsigned int *month,
		   char const **annotation,
		   char const **build);
  time_t get_creation_time();
  void * get_instance();
  void dump_state();
  void dump_VCD_defs();
  void dump_VCD(tVCDDumpType dt);
  tUInt64 skip_license_check();
};

/* Function for creating a new model */
extern "C" {
  void * new_MODEL_mkBsvTop_bsim();
}

#endif /* ifndef __model_mkBsvTop_bsim_h__ */
