rm(list=ls())
library(tidyverse)

# -----------------------------------------------------------------------------
# Simulating an experiment based on the Kramer et al. paper
# 
# This simulation applies principles from Signal Detection Theory (SDT) 
# to model an observer detecting a target disappearance.
# 
# In their study, Kramer et al. noted: 
# "Except for one single missed deadline, all errors that were not due 
# to eye movements were anticipations."
#
# In the context of SDT, these "anticipations" can be interpreted as 
# false alarms—instances where participants report that the target 
# has disappeared when it is, in fact, still present.

# -----------------------------------------------------------------------------
# set average sensitivity and bias of simulated observers
d_prime <- 2.5
criterion <- d_prime/2 # optimal criterion setting

# -----------------------------------------------------------------------------
# standard deviations of d-prime and criterion between participants
d_prime_SD <- 0.5
criterion_SD <- 0.25

# -----------------------------------------------------------------------------
n <- 6 # N trials per delay (108/18)
n_pid <- 32 # 

# create an database for simulating responses
d <- {}
for(pid in 1:32){
  for(i in 1:18){
    d_i <- expand_grid(rep=1:n, 
                       time_bin = 1:18, 
                       offset_time = i)
    d_i$trial <- d_i$rep + (i-1)*n
    d_i$pid <- pid
    d <- rbind(d,d_i)
  }
}
str(d)

# -----------------------------------------------------------------------------
# simulate responses

# In this simulation, errors (false alarms or misses) can occur independently 
# within each 400ms interval. When a response is recorded—whether correct 
# or erroneous—the trial is immediately interrupted.
#
# This structure implies that in trials with longer lead times (i.e., longer 
# intervals before the target actually disappears), participants have more 
# opportunities to make mistakes. However, this does not reflect a change in 
# their actual ability to detect target disappearances; rather, it is a 
# consequence of the increased number of decision points available before 
# the target vanishes.

set.seed(1)

d$resp_ <- NA
for( pid in unique(d$pid)){
  d_prime_i <- rnorm(1, mean=d_prime, sd= d_prime_SD)
  criterion_i <- rnorm(1, mean=criterion, sd= criterion_SD)
  for( i in unique(d$trial)){
    d_i <- d[d$trial==i & d$pid==pid,]
    for(t in 1:18){
      signal_present <- as.numeric(unique(d_i$offset_time)==t)
      d_i$resp_[t] <- rbinom(1,1,pnorm(criterion_i,
                                       mean=signal_present*d_prime_i, 
                                       lower.tail=FALSE))
      if(d_i$resp_[t]==1){
        break
      }
    }
    d$resp_[d$trial==i& d$pid==pid] <- d_i$resp_
  }
}

# -----------------------------------------------------------------------------
# average and plot like in the paper


dag <- d %>%
  filter(!is.na(resp_)) %>%
  filter(resp_==1) %>%
  mutate(acc=ifelse(offset_time==time_bin,1,0)) %>%
  group_by(offset_time, pid) %>%
  summarise(acc=mean(acc)) %>%
  ungroup() %>%
  group_by(offset_time) %>%
  summarise(accuracy=mean(acc),
            se = se(acc))


dag %>%
  ggplot(aes(x=offset_time*0.4 + 0.6, y=accuracy))+
  geom_line()+
  geom_point()+
  geom_errorbar(aes(ymin=accuracy-2*se, ymax=accuracy+2*se),width=0)+
  coord_cartesian(ylim=c(0,1), xlim=c(0.6,8))+
  labs(y="% correct", x="lead time (seconds)")

ggsave("krameretal_sim.pdf", width=3,height=3)

