## Reading the dataset (Home ASH) into R
powerdata.ash <- read.csv(".../Datasets/powerdata.csv", header = T, stringsAsFactors = F)

## Cleaning the variable names
names(powerdata.ash) <- tolower(gsub("\\.", "", names(powerdata.ash)))

## Removing the missing values
powerdata.ash <- powerdata.ash[complete.cases(powerdata.ash),]

library(lubridate)

## Converting timestamp variable (UTC-4) to R date format
powerdata.ash$timestamputc4 <- ymd_hms(powerdata.ash$timestamputc4)

## Replacing the spurious values of mains variable
for(i in 1:nrow(powerdata.ash))
{
  powerdata.ash$mains[i] <- ifelse(powerdata.ash$real_hwh[i] > 2700 & powerdata.ash$mains[i] < powerdata.ash$real_hwh[i], powerdata.ash$real_hwh[i], powerdata.ash$mains[i])
}

## Creating a variable "mainschange" which is the first difference of mains
powerdata.ash$mainschange <- rep(NA, nrow(powerdata.ash))
for(i in 2:nrow(powerdata.ash)){
  powerdata.ash$mainschange[i] <- powerdata.ash$mains[i] - powerdata.ash$mains[i-1]
  powerdata.ash$mainschange[1] <- powerdata.ash$mains[1]
}

library(zoo)

## Creating a new variable "mav" which is the moving average series of mains
mav <- rollmedian(powerdata.ash$mains, 3)
powerdata.ash$mav <- c(powerdata.ash$mains[1], mav, powerdata.ash$mains[nrow(powerdata.ash)])

## Creating a new variable "mavchange" which is the moving average series of mainschange
mavchange <- rollmedian(powerdata.ash$mainschange, 3)
powerdata.ash$mavchange <- c(powerdata.ash$mainschange[1], mavchange, powerdata.ash$mainschange[nrow(powerdata.ash)])

## Creating a binary variable "state" to detect a change of state (event)
powerdata.ash$state <- rep(NA, nrow(powerdata.ash))
for(i in 1:nrow(powerdata.ash))
{
  powerdata.ash$state[i] <- ifelse(powerdata.ash$mav[i] >= 2700 & powerdata.ash$mains[i] >= 2700, "EVENT", "NON-EVENT")
}

## Identifying the length of sequences of events and non-events
vr <- rle(powerdata.ash$state)

## Sequences of events with <= 4 minutes don't belong to heater
vr$values[vr$values == "EVENT" & vr$lengths <= 4] <- "NON-EVENT"
powerdata.ash$state <- inverse.rle(vr)

## ## Identifying the "ON" and "OFF" events by creating a new variable "newstate"
powerdata.ash$newstate <- rep(NA, nrow(powerdata.ash))
for(i in 3:(length(powerdata.ash$state)-1))
{
  a <- abs(powerdata.ash$mav[i-1] - powerdata.ash$mav[i])
  b <- abs(powerdata.ash$mav[i-1] - powerdata.ash$mav[i-2])
  c <- abs(powerdata.ash$mav[i] - powerdata.ash$mav[i+1])
  d <- abs(powerdata.ash$mavchange[i-1] - powerdata.ash$mavchange[i])
  e <- abs(powerdata.ash$mavchange[i-1] - powerdata.ash$mavchange[i-2])
  f <- abs(powerdata.ash$mavchange[i] - powerdata.ash$mavchange[i+1])
  powerdata.ash$newstate[i] <- ifelse(powerdata.ash$state[i] == "EVENT", 
  ifelse(powerdata.ash$state[i] == powerdata.ash$state[i-1] & powerdata.ash$state[i-1] != powerdata.ash$state[i-2] & (a <= b | d <= e), "ON", powerdata.ash$state[i]),
  ifelse(powerdata.ash$state[i] != powerdata.ash$state[i-1] & (a >= c | d >= f), "OFF", powerdata.ash$state[i]))
  powerdata.ash$newstate[1:2] <- powerdata.ash$state[1:2]
  powerdata.ash$newstate[nrow(powerdata.ash)] <- powerdata.ash$state[nrow(powerdata.ash)] 
}
powerdata.ash$newstate <- ifelse(powerdata.ash$newstate != "ON" & powerdata.ash$newstate != "OFF", "NO-CHANGE", powerdata.ash$newstate)

## ## Creating a variable "realchange" which is the first difference of real_hwh
powerdata.ash$realchange <- rep(NA, nrow(powerdata.ash))
for(i in 2:nrow(powerdata.ash))
{
  powerdata.ash$realchange[i] <- powerdata.ash$real_hwh[i] - powerdata.ash$real_hwh[i-1]
  powerdata.ash$realchange[1] <- powerdata.ash$real_hwh[1]
}

## ## Creating a binary variable "realstate" to detect a change of state of heater
powerdata.ash$realstate <- ifelse(powerdata.ash$realchange >= 2700, "ON", ifelse(powerdata.ash$realchange < -2700, "OFF", "NO-CHANGE"))

## Creating a new variable "match" by matching the actual ON-OFF events with the estimated ones considering an error bracket of 1 unit time
for(i in 1:(nrow(powerdata.ash)-1))
{
  powerdata.ash$match[i] <- ifelse(powerdata.ash$realstate[i] == "ON" & powerdata.ash$realstate[i] %in% c(powerdata.ash$newstate[i], powerdata.ash$newstate[i-1], powerdata.ash$newstate[i+1]), "TRUE-ON", ifelse(powerdata.ash$realstate[i] == "OFF" & powerdata.ash$realstate[i] %in% c(powerdata.ash$newstate[i], powerdata.ash$newstate[i-1], powerdata.ash$newstate[i+1]), "TRUE-OFF",powerdata.ash$newstate[i]))
  powerdata.ash$match[nrow(powerdata.ash)] <- powerdata.ash$newstate[nrow(powerdata.ash)]
}

## Renaming the actual ON-OFF events as TRUE-ON & TRUE-OFF
powerdata.ash$realstate <- ifelse(powerdata.ash$realstate == "ON", "TRUE-ON", ifelse(powerdata.ash$realstate == "OFF", "TRUE-OFF", "NO-CHANGE"))

## Creating a confusion matrix
conf.matrix <- as.data.frame.matrix(table(powerdata.ash$match, powerdata.ash$realstate))

## Calculating the precision, recall & F1 score
precision <- sum(conf.matrix[1,1], conf.matrix[4,2], conf.matrix[5,3])/sum(conf.matrix[1,1], conf.matrix[4,2], conf.matrix[5,3], conf.matrix[2,1], conf.matrix[3,1])
recall <- sum(conf.matrix[1,1], conf.matrix[4,2], conf.matrix[5,3])/sum(conf.matrix[1,1], conf.matrix[4,2], conf.matrix[5,3], conf.matrix[1,2], conf.matrix[1,3])
ash.F1 <- (2 * precision * recall)/(precision + recall)


