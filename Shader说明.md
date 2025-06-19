# Shader说明

>  因为我觉得再加下去我自己快看不懂自己的命名方式了

**Texture文件夹**中用于存放各种所需要的贴图

**模型文件夹**中存放模型

## 脚本信息

## 创意

halfToon：卡通点阵Shader

slice_SSS滑条调子：SSS+兰伯特的一个应用，主要是remapTex（需要SSS贴图）

光感_模拟高光：有两个用if判断出来的“高光”效果（需要同shader名贴图）

排线：兰伯特+深度+排线贴图（需要排线贴图）

锈效果：镜面反射+兰伯特（需要锈噪声贴图）

OldSchoolPro：简单的一套光照模型
## 理论复现

AO.shader/shadergraph:环境光遮蔽+3col方法实现（需要模型猴子和AO贴图）

CG 阴影.shder：在默认渲染管线情况下的CG语言阴影实现的shader

HLSL_Shadow:URP渲染管线下HLSL实现的阴影

Lambert：兰伯特shader

OldSchool_Mix:兰伯特+冯模型+阴影+AO+3Col的一个集合shader（需要模型猴子和AO贴图）

matcap.shader/shadergraph：matcap复现（贴图见matcap文件夹）

菲涅尔：菲涅尔复现

Cubemap.shader :cubeMap复现