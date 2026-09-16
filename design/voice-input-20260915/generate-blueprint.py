"""Native editable SVG study: quiet speech-to-text within the Daily Loom composer."""
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
def mic(x,y,color=INK):
    rect(x-3.5,y-10,7,14,'none',f'rx="3.5" stroke="{color}" stroke-width="1.4"')
    path(f'M{x-7} {y-2}V{y+1}Q{x-7} {y+8} {x} {y+8}Q{x+7} {y+8} {x+7} {y+1}V{y-2}M{x} {y+8}V{y+12}M{x-4} {y+12}H{x+4}',color,1.4,extra='stroke-linecap="round"')
def send(x,y):
    shuttle(x-30,y-21,60,42)
    path(f'M{x-6} {y+4}L{x} {y-6}L{x+6} {y+4}M{x} {y-5}V{y+8}',BG,1.5,extra='stroke-linecap="round" stroke-linejoin="round"')
def header():
    path('M35 68L27 76L35 84',INK,1.5,extra='stroke-linecap="round" stroke-linejoin="round"')
    text(201,81,'今天 · 09:41',11,INK,500,extra='text-anchor="middle"');settings()
    line(24,103,378,103,LINE,.65)
def conversation(offset=0, compact=False):
    emit('<g clip-path="url(#conversationClip)">')
    group(f'translate(0 {offset})')
    mono(24,141,'EARLIER / 今天 09:32',8,DIM,extra='letter-spacing=".9"')
    rect(24,159,354,65,'#E7E7DC');text(40,183,'今天读完了二十页书。',13,INK,450)
    text(40,204,'帮我把阅读打个卡。',13,INK,450)
    line(34,247,34,347,BLUE,1)
    circle(34,254,4,BG,'stroke="#3555E8" stroke-width="1.2"');line(38,254,52,254,BLUE,1)
    rect(52,239,326,94,'#DDE99A')
    for y in [254,274,294,314]:circle(52,y,2.5,BG)
    mono(68,261,'01 / HABIT',8,INK,extra='letter-spacing=".9"');text(68,291,'阅读',20,INK,600)
    text(68,316,'今日已完成',11,INK);text(357,316,'查看   撤回',10,INK,extra='text-anchor="end"')
    circle(355,260,7,INK);path('M351 260L354 263L359 257','#DDE99A',1.1,extra='stroke-linecap="round"')
    mono(24,374,'LOOM',8,BLUE,extra='letter-spacing="1.3"');text(24,399,'替你记好了。今天又织进一小段。',12,INK)
    if not compact:
        rect(24,429,354,88,'#E7E7DC')
        mono(40,451,'YOU / 09:41',8,DIM,extra='letter-spacing=".9"')
        text(40,477,'还有一个想法，先帮我留个位置。',13,INK,450)
        text(40,500,'晚一点再慢慢整理。',13,INK,450)
        mono(24,550,'LOOM',8,BLUE,extra='letter-spacing="1.3"')
        text(24,576,'我在这里。随时接着说。',14,INK,500)
    end();end()
def footer(y):
    mono(24,y,'DEEPSEEK',8.5,DIM,extra='letter-spacing="1"');circle(93,y-3,2.5,BLUE)
    text(343,y,'自己记',13,INK,500,extra='text-anchor="end"');arrow(363,y-5,INK)
def normal_composer(y,filled=False):
    rect(0,y,402,874-y,BG);line(24,y,378,y,INK,.8)
    mic(46,y+34,BLUE if filled else INK)
    if filled:
        text(79,y+27,'傍晚走过河边，风很轻。',14,INK)
        text(79,y+50,'想把这个瞬间记下来。',14,INK)
        line(224,y+37,224,y+54,BLUE,1.5)
    else:text(79,y+40,'继续留下一根线…',14,DIM)
    send(348,y+34);footer(y+84)
def listening_composer():
    rect(0,621,402,253,BG);line(24,621,378,621,INK,.8)
    rect(24,637,354,98,'#E6EBD5','rx="10"')
    circle(43,657,3,BLUE);text(55,662,'正在听…',12,INK,550);mono(357,662,'00:08',11,DIM,extra='text-anchor="end"')
    for i in range(48):
        amp=(sin(i*.81)*sin(i*.27+1))**2
        h=3+amp*20
        line(42+i*4.65,696-h/2,42+i*4.65,696+h/2,BLUE,1.3,extra='stroke-linecap="round" opacity=".77"')
    text(294,705,'取消',12,DIM,500,extra='text-anchor="middle"')
    rect(318,682,47,34,INK,'rx="17"');text(342,704,'完成',12,BG,550,extra='text-anchor="middle"')
    mic(46,770,BLUE)
    text(79,763,'傍晚走过河边，风很轻。',14,INK)
    text(79,787,'想把这个瞬间记下来',14,INK)
    line(220,774,220,791,BLUE,1.5)
    shuttle(318,750,60,42,'#C8CEC0')
    path('M342 775L348 765L354 775M348 766V779',BG,1.5,extra='stroke-linecap="round" stroke-linejoin="round"')
    footer(832)
def keyboard():
    rect(0,652,402,222,'#DDE0DF')
    text(201,677,'傍晚        河边        记下来',13,INK,450,extra='text-anchor="middle"')
    line(12,688,390,688,'#C1C8C4',.6)
    rows=[('qwertyuiop',11,699,34,4),('asdfghjkl',29,738,34,4),('zxcvbnm',67,777,34,4)]
    for chars,x,y,w,gap in rows:
        for i,c in enumerate(chars):
            rect(x+i*(w+gap),y,w,31,'#FCFDFB','rx="5"')
            text(x+i*(w+gap)+w/2,y+22,c,18,INK,400,extra='text-anchor="middle"')
    rect(11,777,46,31,'#C2CAC7','rx="5"');text(34,799,'⇧',22,INK,400,extra='text-anchor="middle"')
    rect(344,777,46,31,'#C2CAC7','rx="5"');text(367,798,'⌫',17,INK,400,extra='text-anchor="middle"')
    rect(11,817,46,29,'#C2CAC7','rx="5"');text(34,837,'123',11,INK,450,extra='text-anchor="middle"')
    rect(63,817,43,29,'#C2CAC7','rx="5"');text(84,837,'中/英',10,INK,450,extra='text-anchor="middle"')
    rect(112,817,186,29,'#FCFDFB','rx="5"');text(205,837,'空格',12,INK,450,extra='text-anchor="middle"')
    rect(304,817,86,29,'#C2CAC7','rx="5"');text(347,837,'换行',12,INK,450,extra='text-anchor="middle"')

emit('''<svg xmlns="http://www.w3.org/2000/svg" width="1500" height="1170" viewBox="0 0 1500 1170" role="img" aria-labelledby="title description">
<title id="title">日常织机 · 语音化作一根线</title><desc id="description">对话停留最新消息，轻点麦克风开始听写，实时文字落入原输入框；完成后可编辑并手动发送。取消与完成清楚可见。</desc>
<defs><clipPath id="conversationClip"><rect x="0" y="114" width="402" height="634"/></clipPath><clipPath id="phoneClip"><rect width="402" height="874" rx="43"/></clipPath><filter id="deviceShadow" x="-20%" y="-10%" width="140%" height="130%"><feDropShadow dx="0" dy="12" stdDeviation="18" flood-color="#202A2B" flood-opacity=".065"/></filter></defs><g font-family="-apple-system, BlinkMacSystemFont, PingFang SC, Hiragino Sans GB, sans-serif">''')
rect(0,0,1500,1170,'#E7E7DE')
mono(84,47,'DAILY LOOM   /   VOICE BECOMES A THREAD',11,INK,extra='letter-spacing="1.6"')
text(82,105,'让声音，轻轻落成字。',40,INK,650,extra='letter-spacing="-1.8"')
text(561,103,'话接着说，日常接着织。',15,DIM)
mono(1418,48,'15 SEP 2026',11,INK,extra='text-anchor="end"')
mono(1418,77,'VOICE INPUT / CONVERSATION CONTINUITY',10,DIM,extra='text-anchor="end"')
line(84,132,1418,132,'#C5CBBF',.8)
startphone(84);header();
mono(24,138,'LOOM',8,BLUE,extra='letter-spacing="1.3"')
text(24,165,'不必一次想清楚。',13,INK)
text(24,190,'生活里的小事，我们慢慢记。',13,INK)
line(24,218,378,218,LINE,.6)
conversation(offset=110)
normal_composer(748);closephone()
startphone(550);header();conversation(offset=-20);listening_composer();closephone()
startphone(1016);header();conversation(offset=-100)
normal_composer(547,filled=True);keyboard();closephone()
for x,n,label,caption in [(84,'01','PICK UP THE THREAD','回到对话，停留最新的一段。'),(550,'02','LISTENING, GENTLY','轻点听写，文字随声音落下。'),(1016,'03','YOUR WORDS, YOUR SEND','完成后可修改，再亲手发送。')]:
    mono(x,1076,f'{n}  {label}',10,INK,extra='letter-spacing="1.4"');text(x,1101,caption,12,DIM)
line(84,1127,1418,1127,'#C5CBBF',.8)
mono(84,1150,'ONE INPUT / LIVE TRANSCRIPT / QUIET FEEDBACK / NO AUTO-SEND',8.5,INK,extra='letter-spacing="1.2"')
for i,(color,label) in enumerate([(BG,'PAPER'),(INK,'INK'),(BLUE,'COBALT'),('#E6EBD5','LISTEN'),(CLAY,'CLAY')]):
    x=1036+i*77;rect(x,1141,11,11,color,'stroke="#AEB7A6" stroke-width=".4"');mono(x+16,1150,label,7,DIM)
end();emit('</svg>')
(ROOT/'blueprint.svg').write_text('\n'.join(out),encoding='utf-8')
print(ROOT/'blueprint.svg')
