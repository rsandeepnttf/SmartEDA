#' Function to create frequency and custom tables
#'
#' @description this function will automatically select categorical variables and generate frequency or cross tables based on the user inputs. Output includes counts, percentages, row total and column total.
#' @usage ExpCTable(data,Target=NULL,margin=1,clim=10,nlim=NULL,round=2,bin=NULL,per=FALSE)
##' @param data dataframe or matrix
##' @param Target target variable (dependent variable) if any. Default NULL
##' @param margin margin of index, 1 for row based proportions and 2 for column based proportions
##' @param clim maximum categories to be considered for frequency/custom table. Variables will be dropped if unique levels are higher than ‘clim’ for class factor/character variable. Default value is 10.
##' @param nlim numeric variable unique limits. Default ‘nlim’ values is 3, table excludes the numeric variables which is having greater than ‘nlim’ unique values
##' @param round round off
##' @param bin number of cuts for continuous target variable
##' @param per percentage values. Default table will give counts.
##' @details this function provides both frequency and custom tables for all categorical features. And ouput will be generated in data frame
##'
##' @return Frequency tables, Cross tables
##'
##'  Columns description for frequency tables:
##'
##'   •	Variable – Variable name
##'
##'   •	Valid – Variable values
##'
##'   •	Frequency – Frequency
##'
##'   •	Percent – Relative frequency
##'
##'   •	CumPercent – Cumulative sum of relative frequency
##'
##'  Columns description for custom tables:
##'
##'   •	Variable – Variable name
##'
##'   •	Category -  Variable values
##'
##'   •	Count – Number of counts
##'
##'   •	Per – Percentages
##'
##'   •	Total – Total count
##'
##' @examples
##' # Frequency table
##' ExpCTable(mtcars,Target=NULL,margin=1,clim=10,nlim=3,bin=NULL,per=FALSE)
##' # Crosstbale for Mtcars data
##' ExpCTable(mtcars,Target="gear",margin=1,clim=10,nlim=3,bin=NULL,per=FALSE)
##'
##' @importFrom stats na.omit
##' @export ExpCTable

ExpCTable = function(data,Target=NULL,margin=1,clim=10,nlim=NULL,round=2,bin=NULL,per=FALSE){
  r = round
  xx = as.data.frame(data)

  ### Variable selection
  num_var = names(xx)[sapply(xx, is.numeric)]
  if(length(num_var)>=1)
  {if (is.null(nlim)){num_var <- num_var[sapply(xx[,num_var], function(x){length(unique(na.omit(x)))>1 & length(unique(na.omit(x)))<=3})]} else
  {num_var <- num_var[sapply(xx[,num_var], function(x){length(unique(na.omit(x)))>1 & length(unique(na.omit(x)))<=nlim})]}
  }

  Cat_v = c(names(xx)[sapply(xx, is.character)],names(xx)[sapply(xx, is.factor)])


  if(length(Cat_v)+length(num_var)==0) stop("There is no categorical independent variables in data frame")
  if(length(Cat_v)>0){
    Cat_var <- Cat_v[sapply(xx[,Cat_v], function(x){length(unique(x))<=clim & length(unique(x))>=2})]
    Cat_var <- Cat_var[!(Cat_var %in% Target)]
    Cat_var <- c(Cat_var,num_var)

  }
  else {Cat_var <- c(num_var)

  }

  # if(is.null(Target)) stop("Target variable is missing")
  if(is.null(Target)) {
    Summary_FC = data.frame()
    for (cat in Cat_var) {
      Xvar =xx[,cat]
      Xvar =as.factor(paste0(Xvar))
      nr = nlevels(Xvar)
      FTable <- as.data.frame(matrix(numeric((length(levels(Xvar))+1)),
                                     nrow = length(levels(Xvar))+1, ncol = 5))
      names(FTable) <- c("Variable","Valid","Frequency","Percent","CumPercent")

      tbx = table(Xvar)
      tbxp = round(prop.table(table(Xvar))*100,r)
      tbxcp = cumsum(tbxp)

      FTable$Variable <- cat
      FTable$Valid <- c(levels(Xvar),"TOTAL")

      try(FTable[1:nr,3] <- tbx,silent = T)
      try(FTable[1:nr,4] <- tbxp,silent = T)
      try(FTable[1:nr,5] <- tbxcp,silent = T)
      FTable[nr+1,"Frequency"] <- sum(tbx)
      FTable[nr+1,"Percent"] <- NA
      FTable[nr+1,"CumPercent"] <- NA
      Summary_FC = rbind(Summary_FC,FTable)
    }
    return(Summary_FC)
  } else

  {
    Yvar = xx[,Target]

    if(is.numeric(Yvar) & length(unique(Yvar))>5) {

      if(is.null(bin)) {bin=4} else {bin = bin}
      Yvar = cut(Yvar,bin)
    } else {Yvar =as.factor(paste0(Yvar))}


    if (length(Cat_var)>=1){

      Summary_Cat = data.frame()
      for (cat in Cat_var) {
        Xvar =xx[,cat]
        Xvar =as.factor(paste0(Xvar))
        if (anyNA(Yvar)) {Yvar = addNA(Yvar)}
        if (anyNA(Xvar)) {Xvar = addNA(Xvar)}

        WTable <- as.data.frame(matrix(numeric((length(levels(Xvar))+1)*((length(levels(Yvar)))+3)),
                                       nrow = length(levels(Xvar))+1, ncol = (length(levels(Yvar)))+3))
        names(WTable) <- c("VARIABLE","CATEGORY",paste0(Target,":",levels(Yvar)),"TOTAL")


        WTable$VARIABLE <- cat
        WTable$CATEGORY <- c(levels(Xvar),"TOTAL")
        nr = length(levels(Xvar));nr
        nc = length(levels(Yvar))

        tb = table(Xvar,Yvar)
        tby = prop.table(table(Yvar));tbx = prop.table(table(Xvar))
        tby1 = prop.table(table(Yvar),1)*100;tbx1 = prop.table(table(Xvar),1)*100


        switch (margin,
                {tbl = round(prop.table(tb,2)*100,r); yvarper = tby1;xvarper = round(tbx*100,r)},
                {tbl = round(prop.table(tb,1)*100,r); yvarper = round(tby*100,r);xvarper = tbx1}
        )
        WTable_p = WTable
        try(WTable[1:nr,3:(nc+2)] <- tb,silent = T)
        # try(WTable[1:nr,(nc+3):(nc*2+2)] <- tbl,silent = T)
        try(WTable_p[1:nr,3:(nc+2)] <- tbl,silent = T)

        csum <- apply(WTable[1:nr,3:(nc+2)],2,sum)
        WTable[nr+1,3:(nc+2)] <- csum
        # WTable[nr+1,(nc+3):(nc*2+2)] <- yvarper
        WTable_p[nr+1,3:(nc+2)] <- yvarper

        # rsum <- apply(WTable[1:(nr+1),3:(nc+2)],1,sum)
        rsum <- apply(WTable[1:(nr+1),3:(nc+2)],1,sum)
        WTable[,"TOTAL"] <- rsum


        WTable_p[nr+1,3:(nc+2)] <- yvarper
        WTable_p["TOTAL"] <- c(xvarper,100)


        if(per == TRUE) {
          WTable[,"Number"] <- "nn"
          WTable_p[,"Number"] <- "%"
          WTC <- rbind(WTable,WTable_p)

          nm = names(WTC)
          ornam = c("VARIABLE","CATEGORY","Number")
          ornam = c(ornam,nm[!nm %in% ornam])
          WTC <- WTC[,ornam]

          # WTC <- WTC[order(WTC[,"CATEGORY"]),]
        } else {WTC = WTable}
        Summary_Cat =rbind(Summary_Cat,WTC)
      }
      class(Summary_Cat) <- c("SmartEDA", "ExpCTable", "data.frame")
      return(Summary_Cat)} else stop("There is no categorical IV`s in data frame")
  }

}

#' Function provides summary statistics with weight of evidence
#'
#'
#' @description Weight of evidence for categorical(X-independent) variable against Target variable (Y)
#' @usage ExpWoeTable(X, Y, valueOfGood = NULL,print=FALSE,Round=2)
##' @param X Independent categorical variable.
##' @param Y Binary response variable, it can take values of either 1 or 0.
##' @param valueOfGood Value of Y that is used as reference category.
##' @param print print results
##' @param Round rounds the values
##' @examples
##' X = mtcars$gear
##' Y = mtcars$am
##' WOE = ExpWoeTable(X,Y,valueOfGood = 1)
##' @seealso \code{\link[InformationValue:WOETable]{WOETable}}
##' @details
##' The weight of evidence tells the predictive power of an independent variable in relation to the dependent variable
##'
##' @return Weight of evidance summary table
##' @export ExpWoeTable

ExpWoeTable <- function (X, Y, valueOfGood = NULL,print=FALSE,Round=2){
  if(is.factor(Y)) {Y <- Y} else {Y <- as.factor(paste0(Y))}
  if(is.factor(X)) {X <- X} else {X <- as.factor(paste0(X))}
  if (anyNA(Y)) {Y = addNA(Y)}
  if (anyNA(X)) {X = addNA(X)}
  if (anyNA(Y)==T){stop("Treat NA value from Target varible")}
  if (is.null(valueOfGood)){stop("Specify reference category for target variable")}
  yClasses1 <- unique(Y)
  if (length(yClasses1) < 2){stop("Target variable having only one category")}

  if (length(yClasses1) >= 2) {
    Y =as.character(paste0(Y))
    yClasses <- unique(Y)
    if(valueOfGood==1){
      Y[which(Y == valueOfGood)] <- 1
      Y[which(!(Y == "1"))] <- 0 } else
      {
        Y[which(Y == valueOfGood)] <- 99
        Y[which(!(Y == "99"))] <- 0
        Y[which(Y == 99)] <- 1
      }
    Y <- as.numeric(Y)
    df <- data.frame(X, Y)
    woeTable <- as.data.frame(matrix(numeric(nlevels(X) *
                                               9), nrow = nlevels(X), ncol = 10))
    names(woeTable) <- c("Class","Out_1", "Out_0", "TOTAL",
                         "Per_1", "Per_0","Odds_WOE","Odds","WOE", "IV")
    woeTable$Class <- levels(X)
    try(woeTable[, c(3, 2)] <- table(X,Y), silent = T)
    woeTable[, "TOTAL"] <- apply(woeTable[,c(3,2)],1,sum)

    tbx <- woeTable[,c(2,3)]

    odsvalue <- NULL
    for(j in 1:nrow(tbx)) { ## OR = (a/b)/(c/d)
      t=sapply(rbind(tbx[j,],
                     apply(tbx[-j,],2,sum)),function(x){ x[1]/x[2]})
      odv<- round(t[[1]]/t[[2]],Round)
      if(is.infinite(odv)) odv = 0
      odsvalue <- rbind(c(t,od=odv),odsvalue)
    }


    woeTable$Per_1 <- round(woeTable$Out_1/sum(woeTable$Out_1,na.rm = T),Round)
    woeTable$Per_0 <- round(woeTable$Out_0/sum(woeTable$Out_0, na.rm = T),Round)
    woeTable$Odds_WOE <- round(woeTable$Per_1/woeTable$Per_0,Round)
    woeTable[, "Odds"] <- odsvalue[,3]
    woeTable$WOE <- round(log(woeTable$Odds_WOE),Round)
    woeTable$IV <- round((woeTable$Per_1 - woeTable$Per_0) * woeTable$WOE,Round)
    woeTable[sapply(woeTable, is.infinite)] <-0
    woeTable <- woeTable[,-7]
    attr(woeTable, "iValue") <- sum(woeTable$IV, na.rm = T)

    ref_1 =valueOfGood
    ref_0 = yClasses[!yClasses %in% valueOfGood]
    woeTable$Ref_1 = ref_1
    woeTable$Ref_0 = paste0(ref_0,collapse = ",")
    # }
    return(woeTable)
  }
  else {
    stop("WOE not computed because Y is not binary.")
  }
}


#' Information value
#'
#'Provides information value for each categorical variable (X) against target variable (Y)
#'
#' Information value is one of the most useful technique to select important variables in a predictive model. It helps to rank variables on the basis of their importance. The IV is calculated using the following formula
#'
#' IV = (Percentage of Good event - Percentage of Bad event) * WOE, where WOE is weight of evidence
#'
#' WOE = log(Percentage of Good event - Percentage of Bad event)
#'
#'Here is what the values of IV mean according to Siddiqi (2006)
#'
#'If information value is < 0.03 then predictive power = "Not Predictive"
#'
#'If information value is 0.03 to 0.1 then predictive power = "Somewhat Predictive"
#'
#'If information value is 0.1 to 0.3 then predictive power = "Meidum Predictive"
#'
#'If information value is >0.3 then predictive power = "Highly Predictive"
#'
#'
#' @usage ExpInfoValue(X, Y, valueOfGood = NULL)
##' @param X Independent categorical variable.
##' @param Y Binary response variable, it can take values of either 1 or 0.
##' @param valueOfGood Value of Y that is used as reference category.
##' @examples
#' X = mtcars$gear
#' Y = mtcars$am
#' ExpInfoValue(X,Y,valueOfGood = 1)
##' @seealso \code{\link[InformationValue:IV]{IV}}
##' @return Information value (iv) and Predictive power class
##'
##' information value
##'
##' predictive class
##'
##' @export ExpInfoValue

ExpInfoValue = function (X, Y, valueOfGood = NULL)
{
  if(is.null(valueOfGood)) {stop("Specify reference category for target variable")}
  val =valueOfGood
  woeTable <- ExpWoeTable(X = X, Y = Y, valueOfGood = val,print=FALSE)
  iv <- attr(woeTable, "iValue")
  if(is.nan(iv)|is.na(iv)) {
    PP<-"Not Predictive"
  }
  else if (iv < 0.09) {
    PP <- "Not Predictive"
  }
  else if (iv < 0.19) {
    PP <- "Somewhat Predictive"
  }
  else if (iv < 0.3) {
    PP <- "Medium Predictive"
  }
  else {
    PP <- "Highly Predictive"
  }
  return(list(`Information values`=iv,`Predictive class`=PP))
}

#' Function provides summary statistics for individual categorical predictors
#'
#' @description Provides bivariate summary statistics for all the categorical predictors against target variables. Output includes chi - square value, degrees of freedom, information value, p-value
#' @usage ExpStat(X,Y,valueOfGood = NULL)
##' @param X Independent categorical variable.
##' @param Y Binary response variable, it can take values of either 1 or 0.
##' @param valueOfGood Value of Y that is used as reference category.
##' @examples
##' X = mtcars$carb
##' Y = mtcars$am
##' ExpStat(X,Y,valueOfGood = 1)
##' @seealso \code{\link[stats:chisq.test]{chisq.test}}
##' @details
##' For a given binary Y variable and X categorical variables, the summary statistics are computed. Summary statistics included Pearson's Chi-squared Test for Count Data, "chisq.test" which performs chi-squared contingency table tests and goodness-of-fit tests. If any NA value present in X or Y variable, which will be considered as NA as in category while computing the contingency table.
##'
##' Also added unique levels for each X categorical variables and degrees of freedom
##'
##' @return The function provides summary statistics like
##'
##' Unique levels
##'
##' Chi square statistics
##'
##' P value
##'
##' Degrees of freedom
##'
##' Information value
##'
##' Predictive class
##' @importFrom stats chisq.test
##' @export ExpStat

ExpStat = function(X,Y,valueOfGood = NULL){
  options(warn = -1)

  if(is.null(valueOfGood)){stop("Specify reference category for target variable")}
  if (class(Y)!="factor") {Y =as.factor(Y)}
  if (class(X)!="factor") {X =as.factor(X)}
  if (anyNA(Y)) {Yvar = addNA(Y)}
  if (anyNA(X)) {Xvar = addNA(X)}
  tb = table(X,Y)
  CTest=chisq.test(tb)
  ## Cramers V
  k <- min(dim(CTest$observed))
  N <- sum(CTest$observed)
  chi2 <- CTest$statistic
  CrV <- round(sqrt(chi2/(N * (k - 1))),2) #indicative of the degree of association

  #CrV_IV <- max(round(ExpInfoValue(X, Y, valueOfGood = valueOfGood)[[1]],3),CrV)
  if(is.nan(CrV)|is.na(CrV)) {Deg_asso <- "Very Weak"}
  else if (CrV < 0.09) { Deg_asso <- "Very Weak"}
  else if (CrV < 0.19) {Deg_asso <- "Weak"}
  else if (CrV < 0.3) {Deg_asso <- "Moderate"}
  else {Deg_asso <- "Strong"}

  TList <- rbind(
    Unique_Levels = length(unique(X)),
    C2Tvalue = round(CTest$statistic,3),
    pval=round(CTest$p.value,3),
    df=CTest$parameter,
    IVvalue = round(ExpInfoValue(X, Y, valueOfGood = valueOfGood)[[1]],3),
    Cram_Value = CrV,
    Degree_Asso = Deg_asso,
    Pred_class=ExpInfoValue(X, Y, valueOfGood = valueOfGood)[[2]])
  return(TList)
}


#' Function provides summary statistics for all character or categorical columns in the dataframe
#'
#' @description This function combines results from weight of evidence, information value and summary statistics.
#' @usage ExpCatStat(data,Target=NULL,result=c("Stat","IV"),clim=10,nlim=10,bins=10,
#' Pclass=NULL,plot=FALSE,top=20,Round=2)
##' @param data dataframe or matrix
##' @param Target target variable
##' @param result "Stat" - summary statistics, "IV" - information value
##' @param clim maximum unique levles for categorical variable. Variables will be dropped if unique levels is higher than clim for class factor/character variable
##' @param nlim maximum unique values for numeric variable.
##' @param bins number of bins (default is 10)
##' @param Pclass reference category of target variable
##' @param plot Inforamtion value barplot (default False)
##' @param top for plotting top information values (default value is 20)
##' @param Round round of value
##' @return This function provides summary statistics for categorical variable
##'
##' Stat-Summary statistics includes Chi square test scores, p value, Information values, Cramers V and Degree if association
##'
##' IV- Weight of evidence and Information values
##'
##' Columns description:
##'
##'  •	Variable – variable name
##'
##'  •	Target -  Target variable label
##'
##'  •	class – name of bin (variable value otherwise)
##'
##'  •	out0 – number of good observations
##'
##'  •	out1 – number of bad observations
##'
##'  •	Total – Total values for each category
##'
##'  •	pct1 – good observations / total good observations
##'
##'  •	pct0 – bad observations / total bad observations
##'
##'  •	odds – Odds ratio [(a/b)/(c/d)]
##'
##'  •	woe – Weight of Evidence – calculated as ln(odds)
##'
##'  •	iv – Information Value  - ln(odds) * (pct0 – pct1)
##'
##' @details
##'Criteria used for categorical variable predictive power classification are
##'
##'If information value is < 0.03 then predictive power = "Not Predictive"
##'
##'If information value is 0.3 to 0.1 then predictive power = "Somewhat Predictive"
##'
##'If information value is 0.1 to 0.3 then predictive power = "Meidum Predictive"
##'
##'If information value is >0.3 then predictive power = "Highly Predictive"
##
##' @examples
##' # Example 1
##' ## Read mtcars data
##' # Target variable "am" - Transmission (0 = automatic, 1 = manual)
##' # Summary statistics
##' ExpCatStat(mtcars,Target="am",result = "Stat",clim=10,nlim=10,bins=10,
##' Pclass=1,plot=FALSE,top=20,Round=2)
##' # Information value plot
##' ExpCatStat(mtcars,Target="am",result = "Stat",clim=10,nlim=10,bins=10,
##' Pclass=1,plot=TRUE,top=20,Round=2)
##' # Inforamtion value for categorical Independent variables
##' ExpCatStat(mtcars,Target="am",result = "IV",clim=10,nlim=10,bins=10,
##' Pclass=1,plot=FALSE,top=20,Round=2)
##' @author dubrangala
##' @importFrom scales wrap_format dollar_format
##' @export ExpCatStat

ExpCatStat <- function(data,Target=NULL,result=c("Stat","IV"),clim=10,nlim=10,bins=10,Pclass=NULL,plot=FALSE,top=20,Round=2)
{
  options(warn = -1)

  if(is.null(result)) stop("Specify the result option either 'Stat' or 'IV' for inforamtion value")
  result = toupper(result)

  if(!is.data.frame(data)) stop("'data must be a numeric vector or data.frame'")
  if(is.null(Target)) stop("'Target variable is missing'")

  xx = as.data.frame(data)

  Yvar = as.factor(xx[,Target])

  if(length(levels(Yvar))<2) stop("Target variable has required atleast 2 categories")

  num_var = names(xx)[sapply(xx, is.numeric)]
  Cat_var <- c(names(xx)[sapply(xx, is.character)],names(xx)[sapply(xx, is.factor)])

  if (length(num_var)>0){
    num_var1 <- num_var[sapply(xx[,num_var], function(x){length(unique(na.omit(x)))>1 & length(unique(na.omit(x)))<=nlim})]
    num_var2 <- num_var[sapply(xx[,num_var], function(x){length(unique(na.omit(x)))>nlim})]
  } else {
    num_var1 = NULL
    num_var2 = NULL
  }

  if((length(num_var1)+length(Cat_var)+length(num_var2))==0) stop("there is no categorical variable in the data")


  if(length(Cat_var) >0){
    Cat_varlst <- Cat_var[sapply(xx[,Cat_var], function(x){length(unique(x))<=clim & length(unique(x))>=2})]
    Cat_varlst <- c(Cat_varlst,num_var1)
    Cat_varlst <- Cat_varlst[!(Cat_varlst %in% Target)]
    rm_var = setdiff (Cat_var,Cat_varlst)

  } else
  {Cat_varlst <- num_var1[!(num_var1 %in% Target)]}

  if (is.null(Pclass)) {Pval=1} else {Pval=Pclass}

  ## Adding Bin for Numeric variables
  if(length(num_var2)>0 & !is.null(bins)) {

    bin_data = lapply(xx[,num_var2], function(x){
      q=quantile(x, probs = c(1:(bins - 1)/bins), na.rm = TRUE, type = 3)
      cuts <- unique(q)
      cuts <- unique(c(min(x),cuts,max(x)))
      tp <- cut(x,cuts, include.lowest =T)
      return(tp)
    })

    bin_data <- cbind.data.frame(bin_data)
    InputData <- cbind(subset(xx,select=Cat_varlst),bin_data)
    variables <- names(InputData)
  } else
  {
    InputData <- xx[,Cat_varlst]
    variables <- names(InputData)
  }

  if (result=="STAT") {
    `IV Value` <- NULL
    Variable <- NULL
    tab2 = sapply(InputData,function(x){ExpStat(x,Yvar,valueOfGood = Pval)})
    tab2 <- data.frame(t(tab2))
    tb_op2 = cbind(Var_name= rownames(tab2),Tar_v=Target,tab2)
    rownames(tb_op2)<-NULL
    tb_op2[,3:8] <- sapply(tb_op2[,3:8], function(x){as.numeric(paste0(x))})
    tb_op2[,-c(3:8)] <- sapply(tb_op2[,-c(3:8)], function(x){as.character(paste0(x))})
    names(tb_op2) = c("Variable","Target","Unique","Chi-squared","p-value","df","IV Value","Cramers V","Degree of Association","Predictive Power")

    if(plot==TRUE){
      varcnt = nrow(tb_op2)
      if(top>varcnt) top=varcnt
      plotdt <- tb_op2[order(tb_op2$`IV Value`,decreasing = T),][1:top,]
      gp_iv = ggplot(plotdt, aes(y=`IV Value`, x=reorder(Variable,`IV Value`),label = paste0(`IV Value`))) +
        geom_bar( stat="identity", position="dodge",fill="tan3")+xlab("Variables")+
        ylab("Inforamtion value")+ geom_text(size = 4, position=position_dodge(width=0),vjust=0.5,hjust=0)+
        scale_x_discrete(labels = wrap_format(8))+
        scale_y_continuous(labels = dollar_format(suffix = "", prefix = ""))+coord_flip()+
        theme(axis.line = element_line(size=1, colour = "black"),
              panel.grid.major = element_line(colour = "#d3d3d3",linetype = "dashed"), panel.grid.minor = element_blank(),
              panel.border = element_blank(), panel.background = element_blank())
      print(gp_iv)
      return(tb_op2)
    }
    else {return(tb_op2)}
  }
  if (result=="IV") {
    tab1<- lapply(InputData, function(x) {ExpWoeTable (x,Yvar,valueOfGood = Pval,print = FALSE,Round=Round)})
    cnm <- names(tab1)
    outp_dat <- do.call("rbind",tab1)
    outp_dat <- data.frame(Variable=rownames(outp_dat),outp_dat)
    rownames(outp_dat) <- NULL
    return(outp_dat)
  }
  else {stop("Input data error or Target variable is not properly defined")}
}
