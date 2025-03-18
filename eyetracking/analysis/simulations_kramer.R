# (except for one single missed deadline, all errors that were not due to eye
# movements were anticipations).

rm(list=ls())
library(tidyverse)
library(mlisi)

d_prime <- 2.5
criterion <- d_prime/2 # optimal

n <- 6
n_pid <- 32
# offset_times <- seq(1000, 7800, length.out=18)

d_all <- {}
for(pid in 1:32){
for(i in 1:18){
  d_i <- expand_grid(rep=1:n, 
                 time_bin = 1:18, 
                 offset_time = i)
  d_i$trial <- d_i$rep + (i-1)*n
  d_i$pid <- pid
  d_all <- rbind(d_all,d_i)
}
}
str(d_all)
d <- d_all

# 1 decrease in sensitivity
# move_d <- function(d_prime, time){
#   d_ <- d_prime - (time/19)*d_prime
#   return(d_)
# }
# # plot(1:18, move_d(2, 1:18), type="o")
# 
# # chanhe in c
# move_c <- function(criterion, time){
#   c_ <- criterion + (time/18)*2*criterion
#   return(c_)
# }
# #plot(1:18, move_c(1, 1:18), type="o")
# 
# # simulate
# d$d_m <- move_d(d_prime, d$time_bin)
# d$c_m <- move_c(criterion, d$time_bin)

# d$resp_ <- NA
# for( i in unique(d$trial)){
#   d_i <- d[d$trial==i,]
#   for(t in 1:18){
#     signal_present <- as.numeric(unique(d_i$offset_time)==t)
#     d_i$resp_[t] <- rbinom(1,1,pnorm(criterion, mean=signal_present*d_prime, lower.tail=FALSE))
#     if(d_i$resp_[t]==1){
#       break
#     }
#   }
#   d$resp_[d$trial==i] <- d_i$resp_
# }

d$resp_ <- NA
for( pid in unique(d$pid)){
for( i in unique(d$trial)){
  d_i <- d[d$trial==i & d$pid==pid,]
  for(t in 1:18){
    signal_present <- as.numeric(unique(d_i$offset_time)==t)
    d_i$resp_[t] <- rbinom(1,1,pnorm(criterion, mean=signal_present*d_prime, lower.tail=FALSE))
    if(d_i$resp_[t]==1){
      break
    }
  }
  d$resp_[d$trial==i& d$pid==pid] <- d_i$resp_
}
}


# dag <- d %>%
#   filter(!is.na(resp_)) %>%
#   filter(resp_==1) %>%
#   mutate(acc=ifelse(offset_time==time_bin,1,0)) %>%
#   group_by(offset_time) %>%
#   summarise(accuracy=mean(acc),
#             se = binomSEM(acc))

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
  coord_cartesian(ylim=c(0,1), xlim=c(0,9))



