# -----------------------------
# Author: xcatzix  
# mailto: 3949745980@qq.com  
# Desc: plasmusic需求/计划文档  
# -----------------------------
# 需求如下:  
1. General设置页面,No media found behavior, 在没有播放媒体时,需要能够显示text;  
   在播放媒体是也可以设置显示text,即需要能够关闭播放媒体时显示的媒体播放的text,如歌词;  
   显示的文本,可在General页面设置,也可读取${HOME}/.cache/plasMusic/plasMtext.txt,默认读取General页  
   面设置, 可选择读取plasMtext.txt的文本.
2. Panel view设置页面,去掉backward control, play/pause control和forward control.
3. Full view设置页面,把media player selector放到progress bar的位置且宽度使用progress bar的宽度设置;  
   去掉progress bar.  
4. 去掉点击照片打卡播放器这个功能, 关掉提示"this player can't be raised".  
5. Full view设置页面, 去掉volume control, shuffle control, playback controls, loop control,   
   Minimum/Maximum resizable width 和去掉soundbars.  
6. Compact上显示,从左到右,顺序为text, soundbars和icon,用户可以选择显示或不显示这些项目; 去掉用户交
   互的媒体控制.  
7. 将Album placeholder设置为让用户选择文件夹; 不设置,则显示媒体封面; 选择文件夹时,默认自动选择以名  
   字升序排列的第一张,作为显示目标; 用户可点击照片两边,顺序翻页; 不再翻页时,即显示此次选择的照片显  
   示; 设置开关,播放媒体是可以选择文件夹内的照片显示,即可以关闭媒封面; 没有媒体播放时,若设置了文件  
   夹, 则显示文件夹内的照片.  
8. 为显示的媒体封面或照片设置fixed width.  
9. Song text position: 设置为Above/Under media player selector.text position和media player selector  
   之间用一条横线分割.  
10. 增加一个API页面, 用于获取html订阅,入口在player selector一排,(如图plasmusic-Full.png).  
11. 将plasmusic-bar合并到lyrics-on-panel, 合并后名称为plasmusic.  
12. 将lyrics-on-panel的长度改写为可随内容伸缩的,可设置伸缩最大长度. 去掉title,只显示歌词,单行显示,  
    增加歌词滚动, 滚动方式使用plasmusic滚动功能.  
12. 去掉无用代码.  