---
title: Introduction to R
author: Chiffon
mode : selfcontained
framework: revealjs
widgets: mathjax
hitheme : tomorrow
revealjs:
  theme: Sky
  transition: slide
  center: "true"
bootstrap:
  theme: amelia
navbar:
  title: Slidify
  items: 
    - {item: Home, href: index,  icon: home}
    - {item: "Start", href: start, icon: signin}
    - {item: Author, href: about, icon: pencil}
    - {item: Style, href: style, icon: hand-right, class: dropdown, 
        dropdown: true, menu: [
         {item: io2012, href: 'samples/intro'},
         {item: deck.js, href: 'samples/deck.js'},
         {item: shower, href: 'samples/shower'},
         {item: landslide, href: 'samples/landslide'}
        ]
      }
    - {item: Customize, href: customize, icon: gift}
    - {item: Extend, href: extend, icon: cogs}
    - {item: Publish, href: publish, icon: github}
---



<style>

.title-slide {
  background-color: #e2e2e2;
}

.title-slide hgroup > h1{
  font-family: 'Oswald', sans-serif;
  color: #202020;
}

.title-slide hgroup > h2{
  font-family: 'Signika Negative', 'Calibri', sans-serif;
  color: #202020;
}


strong{
 color: #4876FF;
}
</style>

## Rong360 Open Research
### 融360比赛经验分享
<small> Rank 2nd in Data Mining Part</small><br/>
<small> Created by [Chiffon](http://chiffon.gitcafe.io)</small>

<script src="./libraries/jquery.min.js"></script>
<script>
			document.write( '<link rel="stylesheet" href="libraries/frameworks/revealjs/css/print/' + ( window.location.search.match( /print-pdf/gi ) ? 'pdf' : 'paper' ) + '.css" type="text/css" media="print">' );
		</script>




---
## OUTLINES

- 背景
- 分析流程
- 效果评估
- 其他问题


---
## Intro.
<http://openresearch.rong360.com/>

<iframe src="http://openresearch.rong360.com/" height=500px width =80%></iframe>

---
## 背景简介

![pic/rong360.png](pic/rong360.png)
- 融360是一家新兴的互联网金融公司
- 为小额贷款,信用卡等服务提供第三方申请平台
- 申请流程

	> - 用户申请
	> - 提交银行审核	
	> - 得到反馈(通过/未通过)


---
### 待解决的问题:
## 预测申请是否通过

- 申请流程

	>- .grow 用户申请
	>- .highlight-red 评估申请
	>- .grow 提交银行审核	
	>- .grow 得到反馈(通过/未通过)


---
## 分析流程

- 数据部分
	+ 数据的清理
	+ 特征工程
- 建模过程
	+ 描述性模型
	+ 预测性模型
- 评估过程
	+ 线下评估
	+ 线上提交

--- &vertical ds:soothe
## 数据部分

***
## 原始数据
- `quality.final.txt`
	+ 用户属性数据
	+ 150W
- `product.final.txt`
	+ 产品属性数据
	+ 5W
- `user.final.txt`
	+ 用户浏览记录数据
	+ 24W

***
## 训练与测试数据
- `order_train.txt`(labeled)
	+ 审核结果数据
	+ 14W
- `order_test_no_label.txt`(no label)
	+ 3W
- 以F1值作为评价标准,每天三次提交机会
	+ $F_1 = 2\frac{precision*recall}{precision+recall}$

***
## 提供的字段:

- 用户: 学历,职业,财产,收入,公积金,征信,房,车..
- 产品: 额度,银行,城市,申请人数,是否需要房/车/本地户口...
- 用户浏览记录: 不同页面的pv,申请次数等..

***
## 清理步骤
- 数据表之间的join
- 去除缺失值较多的变量

![pic2](pic/data.png)

***
## 特征工程

增加新的变量:
- 产品匹配(金额,条件)
- 是否有房(房贷,房产价值,居住状态)
- 所在城市情况(申请笔数,银行数量)
- 贷款额
- 访问记录
- ...

***
## 代码部分
[codes](code.r)


--- &vertical ds:soothe
## 建模过程

***
## 描述型模型
- Logistic
	- 因子变量转化为Dummy Variable
	- city_id效果很好
- 优点
	- 可以给出各个变量对于最终结果的关系
	- 基于业务判断是否合理
- 缺点
	- 但计算时间较长
	- 预测效果也一般(f1最高不超过0.30)

***
```
# load("tr4.Rdata")
model = glm(result ~ . -bank_id , 
			data = train_final,
			family = "binomial")
summary(model)
pre = predict(model, test_final)
out = (pre > 0.215) + 0
writeLines(as.character(out), "submit/3.26.1.txt") # 0.2985

```


***
## 描述型模型
- rpart
	- 评价项目风险，判断其可行性
	- 基于Gini系数来进行分割.  
![rpart](pic/rpart.png)


***
## 预测型模型
- GBM,SVM
	- GBM结果并不稳定(离线测试结果与实际测试差距很大)
	- 作为一个弱分类器来聚合(0.32)
- SVM
	- 较多缺失变量和因子变量
	- 没有训练该模型

***
## 预测型模型
- xgboost
	- 自动利用CPU的多线程进行并行
	- 同时在算法上加以改进提高了精度
	- 缺失值较好的处理(0.35-0.36)
	
***
## Stacking(模型聚合)
- Ensemble Learning的一种<https://en.wikipedia.org/wiki/Ensemble_learning>
- 采用xgboost不同的参数,变量作为输入模型
- 输出采用投票方式
- 筛选较好模型来进行聚合

--- &vertical ds:soothe
## 模型评价

***
## 离线测试方案
- 以F1值作为评价标准,每天三次提交机会
	+ $F_1 = 2\frac{precision*recall}{precision+recall}$
- 通过比例
	+ 训练集20%
	+ 测试集10%
	
	
***
### 离线测试方案
## 交叉验证Vs.时间分割

>- 交叉验证F1可以达到0.5以上,测试集不到0.3
>- 时间分割,用时间最晚的20%数据作为测试集
>- 训练/测试/预测的F1值大约为0.4/0.38/0.36

***
### 离线测试方案
## 阈值的选择
- 预测结果为response[0,1]
- 提交的结果为{0,1}
- 选择合适的阈值
	
	>- 选择在train_data里面最优阈值
	>- 选择response最高的8000个作为阈值的界限
	>- 0.215

---
## Thanks

[codes](code.r)

[文档](rong360.docx)

[七风阁](http://chiffon.gitcafe.io)
<script>
$('ul.incremental li').addClass('fragment')
</script>
