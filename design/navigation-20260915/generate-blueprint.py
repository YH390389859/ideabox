"""Native editable SVG study: one capture entrance, an explicit manual alternative."""
from pathlib import Path
from html import escape
from math import sin, cos, pi
ROOT=Path(__file__).resolve().parent
BG,INK,BLUE,LIME,CLAY='#F3F0E8','#202A2B','#3555E8','#D9EB77','#C96C50'
DIM,LINE='#737A73','#D3D6C9'
out=[]
def emit(s):out.append(s)
def text(x,y,s,size=14,fill=INK,weight=400,extra=''):
    emit(f'<text x="{x}" y="{y}" font-size="{size}" fill="{fill}" font-weight="{weight}" {extra}>{escape(s)}</text>')
def mono(x,y,s,size=10,fill=DIM,extra=''):text(x,y,s,size,fill,500,f'font-family="SFMono-Regular, Menlo, monospace" {extra}')
def rect(x,y,w,h,fill,extra=''):emit(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" fill="{fill}" {extra}/>')
def path(d,stroke=INK,width=1,fill='none',extra=''):emit(f'<path d="{d}" stroke="{stroke}" stroke-width="{width}" fill="{fill}" {extra}/>')
def line(x1,y1,x2,y2,color=LINE,width=1,extra=''):path(f'M{x1} {y1}L{x2} {y2}',color,width,extra=extra)
def circle(x,y,r,fill,extra=''):emit(f'<circle cx="{x}" cy="{y}" r="{r}" fill="{fill}" {extra}/>')
def group(transform=''):emit(f'<g transform="{transform}">' if transform else '<g>')
def end():emit('</g>')
def shuttle(x,y,w=50,h=32,fill=INK):path(f'M{x} {y+h/2}Q{x+w/2} {y-h*.22} {x+w} {y+h/2}Q{x+w/2} {y+h*1.22} {x} {y+h/2}Z','none',0,fill)
def arrow(x,y,color=INK):path(f'M{x-5} {y+5}L{x+5} {y-5}M{x-4} {y-5}H{x+5}V{y+4}',color,1.4,extra='stroke-linecap="round" stroke-linejoin="round"')
def startphone(x):
    group(f'translate({x} 172)')
    rect(-1,-1,404,876,BG,'rx="44" stroke="#ADB4A8" stroke-width=".7" filter="url(#deviceShadow)"')
    emit('<g clip-path="url(#phoneClip)">')
    rect(0,0,402,874,BG)
    text(31,33,'9:41',14,INK,650)
    rect(142,10,118,28,INK,'rx="14"')
    for n,h in enumerate([4,7,10,13]):rect(309+n*5,31-h,3,h,INK,'rx="1"')
    path('M337 23Q345 16 353 23M340 26Q345 21 350 26M344 29L346 29',INK,1.8,extra='stroke-linecap="round"')
    rect(361,20,23,12,'none','rx="3" stroke="#202A2B" stroke-width="1"')
    rect(363,22,18,8,INK,'rx="1.5"');rect(385,24,2,4,INK,'rx="1"')
def closephone():
    rect(133,857,136,5,INK,'rx="2.5"');end();end()
def settings(x=365,y=76):
    circle(x,y,9,'none','stroke="#202A2B" stroke-width="1.1"');circle(x,y,3,'none','stroke="#202A2B" stroke-width="1.1"')
    for i in range(8):
        t=i*pi/4;line(x+10*cos(t),y+10*sin(t),x+12*cos(t),y+12*sin(t),INK,1.2)
def sample(points):return 'M'+'L'.join(f'{x:.2f} {y:.2f}' for x,y in points)
def home_nav():
    rect(0,773,402,73,BG);line(24,773,378,773,INK,.8)
    for x,label,active in [(46,'今天',True),(123,'习惯',False),(200,'收集',False)]:
        text(x,815,label,13,INK if active else DIM,600 if active else 400,extra='text-anchor="middle"')
        if active:circle(x,834,2.1,BLUE)
    shuttle(270,783,108,58,INK);text(316,817,'说一点',13,BG,550,extra='text-anchor="middle"');arrow(351,811,BG)
def home_header():
    mono(24,77,'01 / TODAY / ON THE LOOM',9,BLUE,extra='letter-spacing="1.2"')
    for i in range(5):line(350+i*4,61,350+i*4,79,INK,.8)
    for i in range(5):line(347,63+i*4,370,63+i*4,INK,.8)
    text(20,159,'15',74,INK,300,extra='letter-spacing="-6"')
    text(128,125,'九月',18,INK,500);text(128,147,'星期二',11,DIM)
    line(288,105,288,157,LINE,.8)
    text(309,133,'0',33,BLUE,500);text(336,133,'/ 10',13,DIM)
    text(309,155,'今日已完成',9,DIM)
    text(23,210,'今天，织一点。',31,INK,500,extra='letter-spacing="-1.2"')
    text(24,240,'不必完美，每一根线都算数。',12,DIM)
def weave():
    group('translate(14 266)')
    colors=['#BDC4B4','#BAC1B3','#C2C6B9','#BABFB2','#C4C8BC','#C4C3B5','#B8C0B1','#C1C6B7','#BAC2B3','#C4C5B6']
    def pt(u,v):
        return 40+272*u+25*sin(v*pi)+18*sin(u*pi)*sin(v*pi), 15+215*v+23*sin(u*2*pi+v*1.3)+12*sin(v*pi)*cos(u*pi)
    for n in range(100):
        u=n/99
        path(sample([pt(u,j/100) for j in range(101)]),colors[min(9,n//10)],.7,extra='opacity=".76"')
    for n in range(90):
        v=n/89
        path(sample([pt(j/100,v) for j in range(101)]),'#B3BBA9',.62,extra='opacity=".62"')
    for n in range(8):
        u=.575+n*.008
        path(sample([pt(u,j/100) for j in range(101)]),BLUE,.67,extra='opacity=".82"')
    for x,y,s in [(4,65,'阅读'),(280,20,'喝水'),(284,247,'早睡')]:
        rect(x,y-13,79,25,BG);circle(x+7,y,4,'none','stroke="#9BA994" stroke-width="1"');text(x+18,y+4,s,10,INK,500)
    line(79,65,123,97,'#AEB8A3',.7);line(280,20,265,46,'#AEB8A3',.7);line(284,247,257,224,'#AEB8A3',.7)
    end()
emit('''<svg xmlns="http://www.w3.org/2000/svg" width="1500" height="1170" viewBox="0 0 1500 1170" role="img" aria-labelledby="title description">
<title id="title">日常织机 · 记录入口重新设计</title><desc id="description">首页仅保留一个说一点入口；对话输入区域提供清楚的自己记选项；手动记录保留日记、录音、链接和习惯。</desc>
<defs><clipPath id="phoneClip"><rect width="402" height="874" rx="43"/></clipPath><filter id="deviceShadow" x="-20%" y="-10%" width="140%" height="130%"><feDropShadow dx="0" dy="12" stdDeviation="18" flood-color="#202A2B" flood-opacity=".065"/></filter></defs><g font-family="-apple-system, BlinkMacSystemFont, PingFang SC, Hiragino Sans GB, sans-serif">''')
rect(0,0,1500,1170,'#E7E7DE')
mono(84,47,'DAILY LOOM   /   ONE ENTRANCE, YOUR WAY',11,INK,extra='letter-spacing="1.6"')
text(82,105,'留一个入口，给表达。',40,INK,650,extra='letter-spacing="-1.8"')
text(545,103,'说出来，或自己记。都很自然。',15,DIM)
mono(1418,48,'15 SEP 2026',11,INK,extra='text-anchor="end"')
mono(1418,77,'CAPTURE / NAVIGATION STUDY',10,DIM,extra='text-anchor="end"')
line(84,132,1418,132,'#C5CBBF',.8)
# Home: three navigation destinations and just one capture action.
startphone(84);home_header();weave()
mono(24,564,'TOUCH THE THREAD / 轻点线端打卡',8,DIM)
text(377,564,'全部 10 根线 ↗',10,INK,500,extra='text-anchor="end"')
line(24,591,378,591,LINE,.8)
mono(24,615,'RECENTLY WOVEN',8.5,BLUE,extra='letter-spacing="1.2"')
text(24,651,'最近，留下的。',23,INK,500,extra='letter-spacing="-.7"')
rect(24,674,354,78,'#E9E9DE')
line(38,692,38,734,CLAY,2)
text(51,701,'留白，是为了让重要的事发生。',12,INK,500)
mono(51,729,'DIARY / TODAY',8,DIM,extra='letter-spacing=".8"');arrow(359,717)
home_nav();closephone()
# Agent: keep conversation as the main path, put direct capture where it belongs.
startphone(550)
path('M35 68L27 76L35 84',INK,1.5,extra='stroke-linecap="round" stroke-linejoin="round"')
mono(201,80,'一段新对话',11,INK,extra='text-anchor="middle"');settings()
mono(25,131,'04 / TALK TO LOOM',9,BLUE,extra='letter-spacing="1.8"')
text(22,186,'说一点，',43,INK,650,extra='letter-spacing="-2"');text(22,238,'织进去。',43,INK,650,extra='letter-spacing="-2"')
text(25,272,'日常、习惯、灵感，都从一句话开始。',12,DIM)
group('translate(15 288)')
def curve(t,s):return 187+124*cos(t)+s*22*cos(2*t+.65),130+84*sin(2*t)*.8+35*sin(t)+s*(13*cos(t)-5*sin(3*t))
for i in range(41):
    s=(i-20)/20;path(sample([curve(.1+j*2*pi/260,s) for j in range(250)]),BLUE,.58 if i%5 else .82,extra=f'opacity="{.55 if i%5 else .85}"')
path('M32 178C-11 226 82 247 127 228C207 195 264 207 278 249C287 276 314 286 340 277',BLUE,.85)
for i in range(7):path(f'M{48+i*.6} {78+i*.7}C{100+i*.7} {35+i*.5} {113+i*.8} {172+i*.8} {204+i*.5} {172+i*.4}C{254+i*.4} {172+i*.3} {262+i*.8} {119+i*.5} {315+i*.4} {96+i*.6}',CLAY,.62,extra='opacity=".78"')
group('translate(253 164) rotate(-30)');shuttle(0,0,76,31,LIME);path('M17 15.5H58',INK,.8);circle(58,15.5,2.5,BG);end()
mono(19,290,'A THOUGHT BECOMES A THREAD',7.2,DIM,extra='letter-spacing=".7"');end()
line(24,622,378,622,LINE,.7);text(24,650,'从这里开始',10,DIM)
for y,label,number in [(684,'记下今天的小事','01'),(727,'帮我整理一个想法','02')]:
    mono(24,y,number,9,BLUE);text(52,y,label,14,INK,500);arrow(365,y-5,INK)
    if y==684:line(52,701,378,701,LINE,.6)
line(24,760,378,760,INK,.8);text(24,794,'今天有什么想留下？',14,DIM)
shuttle(320,773,58,37);path('M342 797L349 786L356 797M349 787V801',BG,1.5,extra='stroke-linecap="round" stroke-linejoin="round"')
mono(24,831,'DEEPSEEK',8.5,DIM,extra='letter-spacing="1.2"');circle(94,828,2.5,BLUE)
text(342,831,'自己记',11,INK,500,extra='text-anchor="end"');arrow(363,826,INK)
closephone()
# Manual sheet: a clear secondary route, visibly a choice of recording materials.
startphone(1016)
mono(201,80,'一段新对话',11,INK,extra='text-anchor="middle"');settings()
rect(0,45,402,829,INK,'opacity=".18"')
path('M0 166Q0 138 28 138H374Q402 138 402 166V874H0Z','none',0,BG)
rect(178,149,46,4,'#BDC3B6','rx="2"')
mono(24,189,'KEEP IT IN YOUR OWN WAY',8.8,BLUE,extra='letter-spacing="1.3"')
text(22,243,'按自己的方式，',31,INK,550,extra='letter-spacing="-1.2"');text(22,284,'留下。',31,INK,550,extra='letter-spacing="-1.2"')
text(24,316,'不经过 AI，直接存到这台 iPhone。',12,DIM)
for i,(y,title,sub,color,tag) in enumerate([(347,'写下来','文字、心情，还有此刻的想法。','#FBFAF3','01 / NOTE'),(453,'录一段','留住声音，也留住说话的语气。','#E8EBDB','02 / VOICE'),(559,'留链接','收下值得回来的那一页。','#F0E4D8','03 / LINK'),(665,'添加习惯','从一件想坚持的小事开始。','#E4E8EB','04 / HABIT')]):
    rect(24,y,354,92,color)
    mono(40,y+21,tag,7.5,DIM,extra='letter-spacing=".9"')
    text(40,y+48,title,20,INK,550);text(40,y+73,sub,10,DIM)
    arrow(352,y+47,INK)
    if i==0:
        path(f'M272 {y+19}H302L312 {y+29}V{y+69}H272Z','#C2C8B8',.7)
        for n in range(4):line(280,y+36+n*7,303,y+36+n*7,'#C2C8B8',.7)
    if i==1:
        for n,h in enumerate([9,19,31,17,37,25,13]):line(276+n*5,y+45-h/2,276+n*5,y+45+h/2,'#AAB79B',1.2)
    if i==2:
        path(f'M280 {y+46}L292 {y+34}Q302 {y+26}309 {y+35}Q315 {y+42}306 {y+51}L296 {y+60}',CLAY,1.1,extra='opacity=".65"')
        path(f'M300 {y+44}L290 {y+54}Q280 {y+63}273 {y+54}Q267 {y+47}276 {y+38}L285 {y+29}',CLAY,1.1,extra='opacity=".65"')
    if i==3:
        for n in range(5):line(272+n*8,y+27,272+n*8,y+64,'#A6B4BD',.8)
        for n in range(5):line(268,y+29+n*8,309,y+29+n*8,'#A6B4BD',.8)
        circle(288,y+45,3,BLUE)
line(24,785,378,785,LINE,.7)
text(24,813,'随时回来，再把日常说给我听。',11,DIM)
mono(378,838,'SAVED ON DEVICE',7.5,DIM,extra='text-anchor="end" letter-spacing=".8"')
closephone()
for x,n,label,caption in [(84,'01','ONE ENTRANCE','浏览与记录，各有位置。'),(550,'02','SPEAK OR WRITE','一句话，也可以自己记。'),(1016,'03','KEEP YOUR WAY','离线可用，原有能力都在。')]:
    mono(x,1076,f'{n}  {label}',10,INK,extra='letter-spacing="1.4"');text(x,1101,caption,12,DIM)
line(84,1127,1418,1127,'#C5CBBF',.8)
mono(84,1150,'ONE PRIMARY ACTION / CLEAR ALTERNATIVE / QUIET MOTION',8.5,INK,extra='letter-spacing="1.2"')
for i,(color,label) in enumerate([(BG,'PAPER'),(INK,'INK'),(BLUE,'COBALT'),(LIME,'ACID'),(CLAY,'CLAY')]):
    x=1036+i*77;rect(x,1141,11,11,color,'stroke="#AEB7A6" stroke-width=".4"');mono(x+16,1150,label,7,DIM)
end();emit('</svg>')
(ROOT/'blueprint.svg').write_text('\n'.join(out),encoding='utf-8')
print(ROOT/'blueprint.svg')
