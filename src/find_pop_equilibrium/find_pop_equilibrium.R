################################################################################

#                orderly task: 'find_pop_equilibirum' 

################################################################################ 

# THIS ORDERLY TASK'S OBJECTIVE IS TO:------------------------------------------
# - Run the population-level XPVWRH gonovax model to equilibrium given the 
#   natural history parameters provided and save down this equilibrium position
#   to initialise runs downstream 

#-------------------------------------------------------------------------------        
# Set up
#-------------------------------------------------------------------------------
# Generate input & output folders for organisation
dir.create("inputs", showWarnings = FALSE)
dir.create("outputs", showWarnings = FALSE)

#-------------------------------------------------------------------------------        
# Parameters
#-------------------------------------------------------------------------------
# n_erlang : number of transitions for waning from protection to take place
# short_run: if TRUE, the number of parameter sets used will be reduced to 10 
#            from the usual 1e03

orderly::orderly_parameters(
  n_erlang = 1,
  short_run = FALSE
)

#-------------------------------------------------------------------------------        
# Dependencies
#-------------------------------------------------------------------------------
files <- c("outputs/gp_params.rds")
names(files) <- "inputs/gp_params.rds"

orderly::orderly_dependency(
  name = "read_in",
  query = "latest()",                   
  files = files)

#-------------------------------------------------------------------------------        
# Artefacts
#-------------------------------------------------------------------------------
orderly::orderly_artefact(
  description = "Updated parameters according to short vs long run requirement",
  files = c("outputs/gp_params_npar.rds"
  )
)

orderly::orderly_artefact(
  description = "Population model output at equilibrium",
  files = c("outputs/y0_equilibrium_run.rds"
  )
)

#-------------------------------------------------------------------------------        
# Load Resources
#-------------------------------------------------------------------------------
gono_params <- readRDS("inputs/gp_params.rds")

library(gonovax)
library(tidyr)
library(dplyr)

#-------------------------------------------------------------------------------        
# Process
#-------------------------------------------------------------------------------
#Reduce number of parameters according to short vs long run requirement
n_par <- ifelse(short_run, 10, 1e03)
idx <- seq_len(n_par)

gono_params$gono <- gono_params$gono[idx]
gono_params$health_economic <- gono_params$health_economic[idx, ]
gono_params$pathway_cost <- gono_params$pathway_cost$incl_toc[idx, ]
gono_params$vaccine <- gono_params$vaccine[idx, ]

#-------------------------------------------------------------------------------        
# Run population model to equilibrium (& checks)
#-------------------------------------------------------------------------------
#From 2019 to 2028 & 2029
fit_years <- 2019 + c(0, 50, 51)
tt <- gonovax::gonovax_year(fit_years)

y0 <- gonovax::run_onevax_xpvwrh(tt, dur_v = 1e+10, gono_params$gono,
                                 n_erlang = n_erlang)

#Sense check if equilibrium reached across infection states
compartments <- c("U", "I", "A", "S", "T")

for (comp in compartments) {
  runs <- gonovax::aggregate(y0, comp)
  prop <- (runs[, 3] - runs[, 2]) / (runs[, 3])
  a <- (which(abs(prop) >= 1e-04))        #captures prop.change > than threshold
  
  if (length(a) > 0) {
    a <- abs(prop)[a]
    a <- as.data.frame(a) %>% arrange(desc(a))
  
    print(paste((dim(a)[1]) * 100 / n_par,
            "% of parameter sets have not reached equilibrium for compartment",
            comp, "!"))
  } else {
    
    print(paste(comp, "is at equilibrium!"))
    
  }
}

#-------------------------------------------------------------------------------        
# Save
#-------------------------------------------------------------------------------
saveRDS(gono_params, "outputs/gp_params_npar.rds")
saveRDS(y0,"outputs/y0_equilibrium_run.rds")