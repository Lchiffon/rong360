library(caret)
library(dplyr)

##################################读取数据

product = read.table("data/product.final.txt",
                           header = T,sep = "\t") 

product_final = select(product,-is_p2p) %>%
                mutate(.,
                early_repayment_na = is.na(early_repayment)+0,
                penalty_na = is.na(penalty)+0,
                apply_ratio = fangkuan_num/apply_num)
product_final$apply_ratio[is.na(product_final$apply_ratio)] <- 0 

apply(product_final,2,function(x) sum(is.na(x)))
save(product_final,file = "newdata/product.Rdata")


rm(list = ls())


##########################################quality
quality = read.table("data/quality.final.txt",
                     header = T,sep = "\t")


quality =   group_by(quality,user_id) %>%
  summarise(.,
            city_id = first(city_id),
            application_type = first(application_type), 
            application_term = first(application_term), 
            application_limit = first(application_limit), 
            op_type = first(op_type),
            col_type = first(col_type), 
            user_loan_experience = first(user_loan_experience), 
            user_has_car = first(user_has_car), 
            user_income_by_card = first(user_income_by_card), 
            user_work_period = first(user_work_period), 
           col_value = first(col_value),
          house_payment_records = first(house_payment_records), 
            car_value = first(car_value),
            col_has_mortgage = first(col_has_mortgage),
            reapply_count = all(is.na(reapply_count)), 
            product_type = first(product_type), 
            apply_from = first(apply_from), 
            platform =  first(platform), 
            spam_score = first(spam_score), 
            mobile_verify = first(mobile_verify), 
            source = first(source), 
            medium = first(medium),            
            mobile_source = first(mobile_source), 
            mobile_medium = first(mobile_medium), 
            bank_id = first(bank_id),
            quality_amount = n()  
  )


quality_final = quality
save(quality_final,file = "newdata/quality.Rdata")
##load("newdata/quality.Rdata")

user = read.table("data/user.final.txt",head = T,sep ="\t")
me = first
#   function(x){
#   mean(x,na.rm=T)
# }
# name.user = names(user)
user = group_by(user,user_id) %>%
  summarise(.,pv = me(pv),
            pv_index_loan = me(pv_index_loan), 
            pv_apply_total = me(pv_apply_total), 
            pv_ask = me(pv_ask), 
            pv_calculator = me(pv_calculator), 
            order_count_loan = me(order_count_loan), 
            pv_daikuan = me(pv_daikuan), 
            pv_credit = me(pv_credit), 
            pv_search_daikuan = me(pv_search_daikuan), 
            pv_detail_daikuan = me(pv_detail_daikuan), 
            pv_date = me(date),user_amount = n())
# names(user) = c(name.user,"user_amount")
user_final = user
save(user_final,file = "newdata/user.Rdata")

rm(list = ls())
load("newdata/product.Rdata")
load("newdata/quality.Rdata")
load("newdata/user.Rdata")
train = read.table("data/order_train.txt",header = T,sep = "\t")
test = read.table("data/order_test_no_label.txt",header = T,sep = "\t")




train_final = left_join(train,user_final,by = "user_id") %>%
  left_join(.,quality_final,by = "user_id") %>%
  left_join(.,product_final,by = "product_id") 

test_final = left_join(test,user_final,by = "user_id") %>%
  left_join(.,quality_final,by = "user_id") %>%
  left_join(.,product_final,by = "product_id") 


## All completed cases
dim(train_final)
# [1] 143152     59
dim(test_final)
# [2] 36108    58


yun = rbind(train_final[,-6],test_final)

##################### 1 city_fit

city_fit  = yun %>% 
      group_by(.,city_id.x,city_id.y) %>%
      summarise(.,n = n()) %>% 
      arrange(.,desc(n)) %>%
      summarise(.,cityFit = first(as.character(city_id.y)))

yun = left_join(yun,city_fit,by = 'city_id.x') %>%
        mutate(.,city_fit = 0+(as.character(city_id.y) == cityFit),
                  city_blank = is.na(city_id.x)) %>%
        select(.,-c(city_id.y,cityFit)) %>%
        rename(.,city_id = city_id.x)
  
######################### 2 limit

yun = mutate(yun,big_limit = limit>100 & limit!=200,
                  med_limit = limit<100 & limit>50 & limit%%10!=0,
                  dig_limit = round(limit) != limit & 
               !(limit %in% c(2.5,3.5,1.5,4.5)  ))


######################### house


house_function = function(col_type,house_payment_records,
                          col_has_mortgage,col_value){
  a1 = col_type %in% c(1,2,3,4,5,6,8,10,12,14,16,100) 
  a2 = house_payment_records == 1 
  a3 = col_has_mortgage == 2 
  a4 = col_value != 0
  any(a1,a2,a3,a4,na.rm = T)
}

yun = mutate(yun,house_1 = col_type %in% c(1,2,3,4,5,6,8,10,12,14,16,100),
                house_2 = col_value != 0)


table(yun$house_1[1:143152],train_final$result)


train_final = cbind(yun[1:143152,],train$result)
test_final = yun[143153:179260,]
AddVariable = function(data = train,yun = yun){
  require(dplyr)
  prepare1 = yun %>% group_by(.,city_id) %>% 
    summarise(.,city_amount = n())
  prepare2 = yun %>% group_by(.,bank_id.y) %>% 
    summarise(.,bank_amount = n())
  
  data = left_join(data,prepare1,by = "city_id")  %>%
    left_join(.,prepare2,by = "bank_id.y")
  
  mutate(data,weekday = factor(date%%7),
         month = factor(date%%365%/%31),
         fit_user = is.na(user_amount),
         fit_quality = is.na(quality_amount),
         big_city = city_amount >1000,
         med_bank = bank_amount > 30,
         big_bank = bank_amount >100,
         house_3 = house*house_1,
         house_4 = house*house_2*house_1
  ) 
  
}



test_final = AddVariable(data = test_final,
                         yun = yun) %>% 
  select (.,-c(bank_id.y,
               product_id,user_id))


train_final = AddVariable(data = train_final,
                          yun = yun) %>% 
  select (.,-c(bank_id.y,
               product_id,user_id))

train_final[is.na(train_final)] = -10000
test_final[is.na(test_final)] = -10000

levels = table(trainx$city_id) %>%
          sort(.,decreasing = T)



train_final = cbind(train_final,j1)
test_final = cbind(test_final,j2)

dim(train_final)[1] -> n

index = round(n*0.8):n

trainx = train_final[-index,]
testx = train_final[index,]
save(train_final,test_final,trainx,testx,file = "tr4.Rdata")
rm(list = ls())

load("tr4.Rdata")
require(xgboost)
require(methods)
require(plyr)

apply(trainx,2,function(x) sum(x ==-10000))

load("newdata//user.Rdata")
name = names(user_final)
names(trainx) %in% name
trainx = trainx[,!names(trainx) %in% name]
testx = testx[,!names(testx) %in% name]
train_final = train_final[,!names(train_final) %in% name]
test_final = test_final[,!names(test_final) %in% name]


fc = function(pre=res,labels = train$result){
  tp = sum(pre == 1 & labels == 1)/sum(pre == 1)
  fp = sum(pre == 1 & labels == 1)/sum(labels == 1) 
  2*tp*fp/(tp+fp)
}


change = function(x){
  as.numeric(x)
}




label <- as.numeric(as.character(trainx[,69]))

data <- as.matrix(colwise(change)(trainx[,-69]))

data2 <- as.matrix(colwise(change)(testx[,-69]))
label2 = as.numeric(as.character(testx[,69]))
# weight <- as.numeric(dtrain[[32]]) * testsize / length(label)

xgmat <- xgb.DMatrix(data, label = label, missing = -10000)
param <- list("objective" = "binary:logistic",
              "bst:eta" = 0.05,
              "bst:max_depth" = 5,
              "eval_metric" = "logloss",
              "gamma" = 1,
              "silent" = 1,
              "nthread" = 16 ,
              "min_child_weight" =1.45
)
watchlist <- list("train" = xgmat)
nround =300
print ("loading data end, start to boost trees")





label3 <- as.numeric(as.character(train_final[,69]))
data3 <- as.matrix(colwise(as.numeric)(train_final[,-69]))


data4 <- as.matrix(colwise(as.numeric)(test_final))

xgmat <- xgb.DMatrix(data3, label = label3, missing = -10000)

bst2 = xgb.train(param, xgmat, nround, watchlist);
# bst.cv = xgb.cv(param, xgmat, nround,nfold = 10,watchlist)
pre3 = predict(bst2,data3)

ans1 = rep(0,999)
for (i in 1:999){
  j = 0.001*i 
  res = pre3>j
  ans1[i] = fc(pre=res,labels = label3)
}
summary(ans1)

which.max(ans1)

pre.final = predict(bst2,data4)
out  = pre.final>0.23
writeLines(as.character(out),"submit/4.14.1.txt") # 0.3417
