[x] terminal 中输入 control + c 后退出当前命令的同时会把历史内容也清空，预期应该保留的
[x] terminal 内容超出一页时需要显示滚动条
[x] 诊断日志路径改成可复制的
[x] 去掉 sandboxes 列表顶部的 ”OpenBox“ 标题
[x] sandbox 详情页面布局有点问题，右侧空白过多
[x] sandbox 详情页面诊断日志路路径默认折叠，点击后展开，另外当前没有用到的 event log、boot log、stdout 三个 tab 直接去掉，只展示路径就够了
[x] LOGS 中的日志路径改成可复制的，并且合并到 Basic Info 中，日志内容直接通过 terminal 输出（不管是否是交互式的）
[x] workload 的 stop 按钮改成红色
[x] 移除 settings 中旧的或者不必要的设置项
[x] New Sandboxes 弹窗中的 IMAGE REFERENCE 改成下拉列表，列表中只展示已经下载到本地的镜像
[x] Images 列表中区分展示已下载和未下载的镜像， pull 镜像的按钮改成 add，点击后的弹窗中增加一个 add 按钮，如果用户点击 add 按钮则只添加镜像信息到本地数据库，不下载镜像
[x] 支持 Linux 镜像
[x] stop sandbox 按钮改成红色
[x] terminal 的滚动条和背景融为一体了，看不出来，需要调整一下样式
