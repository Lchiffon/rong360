  var myChart = echarts.init(document.getElementById("ID_20150808153549_511087"));
  
                       var options = {
  backgroundColor: '#1b1b1b', 
  color: ['gold','aqua','lime'],
  title : {
  text: '', 
  subtext:'', 
  x:'center',
  textStyle : {
  color: '#fff'  
  }
  },
  tooltip : {
  trigger: 'item',
  formatter: '{b}'
  },
  toolbox: {
  show : true,
  orient : 'vertical',
  x: 'right',
  y: 'center',
  feature : {
  mark : {show: true},
  dataView : {show: true, readOnly: false},
  restore : {show: true},
  saveAsImage : {show: true}
  }
  },
  dataRange: {
  min : 0,
  show: false,
  max : 100,
  y: '60%',
  calculable : true,
  color: ['#ff3333', 'orange', 'yellow','lime','aqua']
  },
  
  series : [
  {
  type:'map',
  itemStyle:{
  normal:{
  borderColor:'rgba(100,149,237,1)', 
  borderWidth: 0.5,
  areaStyle:{
  color: '#1b1b1b'  
  }
  }
  },
  data:[],
  geoCoord: {'上海': [121.48,31.24],
'常州': [119.98,31.82],
'北京': [116.62,40.06],
'广州': [113.31,23.39],
'大连': [121.55,38.97],
'南宁': [108.18,22.62],
'南昌': [115.92,28.86],
'拉萨': [ 90.87,29.37],
'长春': [125.71,44.00],
'包头': [110.01,40.57],
'重庆': [106.65,29.72]},
  
  markLine : {
  smooth:true,
  effect : {
  show: true,
  scaleSize: 1,
  period: 30,
  color: '#fff',
  shadowBlur: 10
  },
  itemStyle : {
  color: 'red',
  normal: {
  borderWidth:1,
  lineStyle: {
  type: 'solid',
  shadowBlur: 10
  },
  label:{show:false}
  }
  },
  
  data : [
  [{name:'北京'}, {name:'上海',value:60}],
[{name:'北京'}, {name:'广州',value:90}],
[{name:'北京'}, {name:'大连',value:40}],
[{name:'北京'}, {name:'南宁',value:20}],
[{name:'北京'}, {name:'南昌',value:90}],
[{name:'北京'}, {name:'拉萨',value:40}],
[{name:'北京'}, {name:'长春',value:90}],
[{name:'北京'}, {name:'包头',value:60}],
[{name:'北京'}, {name:'重庆',value:40}],
[{name:'北京'}, {name:'常州',value:40}]
  ]
  },
  markPoint : {
  symbol:'emptyCircle',
  symbolSize : function (v){
  return 10 + v/10
  },
  effect : {
  show: true,
  shadowBlur : 0
  },
  itemStyle:{
  normal:{
  label:{show:true}
  }
  },
  data : [
  {name:'上海',value:60},
{name:'广州',value:90},
{name:'大连',value:40},
{name:'南宁',value:20},
{name:'南昌',value:90},
{name:'拉萨',value:40},
{name:'长春',value:90},
{name:'包头',value:60},
{name:'重庆',value:40},
{name:'常州',value:40}
  ]	
  }
  }
  ]
  };
  myChart.setOption(options);	
