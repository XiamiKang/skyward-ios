## Skyward-iOS端

#### 一、编码要求

1. 文档注释统一使用  `///`

#### 二、代码分层命名规范

- 最底层组件命名
  - 如：TXFoundationKit
- 通用组件层命名
  - 如：SWMapKit
- 业务组件层命名
  - 业务模块组件目录以Module开头，方便排序查找，组件名称Module结尾。
  - 例如：首页模块，文件夹名称为ModuleHome，组件名称为：HomeModule

#### 三、分支管理规范

1. master分支：主干分支，用于APP发版

2. ci分支：打包分支，主站代码需要通过mr到该分支后，然后合并到其他子站分支

3. v***分支：各个版本和子站开发分支

4. 代码合并规范：

   - 主站代码开发完成，需要先合并到ci分支
   - 所有子站项目代码统一从ci分支上进行合并，保证代码的时效性
   - 所有的代码合并必须要走MR

   

#### 四、提测及发版规范

1. [测试包提测文档](https://idoc.skyward.com)
2. [各应用市场审核发布台账](https://idoc.skyward.com)
3. [超A上架规范](https://idoc.skyward.com)

#### 五、接口规范

 *iOS端所有接口文档中的请求body中有double的，咱们统一传string*


#### 六、路由规范

路由跳转，统一用TXRouter触发

````
1、不需要回调的路由
TXRouter.handle("txts://device/list")
2、需要回调的路由
 TXRouter.handle("txts://device/list") { obj in
     /// 这里是路由执行后的回调，可以在这里写逻辑  
 }
````



#### 七、三方库私有化规范

所有针对三方库的修改，需要在私有化的`readme.md文件中说明修改的内容`，每次修改都要备注修改原因和修改内容





#### 八、代码提交规范

目前 **[AngularJS](https://github.com/angular/angular/commits/master)** 在github上的提交规范是被业内很多人认可的，也被大家逐渐引用。同时针对这种提交格式也有成熟的工具，来根据commit的message记录自动生成Change Log内容。所以我们也采用同样的规范来进行约束。

[AngularJS Git Commit Message规范](https://docs.google.com/document/d/1QrDFcIiPjSLDn3EL15IJygNPiHORgU1_OOAqWjiDU5Y/edit#heading=h.greljkmo14y0) - Google Doc文档需翻墙。

1. 格式：Commit Message包括三部分内容： header，body。其中header是必须的，body可以省略。
   
   ```
   <type>(<scope>): <subject>
   <BLANK LINE>
   <body>
   <BLANK LINE>
   ```
   
   
   
2. header: header部分只有一行，包括三个字段type（必需）、scope（可选）和subject（必需）。

   - type：用于说明commit的类别。
     - feat: 新功能(feature)
     - fix：修复bug
     
     - update: 普通的内容修改
     - docs：文档
     
     - style：格式(不影响代码运行的变动)
     
     - refactor：重构(即不是新增功能，也不是修改bug的代码变动)
     - test：增加测试
     - chore：构建过程或辅助工具
     
   
      - scope：用于说明commit影响的范围，比如数据层、控制层、视图层等等，视项目不同而不同。
   
   
      - subject：commit目的的简短描述。
   
   	```shell
   		# 新功能
   		feat: 轻应用离线包管理
   		
   		# 修复bug
   		fix: 修复下载的xmind类型文件，预览识别类型不正确的问题
   		
   		# 文档更新
   		docs: 轻应用离线功能的文档更新
   		
   		# 重构
   		refactor: 优化下载预览
   		
   		# 增加测试
   		test: 下载逻辑增加单元测试
   		
   		# 自动化、脚本等
   		chore: 修改sonar扫描的配置信息
   
3. body：对本次commit的详细描述，可以分成多行。

   ```shell
   More detailed explanatory text, if necessary. Wrap it to
   about 72 characters or so.
   
   Further paragraphs come after blank lines.
   
   - Bullet points are okay, too
   - Use a hanging indent
   ```

