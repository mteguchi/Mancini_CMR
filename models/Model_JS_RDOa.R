
> cat("model 
+ {
+   for (i in 1:M){
+ 		for (t in 1:(n.occasions - 1)){
+     phi[i, t] <- mean.phi
+     }
+     for (t in 1:(n.occasions)){
+      ..." ... [TRUNCATED] 
model 
{
  for (i in 1:M){
		for (t in 1:(n.occasions - 1)){
    phi[i, t] <- mean.phi
    }
    for (t in 1:(n.occasions)){
    p[i, t] <- mean.p
    }
    }
    
    mean.phi ~ dunif(0, 1)
    mean.p ~ dunif(0, 1)
    
    for (t in 1:n.occasions){
    gamma[t] ~ dunif(0, 1)
    }
    
    # Likelihood
    for (i in 1:M){
    # first occasion
    # state process
    z[i, 1] <- z[i, 1] * p[i, 1]
    
    # observation process
    y[i, 1] ~ dbern(mu1[i])
    
    # subsequent occasions
    for (t in 2:n.occasions){
    # state process
    # availability for recruitment
    q[i, t-1] <- 1 - z[i, t-1]
    mu2[i, t] <- phi[i, t-1] * z[i, t-1] + gamma[t] * prod(q[i, 1:(t-1)])
    z[i, t] ~ dbern(mu2[i, t])
    
    # observation process
    mu3[i, t] <- z[i, t] * p[i, t]
    y[i, t] ~ dbern(mu3[i, t])
    }
    }
    
    # calculate derived population parameters
    for (t in 1:n.occasions){
    qgamma[t] <- 1 - gamma[t]
    }
    
    cprob[1] <- gamma[1]
    for (t in 2:n.occaions){
    cprob[t] <- gamma[t] * prod(qgamma[1:(t-1)])
    }
    
    # inclusion probability
    psi <- sum(cprob[])
    for (t in 1:n.occasions){
    # entry probability
    b[t] <- cprob[t] / psi
    }
    
    for (i in 1:M){
    recruit[i, 1] <- z[i, 1]
    for (t in 2:n.occasions){
    recruit[i, t] <- (1 - z[i, t-1]) * z[i, t]
    }
    }
    
    for (t in 1:n.occasions){
    # actual population size	
    N[t] <- sum(z[1:M, t])
    # number of entries
    B[t] <- sum(recruit[1:M, t])
    }
    
    for (i in 1:M){
    Nind[i] <- sum(z[i, 1:n.occasions])
    Nalive[i] <- 1 - equals(Nind[i], 0)
    }
    
    Nsuper <- sum(Nalive[])
    }

> sink()
