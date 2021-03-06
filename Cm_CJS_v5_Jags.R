rm(list=ls())
library(jagsUI)
library(tidyverse)
library(lubridate)
library(reshape)
library(bayesplot)
#library(ggridges)
library(loo)

# library(RMark)
# library(R2ucare)

source("Mancini_functions.R")
save.fig <- F

MCMC.params <- list(n.samples = 50000,
                    n.burnin = 30000,
                    n.thin = 5,
                    n.chains = 5)

community.names <- c("BKS", "BMA", "GNO", 
                     "IES", "LSI", "MUL",
                     "PAO", "PLM")

# the best models for communities, determined through AICc in MARK:
# models.MARK <- data.frame(community = community.names,
#                           ID = c(2, 10, 11,
#                                  11, 2, 1,
#                                  2, 11),
#                           model = c("Phidot_pt", "PhiTSM_pdot", "PhiTSM_pt",
#                                     "PhiTSM_pt", "Phidot_pt", "Phidot_pdot",
#                                     "Phidot_pt", "PhiTSM_pt"))

# Using TSM instead of dot for phi
models.MARK <- data.frame(community = community.names,
                          ID = c(11, 10, 2,
                                 11, 11, 10,
                                 11, 11),
                          model = c("PhiTSM_pt", "PhiTSM_pdot", "Phidot_pt",
                                    "PhiTSM_pt", "PhiTSM_pt", "PhiTSM_pdot",
                                    "PhiTSM_pt", "PhiTSM_pt"))


#dat.1 <- get.data("data/GTC_20190725_Tomo_v2.csv")

# Use the input files from Mark analysis.
for (k in 1:length(community.names)){
  
  Cm.inputs <- readRDS(file = paste0("RData/CJS_Cm_RMark_input_", 
                                     community.names[k], ".rds"))

  CH <- Cm.inputs$CH.1 %>% select(-ID) %>% as.matrix()
  
  nInd <- sum(Cm.inputs$CH.R2ucare$effY)
  
  ns <- colSums(Cm.inputs$CH.1 %>% select(-ID))
  
  cap.dates <- paste0(colnames(CH), "-01")
  delta.dates <- signif(as.numeric(as.Date(cap.dates[2:length(cap.dates)]) -
                                     as.Date(cap.dates[1:(length(cap.dates)-1)]))/365, 1)

  # find the first capture date
  get.first <- function(x) min(which(x != 0))
  first.cap <- apply(CH, 1, get.first)
  
  m <- matrix(data = 2, nrow = nrow(CH), ncol = ncol(CH))
  for (k2 in 1:nrow(m)){
    m[k2, first.cap[k2]] <- 1
  }
  
  jags.data <- list(y = CH, 
                    f = first.cap, 
                    nind = nInd, 
                    n.occasions = dim(CH)[2],
                    n = ns, 
                    T = ncol(CH),
                    dt = c(0, delta.dates),
                    mean.K = 2000,
                    m = m)
  
  ## parameters to monitor - when this is changed, make sure to change
  ## summary statistics index at the end of this script. 
  parameters <- c("beta", "gamma", "N", "prop.trans", 
                  "r", "K",  "beta.p", "mean.phi", 
                  "deviance")
  
  jags.input <- list(CH = CH,
                     jags.data = jags.data,
                     parameters.to.save = parameters,
                     run.date = Sys.Date())
  
  if (!file.exists(paste0("RData/CJS_Cm_jags_input_v5_", community.names[k], ".rds")))
    saveRDS(jags.input, 
            file = paste0("RData/CJS_Cm_jags_input_v5_", community.names[k], ".rds"))        
  
  # models need to change according to the output from Mark, or do we do 
  # a similar model selection process using Pareto K?
  MCMC.params$model.file <- paste0("models/Model_CJS_", 
                                   filter(models.MARK, 
                                          community == community.names[k])["model"],
                                   ".txt")
  
  if (!file.exists(paste0("RData/CJS_Cm_jags_v5_M",
                          filter(models.MARK, 
                                 community == community.names[k])["ID"], "_", 
                          community.names[k], ".rds"))){
    
    jm <- jags(data = jags.data,
               parameters.to.save= parameters,
               model.file = MCMC.params$model.file,
               n.chains = MCMC.params$n.chains,
               n.burnin = MCMC.params$n.burnin,
               n.thin = MCMC.params$n.thin,
               n.iter = MCMC.params$n.samples,
               DIC = T, 
               parallel=T)
    
    saveRDS(jm, 
            file = paste0("RData/CJS_Cm_jags_v5_M",
                          filter(models.MARK, 
                                 community == community.names[k])["ID"], "_", 
                          community.names[k], ".rds"))
  }  
  
  # loo.out[[k1]] <- compute.LOOIC(loglik = jm$sims.list$loglik, 
  #                                MCMC.params = MCMC.params, 
  #                                data.vector = as.vector(jags.data$y))
  rm(list = c("jm"))

}

#saveRDS(loo.out, file = paste0("RData/CJS_Cm_jags_", community.names[k], "_loo.rds"))
        

