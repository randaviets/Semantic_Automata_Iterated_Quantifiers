expname="rv_digitSpan"
rtcol = 2
successcol = 4
lastlines = 1
trimSD = NA
lowestRT=NA
highestRT=NA
followsuccess = F
datafilename = paste("exp_datafiles_", expname, ".txt", sep = "")
d = read.table(datafilename, as.is = T)

outputMean = NULL
outputMedian = NULL
outputMin = NULL
outputMax = NULL
outputN = NULL
outputPE = NULL

for (i in 1:length(d[, 1])) {
    if (!is.na(d[i, 1]) & file.info(d[i, 1])$size > 0) {

        print(i)

        if (exists("x")) {
            rm(x)
        }

        if (exists("exclude_lastlines")) {
            if (exclude_lastlines > 0) {
                o = system(paste("head -n", exclude_lastlines * -1, d[i, 1]), intern = T)
                x = read.table(textConnection(o), fill = T)
            }
        }

        if (exists("lastlines")) {
            if (lastlines > 0) {
                o = system(paste("tail -n", lastlines, d[i, 1]), intern = T)
                x = read.table(textConnection(o), fill = T)
            }
        }

        # if neither exclude_lastlines or lastlines has been applied
        if (!exists("x")) {
            x = read.table(d[i, 1], fill = T)
        }

        ## following block is inserted from file --------------- filter using
        ## lastlines, include_me, exclude_me

        if (exists("include_me"))
            x = x[x[, 1] == include_me, ]
        if (exists("exclude_me"))
            x = x[x[, 1] != exclude_me, ]

        ###################################################################### include
        ###################################################################### and
        ###################################################################### exclude
        ###################################################################### blocks

        ntrials = length(x[, 1])
        if (exists("blockcol")) {
            block = x[, blockcol]

            if (exists("IncludeBlocks")) {
                inclusion = block %in% IncludeBlocks
            } else {
                inclusion = rep(T, ntrials)
            }

            if (exists("ExcludeBlocks")) {
                exclusion = block %in% ExcludeBlocks
            } else {
                exclusion = rep(F, ntrials)  ## non is excluded
            }

            blockselection = inclusion & !exclusion
        } else {
            blockselection = rep(T, ntrials)
        }

        x = droplevels(x[blockselection, ])  ## droplevels removes unused levels

        ######################################################################

        sink("Rout.txt")

        ## these 4 variables are for later storage if used with multiple files,
        ## but not for single datafile analysis

        outputdataMean = numeric()
        outputdataMedian = numeric()
        outputdataMin = numeric()
        outputdataMax = numeric()
        outputdataN = numeric()
        outputdataPE = numeric()

        ###################################################################### trim
        ###################################################################### rt
        ###################################################################### data

        psytkTrim = function(x, xsd = 3, low = NA, high = NA) {
            y = x
            if (!is.na(low))
                y = y[y >= low]
            if (!is.na(high))
                y = y[y <= high]
            m = mean(y)
            if (!is.na(xsd)) {
                s = sd(y) * xsd
                y = y[y > (m - s) & y < (m + s)]
            }
            return(y)
        }

        ###################################################################### read
        ###################################################################### data

        ntrials = length(x[, 1])
        trialnum = 1:ntrials

        ## if successcol not specified all trials are success the success is
        ## stored as logical in CORRECT, and if not provided, all trials are
        ## considered to be true

        if (exists("successcol")) {
            if (exists("status_correct")) {
                CORRECT = x[, successcol] == status_correct
            } else {
                CORRECT = x[, successcol] == 1
            }
        } else {
            CORRECT = rep(T, ntrials)
        }

        ###################################################################### if
        ###################################################################### we
        ###################################################################### know
        ###################################################################### block,
        ###################################################################### code
        ###################################################################### if
        ###################################################################### a
        ###################################################################### trial
        ###################################################################### is
        ###################################################################### in
        ###################################################################### same
        ###################################################################### block
        ###################################################################### as
        ###################################################################### previous
        ###################################################################### one

        if (exists("blockcol")) {
            sameblock = c(F, x[2:ntrials, blockcol] == x[1:(ntrials - 1), blockcol])
        } else {
            sameblock = rep(T, ntrials)  ## if info is not available, always true
        }


        ###################################################################### now,
        ###################################################################### just
        ###################################################################### get
        ###################################################################### the
        ###################################################################### trial
        ###################################################################### numbers
        ###################################################################### for
        ###################################################################### each
        ###################################################################### condition
        ###################################################################### you
        ###################################################################### want
        allvalues = function(a) {
            return(a)
        }

        ## of course, it is possible there are no conditions, and all data are
        ## part of the one-and-only condition

        ## note that z is the result of by, which is a list. you can get the
        ## names of it using expand.grid.

        if (exists("conditions")) {
            z = by(trialnum, x[, conditions], allvalues)
            conditionnames = apply(expand.grid(dimnames(z)), 1, paste, collapse = "_")
        } else {
            z = list(trialnum)  ## include all trials
            conditionnames = "all_data"
        }

        ## NOTE: the tmpRtData should not be acted on with any further boolean
        ## selectors.

        for (i in 1:length(conditionnames)) {
            tc = conditionnames[i]
            selection = trialnum %in% z[[i]]

            ## if you want only trials that follow a succesful trial of course,
            ## that trial must be in the same block as previous trial as well
            if (followsuccess) {
                selection = selection & sameblock & c(F, CORRECT[1:(ntrials - 1)])
            }

            ## if necessary, trim the data based on low/high and/or SD
            if (!is.na(lowestRT) | !is.na(highestRT) | !is.na(trimSD)) {
                tmpRtData = psytkTrim(x[selection & CORRECT, rtcol], 3, lowestRT,
                  highestRT)
            } else {
                tmpRtData = x[selection & CORRECT, rtcol]
            }

            ## now report averages
            cat("Condition:", tc, "\n")
            cat("-------------------------------------------\n")
            cat("Total trials  :", sum(selection), "trials.\n")

            cat("Total correct :", sum(selection & CORRECT), "trials (errors excluded, for RT data below).\n")

            if (!is.na(lowestRT) | !is.na(highestRT) | !is.na(trimSD)) {
                cat("After RT trim :", length(tmpRtData), "\n")
            }

            cat("Error count   :", sum(!CORRECT & selection), "\n")
            cat("Mean value    :", mean(tmpRtData), "\n")
            cat("Median value  :", median(tmpRtData), "\n")
            cat("Min value     :", min(tmpRtData), "\n")
            cat("Max value     :", max(tmpRtData), "\n")
            cat("Error rate    :", (1 - sum(CORRECT[selection])/sum(selection)) *
                100, "percent\n\n")

            ## now store the data for multiple data file analysis
            if (length(outputdataMean) == 0) {
                outputdataMean = mean(tmpRtData)
            } else {
                outputdataMean = c(outputdataMean, mean(tmpRtData))
            }

            if (length(outputdataMedian) == 0) {
                outputdataMedian = median(tmpRtData)
            } else {
                outputdataMedian = c(outputdataMedian, median(tmpRtData))
            }

            if (length(outputdataMin) == 0) {
                outputdataMin = min(tmpRtData)
            } else {
                outputdataMin = c(outputdataMin, min(tmpRtData))
            }

            if (length(outputdataMax) == 0) {
                outputdataMax = max(tmpRtData)
            } else {
                outputdataMax = c(outputdataMax, max(tmpRtData))
            }

            if (length(outputdataN) == 0) {
                outputdataN = sum(selection)
            } else {
                outputdataN = c(outputdataN, sum(selection))
            }

            if (length(outputdataPE) == 0) {
                outputdataPE = (1 - sum(CORRECT[selection])/sum(selection)) * 100
            } else {
                outputdataPE = c(outputdataPE, (1 - sum(CORRECT[selection])/sum(selection)) *
                  100)
            }
        }

        # colnames( outputdata ) = conditionnames
        sink()
        ## end of block that was inserted ----------------------

        print(outputdataMean)

        outputMean = rbind(outputMean, outputdataMean)
        outputMedian = rbind(outputMedian, outputdataMedian)
        outputMin = rbind(outputMin, outputdataMin)
        outputMax = rbind(outputMax, outputdataMax)
        outputN = rbind(outputN, outputdataN)
        outputPE = rbind(outputPE, outputdataPE)
    }
}

print(outputMean)

colnames(outputMean) = conditionnames
colnames(outputMedian) = conditionnames
colnames(outputMin) = conditionnames
colnames(outputMax) = conditionnames
colnames(outputN) = conditionnames
colnames(outputPE) = conditionnames
## the problem is that not all participants will have an experiment
## datafile We know this from a NA in the datafiles file NA. This file
## just makes sure that we have output for each participant, with NA
## at the appropriate places
## This way, the files will match the main csv file

## this always creates excel files and optionally ODS files

outputMean2   = matrix(ncol=length( conditionnames ),nrow=length(d[,1]))
outputMedian2 = matrix(ncol=length( conditionnames ),nrow=length(d[,1]))
outputMin2    = matrix(ncol=length( conditionnames ),nrow=length(d[,1]))
outputMax2    = matrix(ncol=length( conditionnames ),nrow=length(d[,1]))
outputN2      = matrix(ncol=length( conditionnames ),nrow=length(d[,1]))
outputPE2     = matrix(ncol=length( conditionnames ),nrow=length(d[,1]))

colnames(outputMean2)   = conditionnames
colnames(outputMedian2) = conditionnames
colnames(outputMin2)    = conditionnames
colnames(outputMax2)    = conditionnames
colnames(outputN2)      = conditionnames
colnames(outputPE2)     = conditionnames

counter = 1
for( i in 1:length(d[,1])){
    if( is.na(d[i,1]) | file.info(d[i,1])$size == 0 ){
        outputMean2[i,]   = rep( NA , length( conditionnames ) )
        outputMedian2[i,] = rep( NA , length( conditionnames ) )
        outputMin2[i,]    = rep( NA , length( conditionnames ) )
        outputMax2[i,]    = rep( NA , length( conditionnames ) )                
        outputN2[i,]      = rep( NA , length( conditionnames ) )
        outputPE2[i,]     = rep( NA , length( conditionnames ) )        
    }else{
        outputMean2[i,]   = outputMean[counter,]
        outputMedian2[i,] = outputMedian[counter,]
        outputN2[i,]      = outputN[counter,]
        outputMin2[i,]    = outputMin[counter,]
        outputMax2[i,]    = outputMax[counter,]
        outputPE2[i,]     = outputPE[counter,]
        counter=counter+1
    }
}

## the variables outputMean2, outputMedian2 etc now contain averages for all participants
## you can write these to csv if needed with write.csv(outputMean2,"file.csv",row.names=F)
