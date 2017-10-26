# -------------------------------------------------------------------------
# Estimate a first-order autoregressive stochastic volatility model on the
# forecast errors from the macroeconomic data (no conditional mean)
# -------------------------------------------------------------------------

#rm(list=ls())


# Initialization
require(stochvol)
options(digits=17)
set.seed(0) # for replication

# KE file
vt = read.csv(header = TRUE, sep = ",", "C:/Dateien/My Dropbox/Lennart/Thesis/Code/ez-shocks/MATLAB/factors_vyt.csv")

# Remove dates vector
vt = vt[, -1]

obs.T    = dim(vt)[1]
obs.N    = dim(vt)[2]


for (i in 1:obs.N){
  
	if(min(log(vt[, i]^2)) == -Inf){
	  
		vt[, i] = vt[, i] + 0.00001 #offset to avoid taking log of zero
	}
}


# Run MCMC algorithm and store draws
S    = 50000
burn = 50000 # MCMC with [50000, 50000] takes roughly 50 seconds per iteration.
m    = matrix(0, obs.T + 3, obs.N)
g    = matrix(0, 3, obs.N)


for (i in 1:obs.N){
  
	draws   = svsample(vt[, i], draws = S, burnin = burn, quiet = TRUE, thinpara = 10, thinlatent = 10)
	all     = cbind(draws$para, draws$latent)
	m[, i]  = colMeans(all)
	g[, i]  = geweke.diag(draws$para)$z
	
	#name    = sprintf('svydraws%d.txt', i)
	#write(t(all),file=name,ncolumn=dim(all)[2])
	
	# Show progress in console
	cat('i =', i)
	print(Sys.time())
}




# Output results to .csv

#save(m, file = "svymeans.RData")
#save(g, file = "svygeweke.RData")

write.csv(t(m), file = 'svymeans.csv', row.names = FALSE)
write.csv(t(g), file = 'svygeweke.csv', row.names = FALSE)

